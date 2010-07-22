package HTML::FormHandler::Field::TextArea;

use Moose;
extends 'HTML::FormHandler::Field';
our $VERSION = '0.01';

has '+widget' => ( default => 'textarea' );
has 'cols'    => ( isa     => 'Int', is => 'rw' );
has 'rows'    => ( isa     => 'Int', is => 'rw' );

=head1 NAME

HTML::FormHandler::Field::TextArea - Multiple line input

=head1 AUTHORS

Gerda Shank

=head1 COPYRIGHT

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;
