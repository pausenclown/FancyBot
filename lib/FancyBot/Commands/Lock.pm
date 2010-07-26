package FancyBot::Commands::Lock;

use Moose;

sub execute 
{
	my $self   = shift;
	my $bot    = shift;
	my $user   = shift;
	my $search = shift; $search = 1 unless defined $search;

	$bot->screen->send_chatter( "Error selecting server lock." )
		unless $bot->screen->select_lock( $search ); 

	return 1;
}

1;
