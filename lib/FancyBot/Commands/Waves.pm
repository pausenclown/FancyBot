package FancyBot::Commands::Waves;

use Moose;

sub execute 
{
	my $self  = shift;
	my $bot   = shift;
	my $user  = shift;
	my $search = shift;

	$bot->screen->send_chatter( "Error selecting waves." )
		unless $bot->screen->select_waves( $search ); 

	return 1;
}

1;
