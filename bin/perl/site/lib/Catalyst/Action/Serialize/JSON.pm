package Catalyst::Action::Serialize::JSON;

use Moose;
use namespace::autoclean;

extends 'Catalyst::Action';
use JSON ();

our $VERSION = '0.85';
$VERSION = eval $VERSION;

has encoder => (
   is => 'ro',
   lazy_build => 1,
);

sub _build_encoder {
   my $self = shift;
   return JSON->new->utf8->convert_blessed;
}

sub execute {
    my $self = shift;
    my ( $controller, $c ) = @_;

    my $stash_key = (
            $controller->{'serialize'} ?
                $controller->{'serialize'}->{'stash_key'} :
                $controller->{'stash_key'}
        ) || 'rest';
    my $output = $self->serialize( $c->stash->{$stash_key} );
    $c->response->output( $output );
    return 1;
}

sub serialize {
    my $self = shift;
    my $data = shift;
    $self->encoder->encode( $data );
}

1;
