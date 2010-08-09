package FancyBot::Commands::Yes;

use Moose;

sub execute 
{
	my ( $self, $bot, $user ) = @_;
	
	my $name   = $user->name;
	my $result = $bot->plugin_stash->{vote}->{result};
	
	delete $result->{no}->{ $name };
	$result->{yes}->{ $name } = 1;
}

1;
