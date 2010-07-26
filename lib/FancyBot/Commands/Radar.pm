package FancyBot::Commands::Radar;

use Moose;

sub execute 
{
	my $self  = shift;
	my $bot   = shift;
	my $user  = shift;
	my $search = shift;

	$bot->screen->send_chatter( "Error selecting radar." )
		unless $bot->screen->select_radar( $search ); 

	return 1;
}

1;
