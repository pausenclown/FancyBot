package Catalyst::Model::Adaptor::Base;
use strict;
use warnings;

use Carp;
use MRO::Compat;

use base 'Catalyst::Model';

sub _load_adapted_class {
    my ($self) = @_;

    croak 'need class' unless $self->{class};
    my $adapted_class = $self->{class};
    eval "require $adapted_class" or die "failed to require $adapted_class: $@";

    return $adapted_class;
}

sub _create_instance {
    my ($self, $app) = @_;

    my $constructor = $self->{constructor} || 'new';
    my $args = $self->prepare_arguments($app);
    my $adapted_class = $self->{class};

    return $adapted_class->$constructor($self->mangle_arguments($args));
}

sub prepare_arguments {
    my ($self, $app) = @_;
    return exists $self->{args} ? $self->{args} : {};
}

sub mangle_arguments {
    my ($self, $args) = @_;
    return $args;
}

1;

__END__

=head1 NAME

Catalyst::Model::Adaptor::Base - internal base class for Catalyst::Model::Adaptor and friends.

=head1 SYNOPSIS

    # There are no user-serviceable parts in here.

=head1 METHODS

=head2 _load_adapted_class

Load the adapted class

=head2 _create_instance

Instantiate the adapted class

=head2 prepare_arguments

Prepare the arguements

=head2 mangle_arguments

Make the arguements amenable to the adapted class

=head1 SEE ALSO

L<Catalyst::Model::Adaptor>

L<Catalyst::Model::Factory>

L<Catalyst::Model::Factory::PerRequest>

