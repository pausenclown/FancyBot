=head1 FancyBot::Commands::ListBots

Prints an overview of players and their mech to the game chat.

=head1 SYNOPSIS

	-list-players              # list names of Bots
 
=head1 DESCRIPTION

This command just prints the names of all bots.

	2 Bots ( Cachi, Warrior ).

=cut


# Last part of package name must correspond to the command name, 
# with the first letter uppercase.
package FancyBot::Commands::ListBots;

use Moose;

# Main function of the command
# Receives references to self, bot, user and the commands argument(s), 
# which is everything that follows the space after the command name.
sub execute 
{
	# Fetch args from @_
	my $self    = shift;
	my $bot     = shift;
	my $user    = shift;
		
	# read player data from the bot screen
	$bot->update_player_info;
	
	my @bots = grep { $bot->user( $_ )->is_bot } sort keys %{ $bot->users };
	
	$bot->send_chatter( scalar @bots. " Bots: ". join( ', ', @bots ) );
	return 1;
}

1;
	
