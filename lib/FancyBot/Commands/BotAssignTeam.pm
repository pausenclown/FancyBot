package FancyBot::Commands::BotAssignTeam;

use Moose;

sub execute 
{
	my $self   = shift;
	my $bot    = shift;
	my $user   = shift;
	my $argstr = shift;
	my $cmd    = shift;
	my $args   = shift;
	
	my ( $player, $team ) = ( $args->[0], $args->[1] );

	$bot->assign_team_for( $player, $team ); 

	return 1;
}

1;
