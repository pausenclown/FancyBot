package FancyBot::Commands::No;

use Moose;

sub execute 
{
	my ( $self, $bot, $user ) = @_;
	
	my $name   = $user->name;
	my $result = $bot->plugin_stash->{vote}->{result};
	
	delete $result->{yes}->{ $name };
	$result->{no}->{ $name } = 1;
}

1;
