package FancyBot::Commands::Cbills;

use Moose;

sub execute 
{
	my $self  = shift;
	my $bot   = shift;
	my $user  = shift;
	my $search = shift;

	$bot->screen->send_chatter( "Error selecting c-bills." )
		unless $bot->screen->select_cbills( $search ); 

	return 1;
}

1;
