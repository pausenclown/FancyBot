=head1 FancyBot::Commands::Webshell

Prints the current software version to the game chat.

=head1 SYNOPSIS

 -version
 
=head1 DESCRIPTION

Just prints the current software version to the game chat. The version number is determined by
inspecting $VERSION in FancyBot.pm

=cut

# Last part of package name must correspond to the command name, 
# with the first letter uppercase.
package FancyBot::Commands::Webshell;

use Moose;
use Data::Dumper;
use LWP::Simple;

# Main function of the command
# Receives references to self, bot, user and the commands argument(s), 
# which is everything that follows the space after the command name.
sub execute 
{
	# Fetch args from @_
	my $self  = shift;
	my $bot   = shift;
	
	print Dumper ( $bot->config->{WebShell} );
	
	my $port  = ref $bot->config->{WebShell}->{Port} ?
				3000 :
				$bot->config->{WebShell}->{Port};

	my $url   = ref $bot->config->{WebShell}->{Host} ?
				get( 'http://www.whatismyip.com/automation/n09230945.asp' ) :
				$bot->config->{WebShell}->{Host};
				
	$bot->screen->send_chatter( "Webshell at http://${url}:${port}" );
	
	return 1;
}

1;