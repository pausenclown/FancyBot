package Email::Sender::Failure::Temporary;
BEGIN {
  $Email::Sender::Failure::Temporary::VERSION = '0.101760';
}
use Moose;
extends 'Email::Sender::Failure';
# ABSTRACT: a temporary delivery failure

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
no Moose;
1;

__END__
=pod

=head1 NAME

Email::Sender::Failure::Temporary - a temporary delivery failure

=head1 VERSION

version 0.101760

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

