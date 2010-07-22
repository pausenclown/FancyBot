use strict;
use warnings;
package Email::Sender::Util;
BEGIN {
  $Email::Sender::Util::VERSION = '0.101760';
}
# ABSTRACT: random stuff that makes Email::Sender go

use Email::Address;
use Email::Sender::Failure;
use Email::Sender::Failure::Permanent;
use Email::Sender::Failure::Temporary;
use List::MoreUtils ();

# This code will be used by Email::Sender::Simple. -- rjbs, 2008-12-04
sub _recipients_from_email {
  my ($self, $email) = @_;

  my @to = List::MoreUtils::uniq(
           map { $_->address }
           map { Email::Address->parse($_) }
           map { $email->get_header($_) }
           qw(to cc bcc));

  return \@to;
}

sub _sender_from_email {
  my ($self, $email) = @_;

  my ($sender) = map { $_->address }
                 map { Email::Address->parse($_) }
                 scalar $email->get_header('from');

  return $sender;
}

# It's probably reasonable to make this code publicker at some point, but for
# now I don't want to deal with making a sane set of args. -- rjbs, 2008-12-09
sub _failure {
  my ($self, $error, $smtp, @rest) = @_;
  my $code = $smtp ? $smtp->code : undef;

  my $error_class = ! $code       ? 'Email::Sender::Failure'
                  : $code =~ /^4/ ? 'Email::Sender::Failure::Temporary'
                  : $code =~ /^5/ ? 'Email::Sender::Failure::Permanent'
                  :                 'Email::Sender::Failure';

  $error_class->new({
    message => $smtp
               ? ($error ? ("$error: " . $smtp->message) : $smtp->message)
               : $error,
    code    => $code,
    @rest,
  });
}

1;

__END__
=pod

=head1 NAME

Email::Sender::Util - random stuff that makes Email::Sender go

=head1 VERSION

version 0.101760

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

