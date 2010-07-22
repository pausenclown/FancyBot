package Catalyst::Request::REST;
use Moose;

use Catalyst::Utils;
use namespace::autoclean;

extends 'Catalyst::Request';
with 'Catalyst::TraitFor::Request::REST';

our $VERSION = '0.85';
$VERSION = eval $VERSION;

# Please don't take this as a recommended way to do things.
# The code below is grotty, badly factored and mostly here for back
# compat..
sub _insert_self_into {
  my ($class, $app_class ) = @_;
  # the fallback to $app_class is for the (rare and deprecated) case when
  # people are defining actions in MyApp.pm instead of in a controller.
  my $app = (blessed($app_class) && $app_class->can('_application'))
        ? $app_class->_application : Catalyst::Utils::class2appclass( $app_class ) || $app_class;

  my $req_class = $app->request_class;
  return if $req_class->isa($class);
  my $req_class_meta = Moose->init_meta( for_class => $req_class );
  return if $req_class_meta->does_role('Catalyst::TraitFor::Request::REST');
  if ($req_class eq 'Catalyst::Request') {
    $app->request_class($class);
  }
  else {
      my $meta = Moose::Meta::Class->create_anon_class(
          superclasses => [$req_class],
          roles => ['Catalyst::TraitFor::Request::REST'],
          cache => 1
      );
      $meta->add_method(meta => sub { $meta });
      $app->request_class($meta->name);
  }
}

__PACKAGE__->meta->make_immutable;
__END__

=head1 NAME

Catalyst::Request::REST - A REST-y subclass of Catalyst::Request

=head1 SYNOPSIS

     if ( $c->request->accepts('application/json') ) {
         ...
     }

     my $types = $c->request->accepted_content_types();

=head1 DESCRIPTION

This is a subclass of C<Catalyst::Request> that applies the
L<Catalyst::TraitFor::Request::REST> role to your request class. That trait
adds a few methods to the request object to facilitate writing REST-y code.

This class is only here for backwards compatibility with applications already
subclassing this class. New code should use
L<Catalyst::TraitFor::Request::REST> directly.

L<Catalyst::Action::REST> and L<Catalyst::Controller::REST> will arrange
for the request trait to be applied if needed.

=head1 SEE ALSO

L<Catalyst::TraitFor::Request::REST>.

=head1 AUTHORS

See L<Catalyst::Action::REST> for authors.

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut
