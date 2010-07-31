package FancyBot::Commands::BotAssignTeam;

use Moose;

sub execute 
{
	my $self   = shift;
	my $bot    = shift;
	my $user   = shift;
	my $args   = shift;
	
	my ( $player, $team ) = split /\s+/, $args;

	$bot->assign_team_for( $player, $team ); 

	return 1;
}

1;
