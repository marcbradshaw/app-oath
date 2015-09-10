package App::OATH::Crypt::CBC;
# VERSION

use strict;
use warnings;
use Convert::Base32;
use Crypt::CBC;
use Digest::MD5;
use String::Random qw{ random_string };

sub new {
    my ( $class, $args ) = @_;
    my $self = {
        'password' => $args->{'password'},
        'type'     => $args->{'type'},
        'check'    => 'oath',
    };
    bless $self, $class;
    return $self;
}

sub _get_crypt_object {
    my ( $self ) = @_;
    my $password = $self->{'password'};

    my $crypt = Crypt::CBC->new({
        'key'    => $password,
        'cipher' => $self->{'type'},
        'salt'   => 1,
    });
    return $crypt;
}

sub encrypt {
    my ( $self, $data ) = @_;
    my $worker = $self->_get_crypt_object();
    my $u = random_string( '..........' ) . ' ' . $self->{'check'} . ' ' . $data;

    my $e = $worker->encrypt( $u );
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
