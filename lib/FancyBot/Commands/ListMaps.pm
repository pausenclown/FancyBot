package FancyBot::Commands::ListMaps;

use Moose;

sub execute 
{
	my $self  = shift;
	my $bot   = shift;
	my $user  = shift;
	my $search = shift;

	$bot->screen->send_chatter( join ( ", ", $bot->screen->maps( $search ) ), ", " ); 
	
	return 1;
}

1;
