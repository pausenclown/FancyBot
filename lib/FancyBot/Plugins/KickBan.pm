package FancyBot::Plugins::KickBan;

use Moose;
use Data::Dumper;


has events =>
	isa     => 'HashRef',
	is      => 'ro',
	default => sub {{
		'player_info_updated' => sub 
		{
			# Fetch arguments
			my $args  = shift;
			
			# Make sure we got a bot reference
			my $bot  = $args->{bot}         || die 'No bot reference';
			
			# make the event cancel when a player was kicked
			return !$bot->kick_a_player;
		}
	}};
1;
