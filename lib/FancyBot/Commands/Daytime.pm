package FancyBot::Commands::Daytime;

use Moose;

sub execute 
{
	my $self   = shift;
	my $bot    = shift;
	my $user   = shift;
	my $dt     = shift;

	$bot->screen->send_chatter( "Error selecting daytime." )
		unless $bot->screen->select_daytime( $dt ); 

	return 1;
}

1;
