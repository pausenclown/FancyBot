
package MooseX::AttributeHelpers::Trait::Collection::Array;
use Moose::Role;

our $VERSION   = '0.23';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use MooseX::AttributeHelpers::MethodProvider::Array;

with 'MooseX::AttributeHelpers::Trait::Collection';

has 'method_provider' => (
    is        => 'ro',
    isa       => 'ClassName',
    predicate => 'has_method_provider',
    default   => 'MooseX::AttributeHelpers::MethodProvider::Array'
);

sub helper_type { 'ArrayRef' }

no Moose::Role;

1;

__END__

=pod

=head1 NAME

MooseX::AttributeHelpers::Collection::Array

=head1 SYNOPSIS

  package Stuff;
  use Moose;
  use MooseX::AttributeHelpers;
  
  has 'options' => (
      metaclass => 'Collection::Array',
      is        => 'ro',
      isa       => 'ArrayRef[Int]',
      default   => sub { [] },
      provides  => {
          'push' => 'add_options',
          'pop'  => 'remove_last_option',
      }
  );

=head1 DESCRIPTION

This module provides an Array attribute which provides a number of 
array operations. See L<MooseX::AttributeHelpers::MethodProvider::Array>
for more details.

=head1 METHODS

=over 4

=item B<meta>

=item B<method_provider>

=item B<has_method_provider>

=item B<helper_type>

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
