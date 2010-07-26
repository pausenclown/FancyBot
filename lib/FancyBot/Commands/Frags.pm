package FancyBot::Commands::Frags;

use Moose;

sub execute 
{
	my $self  = shift;
	my $bot   = shift;
	my $user  = shift;
	my $search = shift;

	$bot->screen->send_chatter( "Error selecting frag limit." )
		unless $bot->screen->select_frag_limit( $search ); 

	return 1;
}

1;
