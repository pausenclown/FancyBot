package FancyBot::Commands::Type;

use Moose;

sub execute 
{
	my $self  = shift;
	my $bot   = shift;
	my $user  = shift;
	my $search = shift;

	$bot->screen->send_chatter( "Error selecting gametype." )
		unless $bot->screen->select_type( $search ); 

	return 1;
}

1;
