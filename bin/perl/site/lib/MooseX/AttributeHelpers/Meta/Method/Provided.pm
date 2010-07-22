
package MooseX::AttributeHelpers::Meta::Method::Provided;
use Moose;

our $VERSION   = '0.23';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

extends 'Moose::Meta::Method';

1;

__END__

=pod

=head1 NAME

MooseX::AttributeHelpers::Meta::Method::Provided
  
=head1 DESCRIPTION

This is an extension of Moose::Meta::Method to mark I<provided> methods.

=head1 METHODS

=over 4

=item B<meta>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
