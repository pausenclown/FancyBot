package FancyBot::Commands::Visibility;

use Moose;

sub execute 
{
	my $self  = shift;
	my $bot   = shift;
	my $user  = shift;
	my $search = shift;

	$bot->screen->send_chatter( "Error selecting visibility." )
		unless $bot->screen->select_visibility( $search ); 

	return 1;
}

1;
