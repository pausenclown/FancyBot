
package MooseX::AttributeHelpers::Collection::Bag;
use Moose;

our $VERSION   = '0.23';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

extends 'Moose::Meta::Attribute';
with 'MooseX::AttributeHelpers::Trait::Collection::Bag';

no Moose;

# register the alias ...
package # hide me from search.cpan.org
    Moose::Meta::Attribute::Custom::Collection::Bag;
sub register_implementation { 'MooseX::AttributeHelpers::Collection::Bag' }

1;

__END__

=pod

=head1 NAME

MooseX::AttributeHelpers::Collection::Bag

=head1 SYNOPSIS

  package Stuff;
  use Moose;
  use MooseX::AttributeHelpers;
  
  has 'word_histogram' => (
      metaclass => 'Collection::Bag',
      is        => 'ro',
      isa       => 'Bag', # optional ... as is default
      provides  => {
          'add'    => 'add_word',
          'get'    => 'get_count_for',            
          'empty'  => 'has_any_words',
          'count'  => 'num_words',
          'delete' => 'delete_word',
      }
  );
  
=head1 DESCRIPTION

This module provides a Bag attribute which provides a number of 
bag-like operations. See L<MooseX::AttributeHelpers::MethodProvider::Bag>
for more details.

=head1 METHODS

=over 4

=item B<meta>

=item B<method_provider>

=item B<has_method_provider>

=item B<helper_type>

=item B<process_options_for_provides>

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
