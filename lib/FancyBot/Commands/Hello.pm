package FancyBot::Commands::Hello;

use Moose;
use Data::Dumper;

sub execute 
{
	my $self    = shift;
	my $bot     = shift;
	my $user    = shift;

	$bot->send_chatter( "Hello ". $user->name. "!" );

	return 1;
}

1;
	
