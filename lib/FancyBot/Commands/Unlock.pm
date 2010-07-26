package FancyBot::Commands::Unlock;

use Moose;

sub execute 
{
	my $self  = shift;
	my $bot   = shift;

	$bot->screen->send_chatter( "Error unlocking server." )
		unless $bot->screen->select_lock( 0 ); 

	return 1;
}

1;
