package FancyBot::Commands::Tonnage;

use Moose;

sub execute 
{
	my $self  = shift;
	my $bot   = shift;
	my $user  = shift;
	my $search = shift;

	$bot->screen->send_chatter( "Error selecting tonnage." )
		unless $bot->screen->select_tonnage( $search ); 

	return 1;
}

1;
