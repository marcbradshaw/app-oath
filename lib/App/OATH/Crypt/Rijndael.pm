package App::OATH::Crypt::Rijndael;
# VERSION

use strict;
use warnings;
use Convert::Base32;
use Crypt::Rijndael;
use Digest::MD5;
use String::Random qw{ random_string };

sub new {
    my ( $class, $args ) = @_;
    my $self = {
        'password' => $args->{'password'},
        'check'    => 'oath',
    };
    bless $self, $class;
    return $self;
}

sub _get_crypt_object {
    my ( $self ) = @_;
    my $password = $self->{'password'};

    my $md5 = Digest::MD5->new();
    $md5->add( $password );
    my $crypt_key = $md5->digest();

    my $crypt = Crypt::Rijndael->new( $crypt_key, Crypt::Rijndael::MODE_CBC() );
    return $crypt;
}

sub encrypt {
    my ( $self, $data ) = @_;
    my $worker = $self->_get_crypt_object();
    my $u = random_string( '..........' ) . ' ' . $self->{'check'} . ' ' . $data;
    my $pad = random_string( '.' x ( 16 - ( length( $u ) % 16 ) ) );

    my $e = $worker->encrypt( $pad . $u );
    $e = encode_base32( $e );
    return $e;
}

sub decrypt {
    my ( $self, $data ) = @_;
    my $worker = $self->_get_crypt_object();
    my $e = decode_base32( $data );
    my $u = $worker->decrypt($e);
    my ( $salt, $check, $payload ) = split( ' ', $u );
    $check = q{} if ! $check;
    if ( $check ne $self->{'check'} ) {
        return;
    }
    return $payload;
}

1;
