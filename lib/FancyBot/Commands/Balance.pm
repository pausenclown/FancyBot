=head1 FancyBot::Commands::Balance

Prints an overview of total tonnage and used Mech classes to the game chat.

=head1 SYNOPSIS

 -balance
 
=head1 DESCRIPTION

This command is pretty much the most well known command, next to C<-vote map>.

It just prints an overview of total tonnage and used Mech classes to the game chat.
The output may look like the following:

 Team 1: 3 players, 160 tons (1/0/0/1/1)
 Team 2: 2 players, 160 tons (0/0/0/0/2)
 
which indicates the following:

The teams have the same drop weight, but a different number of players.

Team one consists of one BattleArmor, one Heavy Mech and one Assault.
Team two consists of 2 Assaults.

=cut

# Last part of package name must correspond to the command name, 
# with the first letter uppercase.
package FancyBot::Commands::Balance;

use Moose;

# Main function of the command
# Receives references to self, bot, user and the commands argument(s), 
# which is everything that follows the space after the command name.
sub execute 
{
	# Fetch args from @_
	my $self    = shift;
	my $bot     = shift;
	
	# Needed to keep track of the sums
	my $teams   = {};
	
	# Iterate over all players and collect sums
	# iterate the player names
	for my $name ( sort keys %{ $bot->users } )
	{
		# do nothing if its the FancyBot
		next if $name eq $bot->config->{Server}->{BotName};
		
		my $user = $bot->user( $name );
		
		my $w = $user->{mech}->{tonnage};
		my $t = $user->{team};

		# count number of players per team 
		$teams->{ $t }->{players} += 1; 
		
		# count total tonnage
		$teams->{ $t }->{tonnage} += $w; 
		
		# initialize the per class counter if neccessary
		$teams->{ $t }->{mechs}  ||= {
			light   => 0,
			medium  => 0,
			heavy   => 0,
			assault => 0
		};
		
		# count number of mechs per class
		$teams->{ $t }->{mechs}->{ba}++,     next
			if $w < 25;
			
		$teams->{ $t }->{mechs}->{light}++,  next
			if $w < 40;
			
		$teams->{ $t }->{mechs}->{medium}++, next
			if $w < 60 	;
			
		$teams->{ $t }->{mechs}->{heavy}++,  next
			if $w < 80;
			
		$teams->{ $t }->{mechs}->{assault}++;
	}
	
	# Put the collected stuff into a human readable string.
	my $balance = join '', map {
		my $team    = $_;
		my $players = $teams->{ $team }->{players};
		my $tonnage = $teams->{ $team }->{tonnage};
		my $mechs   = join( "/", map { $teams->{ $team }->{mechs}->{ $_ } } qw( ba light medium heavy assault ) );
		"Team: $team, $tonnage tons ( $mechs )";
	}
	sort keys %$teams;
	
	# and send it to the chat
	$bot->send_chatter( $balance );

	# indicates success of the command
	return 1;
}

1;