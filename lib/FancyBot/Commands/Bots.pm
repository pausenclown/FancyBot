package FancyBot::Commands::Bots;

use Moose;

sub execute 
{
	my $self   = shift;
	my $bot    = shift;
	my $user   = shift;
	my $search = shift;

	$bot->screen->send_chatter( "Error selecting bots" )
		unless $bot->screen->select_bots( $search ); 

	return 1;
}

1;
