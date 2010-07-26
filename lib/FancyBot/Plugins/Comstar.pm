=head1 FancyBot::Plugin::Comstar

=head1 SYNOPSIS
 
=head1 DESCRIPTION

=cut

package FancyBot::Plugins::Comstar;

use Moose;

# Declare the events we listen to, here
has events =>
	isa     => 'HashRef',
	is      => 'ro',
	default => sub {{
	}};

1;
