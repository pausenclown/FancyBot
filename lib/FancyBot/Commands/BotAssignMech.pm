package FancyBot::Commands::BotAssignMech;

use Moose;

sub execute 
{
	my $self    = shift;
	my $bot     = shift;
	my $user    = shift;
	my $argstr  = shift;
	my $cmd     = shift;
	my $args    = shift;
	
	my ( $player, $mech ) = ( $args->[0], $args->[1] );
	($mech, my $build) = split /:/, $mech;

	$bot->assign_mech_for( $player, $mech, $build ); 

	return 1;
}

1;
