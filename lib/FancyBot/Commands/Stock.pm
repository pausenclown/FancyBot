package FancyBot::Commands::Stock;

use Moose;

sub execute 
{
	my $self  = shift;
	my $bot   = shift;
	my $user  = shift;
	my $search = shift;

	$bot->screen->send_chatter( "Error selecting stock." )
		unless $bot->screen->select_stock( $search ); 

	return 1;
}

1;
