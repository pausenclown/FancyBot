=head1 FancyBot::Commands::ListPlayers

Prints an overview of players and their mech to the game chat.

=head1 SYNOPSIS

	-list-players              # list info about all players
	-list-players Foo          # list info about all players with 'Foo' in their name
	-list-players 1            # list info about all players in Team 1
 
=head1 DESCRIPTION

This command just prints an overview of players and their mech to the game chat.
The output may look like the following:

	Warrior is using a 70 tons Thor.
	Coward is using a 100 tons Atlas.

=cut


# Last part of package name must correspond to the command name, 
# with the first letter uppercase.
package FancyBot::Commands::ListPlayers;

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
	my $player  = quotemeta( shift );
	my $team    = 0; 

	# if $player is a number, 
	# then we really search for a team
	if ( $player =~ /^\d+$/ )
	{
		$team   = $player;
		$player = '';
	}
	
	# read player data from the bot screen
	$bot->update_player_info;
	
	# iterate the player names
	for my $name ( sort keys %{ $bots->users } )
	{
		# do nothing if we look for teams and team no. doesn't match
		next if $team   && $bots->user( $name )->team ne $team;
		
		# do nothing if we look for a specific player and the name doesn't match
		next if $player && $name !~ /$player/;
		
		# otherwise print player info
		my $t = $bots->user( $name )->tonnage;
		my $m = $bots->user( $name )->mech;
		
		$bot->send_chatter( "$name is using a $t tons $m." );
	}

	return 1;
}

1;
	
