package App::OATH::Crypt;
# VERSION

use strict;
use warnings;

use App::OATH::Crypt::Rijndael;
use App::OATH::Crypt::CBC;

sub new {
    my ( $class, $password ) = @_;
    
    my $self = {
        'workers' => {
            'rijndael'    => App::OATH::Crypt::Rijndael->new({ 'password' => $password }),
            'cbcrijndael' => App::OATH::Crypt::CBC->new({ 'password' => $password, 'type' => 'Rijndael', }),
            'cbcblowfish' => App::OATH::Crypt::CBC->new({ 'password' => $password, 'type' => 'Blowfish', }),
        },
        'type' => q{},
    };
    bless $self, $class;
    return $self;
}

sub get_workers_list {
    my ( $self ) = @_;
    my @list = sort keys %{ $self->{'workers'} };
    return \@list;
}

sub set_worker {
    my ( $self, $type ) = @_;
    if ( $type ne q{} and ! exists( $self->{'workers'}->{$type} ) ) {
        die "Unknown encryption type $type";
    }
    $self->{'type'} = $type;
    return;
}

sub encrypt {
    my ( $self, $data ) = @_;
    my $type = $self->{'type'};
    $type = 'cbcrijndael' if $type eq q{};
    my $worker = $self->{'workers'}->{$type};
    return $type . ':' . $worker->encrypt( $data );
}

sub decrypt {
    my ( $self, $data ) = @_;
    my $type = $self->{'type'};
    $type = 'rijndael' if $type eq q{};
    if ( $data =~ /:/ ) {
        ( $type, $data ) = split ':', $data;
    }
    my $worker = $self->{'workers'}->{$type};
    die "Unknown encryption type $type" if ! $worker;
    return $worker->decrypt( $data );
}

1;

