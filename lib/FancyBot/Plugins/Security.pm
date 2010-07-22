=head1 FancyBot::Plugin::Security

=head1 SYNOPSIS
 
=head1 DESCRIPTION

=cut

package FancyBot::Plugins::Security;

use Moose;

# Declare the events we listen to, here
has events =>
	isa     => 'HashRef',
	is      => 'ro',
	default => sub {{
	}};

1;
