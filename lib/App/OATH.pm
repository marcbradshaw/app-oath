package App::OATH;
# VERSION

use strict;
use warnings;

use Convert::Base32;
use Digest::HMAC_SHA1 qw(hmac_sha1);
use Fcntl ':flock';
use JSON;
use POSIX;
use Term::ReadKey;

use App::OATH::Crypt;

sub new {
    my ( $class ) = @_;
    my $self = {
        'filename' => $ENV{'HOME'} . '/.oath.json',
    };
    bless $self, $class;
    return $self;
}

sub usage {
    my ( $self ) = @_;
    print "usage: $0 --add string --file filename --help --init --list --newpass --search string \n\n";
    print "options:\n\n";
    print "--add string\n";
    print "    add a new password to the database, the format can be one of the following\n"; 
    print "        text: identifier:secret\n";
    print "        url:  otpauth://totp/alice\@google.com?secret=JBSWY3DPEHPK3PXP\n\n";
    print "--file filename\n";
    print "    filename for database, default ~/.oath.json\n\n";
    print "--help\n";
    print "    show this help\n\n";
    print "--init\n";
    print "    initialise the database, file must not exist\n\n";
    print "--list\n";
    print "    list keys in database\n\n";
    print "--newpass\n";
    print "    resave database with a new password\n\n";
    print "--search string\n";
    print "    search database for keys matching string\n\n";
    exit 0;
}

sub set_search {
    my ( $self, $search ) = @_;
    $self->{'search'} = $search;
    return;
}

sub get_search { 
    my ( $self ) = @_;
    return $self->{'search'};
}

sub init {
    my ( $self ) = @_;
    my $filename = $self->get_filename();
    if ( -e $filename ) {
        print "Error: file already exists\n";
        exit 1;
    }
    $self->{ 'data_plaintext' } = {};
    $self->encrypt_data();
    $self->save_data();
    return;
}

sub add_entry {
    my ( $self, $entry ) = @_;
    my $search = $self->get_search();
    my $data = $self->get_plaintext();

    if ( $entry =~ /^otpauth:\/\/totp\// ) {
        # Better parsing required
        my ( $key, $rest ) = $entry =~ /^otpauth:\/\/totp\/(.*)\?(.*)$/;
        my ( $value ) = $rest =~ /secret=([^&]*)/;
        if ( exists( $data->{$key} ) ) {
            print "Error: Key already exists\n";
            exit 1;
        }
        else {
            print "Adding OTP for $key\n";
            $self->{'data_plaintext'}->{$key} = $value;
        }
        
    }
    elsif ( $entry =~ /^[^:]+:[^:]+$/ ) {
        my ( $key, $value ) = $entry =~ /^([^:]+):([^:]+)$/;
        if ( exists( $data->{$key} ) ) {
            print "Error: Key already exists\n";
            exit 1;
        }
        else {
            print "Adding OTP for $key\n";
            $self->{'data_plaintext'}->{$key} = $value;
        }
        
    }
    else {
        print "Error: Unknown format\n";
        exit 1;
    }

    $self->encrypt_data();
    $self->save_data();
    
    return;
}

sub list_keys {
    my ( $self ) = @_;
    my $search = $self->get_search();
    my $data = $self->get_encrypted();

    my $counter = int( time() / 30 );

    foreach my $account ( sort keys %$data ) {
        if ( $search ) {
            next if ( index( lc $account, lc $search ) == -1 );
        }
        print "$account\n";
    }

    print "\n";
    return;
}

sub get_counter {
    my ( $self ) = @_;
    my $counter = int( time() / 30 );
    return $counter;
}

