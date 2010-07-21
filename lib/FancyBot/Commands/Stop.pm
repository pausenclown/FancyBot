package FancyBot::Commands::Stop;

use Moose;

sub execute 
{
	my $self  = shift;
	my $bot   = shift;
	my $user  = shift;
	
	$bot->screen->stop_map;
		
	$bot->raise_event( 'drop_stop', { bot => $bot, user => $user->name, params => time } );
	
	return 1;
}

1;
