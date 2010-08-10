package FancyBot::Commands::Kick;

use Moose;

sub execute 
{
	my $self   = shift;
	my $bot    = shift;
	my $user   = shift;
	my $player = shift;
	my $cmd    = shift;
	my $args   = shift;

	$bot->screen->prepare_player_kick( $player ); 

	return 1;
}

1;
