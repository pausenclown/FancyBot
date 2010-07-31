package FancyBot::Commands::BotAssignMech;

use Moose;

sub execute 
{
	my $self   = shift;
	my $bot    = shift;
	my $user   = shift;
	my $args   = shift;
	
	my ( $player, $mech ) = split /\s+/, $args;

	$bot->assign_mech_for( $player, $mech ); 

	return 1;
}

1;
