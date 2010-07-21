=head1 FancyBot::Commands::Version

Prints the current software version to the game chat.

=head1 SYNOPSIS

 -version
 
=head1 DESCRIPTION

Just prints the current software version to the game chat. The version number is determined by
inspecting $VERSION in FancyBot.pm

=cut

# Last part of package name must correspond to the command name, 
# with the first letter uppercase.
package FancyBot::Commands::Version;

use Moose;

# Main function of the command
# Receives references to self, bot, user and the commands argument(s), 
# which is everything that follows the space after the command name.
sub execute 
{
	# Fetch args from @_
	my $self  = shift;
	my $bot   = shift;
		
	$bot->screen->send_chatter( "FancyBot Version ". $FancyBot::VERSION );
	
	return 1;
}

1;