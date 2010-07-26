package FancyBot::Commands::Time;

use Moose;

sub execute 
{
	my $self  = shift;
	my $bot   = shift;
	my $user  = shift;
	my $search = shift;

	$bot->screen->send_chatter( "Error selecting time." )
		unless $bot->screen->select_time( $search ); 

	return 1;
}

1;
