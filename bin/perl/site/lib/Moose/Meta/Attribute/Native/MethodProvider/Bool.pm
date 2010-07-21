
package Moose::Meta::Attribute::Native::MethodProvider::Bool;
use Moose::Role;

our $VERSION   = '1.08';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

sub set : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub { $writer->( $_[0], 1 ) };
}

sub unset : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub { $writer->( $_[0], 0 ) };
}

sub toggle : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub { $writer->( $_[0], !$reader->( $_[0] ) ) };
}

sub not : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub { !$reader->( $_[0] ) };
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Attribute::Native::MethodProvider::Bool - role providing method generators for Bool trait

=head1 DESCRIPTION

This is a role which provides the method generators for
L<Moose::Meta::Attribute::Native::Trait::Bool>. Please check there for
documentation on what methods are provided.

=head1 METHODS

=over 4

=item B<meta>

=back

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHOR

Jason May E<lt>jason.a.may@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
