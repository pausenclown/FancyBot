package FancyBot::Commands::Launch;

use Moose;

sub execute 
{
	my $self  = shift;
	my $bot   = shift;
	my $user  = shift;
	
	$bot->screen->launch;
		
	$bot->raise_event( 'drop_start', { bot => $bot, user => $user, params => time } );
	
	return 1;
}

1;
