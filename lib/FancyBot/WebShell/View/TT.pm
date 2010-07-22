package FancyBot::WebShell::View::TT;

use strict;
use warnings;

use base 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    render_die => 1,
);

=head1 NAME

FancyBot::WebShell::View::TT - TT View for FancyBot::WebShell

=head1 DESCRIPTION

TT View for FancyBot::WebShell.

=head1 SEE ALSO

L<FancyBot::WebShell>

=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
