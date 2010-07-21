package FancyBot::Commands::Map;

use Moose;

sub execute 
{
	my $self  = shift;
	my $bot   = shift;
	my $user  = shift;
	my $search = shift;

	$bot->screen->send_chatter( "Error selecting map." )
		unless $bot->screen->select_map( $search ); 

	return 1;
}

1;
