package FancyBot::Commands::Next;

use Moose;

sub execute 
{
	my $self = shift;
	my $bot  = shift;
	
	$bot->raise_event( 'game_next', { bot => $bot } );

	return 1;
}

1;