sub display_codes {
    my ( $self ) = @_;
    my $search = $self->get_search();
    my $data = $self->get_plaintext();
    my $counter = $self->get_counter();

    my $max_len = 0;

    foreach my $account ( sort keys %$data ) {
        if ( $search ) {
            next if ( index( lc $account, lc $search ) == -1 );
        }
        $max_len = length( $account ) if length $account > $max_len;
    }

    print "\n";
    foreach my $account ( sort keys %$data ) {
        if ( $search ) {
            next if ( index( lc $account, lc $search ) == -1 );
        }
        my $secret = uc $data->{ $account };
        printf( '%*3$s : %s' . "\n", $account, $self->oath_auth( $secret, $counter ), $max_len );
    }
    print "\n";
    return;
}

sub oath_auth {
    my ( $self, $key, $tm ) = @_;

    my @chal;
    for (my $i=7;$i;$i--) {
        $chal[$i] = $tm & 0xFF;
        $tm >>= 8;
    }

    my $challenge;
    {
        no warnings;
        $challenge = pack('C*',@chal);
    }

    my $secret = decode_base32($key);

    my $hashtxt = hmac_sha1($challenge,$secret);
    my @hash = unpack("C*",$hashtxt);
    my $offset = $hash[$#hash]& 0xf ;

    my $truncatedHash=0;
    for (my $i=0;$i<4;$i++) {
        $truncatedHash <<=8;
        $truncatedHash |= $hash[$offset+$i];
    }
    $truncatedHash &=0x7fffffff;
    $truncatedHash %= 1000000;
    $truncatedHash = substr( '0'x6 . $truncatedHash, -6 );

    return $truncatedHash;
}

sub set_filename {
    my ( $self, $filename ) = @_;

    if ( $self->{'filaname'} ne $filename ) {
        # Unlock if filename has changed
        $self->drop_lock();
    }

    $self->{'filename'} = $filename;
    return;
}

sub get_filename {
    my ( $self ) = @_;
    return $self->{'filename'};
}

sub get_lockfilename {
    my ( $self ) = @_;
    my $filename = $self->get_filename();
    my $lockfilename = $filename . '.lock';
    return $lockfilename;
}

sub drop_lock {
    my ( $self ) = @_;
    delete $self->{'lockhandle'};
    return;
}
sub get_lock {
    my ( $self ) = @_;

    my $lockh;
    my $lockfilename = $self->get_lockfilename();
    if ( ! -e $lockfilename ) {
        open $lockh, '>', $lockfilename;
        close $lockh;
    }
    open $lockh, '<', $lockfilename;
    if ( !flock( $lockh, LOCK_EX | LOCK_NB ) ) {
        return 0;
    }
    $self->{'lockhandle'} = $lockh;
    return 1;
} 

sub load_data {
    my ( $self ) = @_;
    my $json = JSON->new();
    my $filename = $self->get_filename();
    open( my $file, '<', $filename ) || die "cannot open file $!";
    my @content = <$file>;
    close $file;
    my $data = $json->decode( join( "\n", @content ) );
    $self->{'data_encrypted'} = $data;
    return;
}

sub save_data {
    my ( $self ) = @_;
    my $data = $self->get_encrypted();
    my $json = JSON->new();
    my $content = $json->encode( $data );
    my $filename = $self->get_filename();
    open( my $file, '>', $filename ) || die "cannot open file $!";
    print $file $content;
    close $file;
    return;
}

sub encrypt_data {
    my ( $self ) = @_;
    my $data = $self->get_plaintext();
    $self->drop_password() if $self->{'newpass'};
    my $crypt = App::OATH::Crypt->new( $self->get_password() );
    my $edata = {};
    foreach my $k ( keys %$data ) {
        $edata->{$k} = $crypt->encrypt( $data->{$k} );
    }
    $self->{'data_encrypted'} = $edata;
    return;
}

sub decrypt_data {
    my ( $self ) = @_;
    my $data = $self->get_encrypted();
    my $crypt = App::OATH::Crypt->new( $self->get_password() );
    my $ddata = {};
    foreach my $k ( keys %$data ) {
        my $d = $crypt->decrypt( $data->{$k} );
        if ( ! $d ) {
            print  "Invalid password\n";
            exit 1;
        }
        $ddata->{$k} = $d;
    }
    $self->{'data_plaintext'} = $ddata;
    return;
}

sub get_plaintext {
    my ( $self ) = @_;
    $self->decrypt_data() if ! exists $self->{'data_plaintext'};
    return $self->{'data_plaintext'}; 
}

sub get_encrypted {
    my ( $self ) = @_;
    $self->load_data() if ! exists $self->{'data_encrypted'};
    return $self->{'data_encrypted'};
}

sub set_newpass {
    my ( $self ) = @_;
    $self->{'newpass'} = 1;
    return;
}

sub drop_password {
    my ( $self ) = @_;
    delete $self->{'password'};
    return;
}

sub get_password {
    my ( $self ) = @_;
    return $self->{'password'} if $self->{'password'};
    print "Password:";
    ReadMode('noecho');
    my $password;
    chomp($password = <STDIN>);
    ReadMode(0);
    print "\n";
    $self->{'password'} = $password;
    return $password;
}

1;

# ABSTRACT: Simple OATH authenticator
__END__

=head1 NAME

App::OATH - Simple OATH authenticator

=head1 DESCRIPTION

Simple command line OATH authenticator written in Perl.

=head1 SYNOPSIS

Implements the Open Authentication (OATH) time-based one time password (TOTP)
two factor authentication standard as a simple command line programme.

Allows storage of multiple tokens, which are kept encrypted on disk.

Google Authenticator is a popular example of this standard, and this project
can be used with the same tokens.

=head1 USAGE

usage: oath --add string --file filename --help --init --list --newpass --search string 

options:

--add string

    add a new password to the database, the format can be one of the following

        text: identifier:secret
        url:  otpauth://totp/alice@google.com?secret=JBSWY3DPEHPK3PXP

--file filename

    filename for database, default ~/.oath.json

--help

    show this help

--init

    initialise the database, file must not exist

--list

    list keys in database

--newpass

    resave database with a new password

--search string

    search database for keys matching string

=head1 SECURITY

Tokens are encrypted on disk, the identifiers are not encrypted and can be read in plaintext
from the file.

This is intended to secure against casual reading of the file, but as always, if you have specific security requirements
you should do your own research with regard to relevant attack vectors and use an appropriate solution.

=head1 METHODS

You most likely won't ever want to call these directly, you should use the included command line programme instead.

=over

=item I<new()>

Instantiate a new object

=item I<usage()>

Display usage and exit

=item I<set_search()>

Set the search parameter

=item I<get_search()>

Get the search parameter

=item I<init()>

Initialise a new file

=item I<add_entry()>

Add an entry to the file

=item I<list_keys()>

Display a list of keys in the current file

=item I<get_counter()>

Get the current time based counter

=item I<display_codes()>

Display a list of codes

=item I<oath_auth()>

Perform the authentication calculations

=item I<set_filename()>

Set the filename

=item I<get_filename()>

Get the filename

=item I<load_data()>

Load in data from file

=item I<save_data()>

Save data to file

=item I<encrypt_data()>

Encrypt the data

=item I<decrypt_data()>

Decrypt the data

=item I<get_plaintext()>

Get the plaintext version of the data

=item I<get_encrypted()>

Get the encrypted version of the data

=item I<set_newpass()>

Signal that we would like to set a new password

=item I<drop_password()>

Drop the password

=item I<get_password()>

Get the current password (from user or cache)

=item I<get_lockfilename()>

Return a filename for the lock file, typically this is filename appended with .lock

=item I<drop_lock()>

Drop the lock (unlock)

=item I<get_lock()>

Get a lock, return 1 on success or 0 on failure

=back

=head1 DEPENDENCIES

  Convert::Base32
  Digest::HMAC_SHA1
  JSON
  POSIX
  Term::ReadKey

=head1 AUTHORS

Marc Bradshaw E<lt>marc@marcbradshaw.netE<gt>

=head1 COPYRIGHT

Copyright 2015

This library is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

