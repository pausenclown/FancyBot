package FancyBot::Commands::ListTypes;

use Moose;

sub execute 
{
	my $self  = shift;
	my $bot   = shift;
	my $user  = shift;
	my $search = shift;

	$bot->screen->send_chatter( join ( ", ", $bot->screen->game_types( $search ) ), ", " ); 
	
	return 1;
}

1;
