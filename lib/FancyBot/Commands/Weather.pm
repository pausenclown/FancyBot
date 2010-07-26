package FancyBot::Commands::Weather;

use Moose;

sub execute 
{
	my $self  = shift;
	my $bot   = shift;
	my $user  = shift;
	my $search = shift;

	$bot->screen->send_chatter( "Error selecting weather." )
		unless $bot->screen->select_weather( $search ); 

	return 1;
}

1;
