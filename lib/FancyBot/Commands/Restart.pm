package FancyBot::Commands::Restart;

use Moose;

sub execute 
{
	my $self  = shift;
	my $bot   = shift;
	
	my @timeout   = split /,/, $bot->config->{Monitor}->{ShutdownTime};
	my $remaining = shift @timeout;
	
	$bot->send_chatter( $bot->config->{Monitor}->{ShutdownWarning} );
	$bot->send_chatter( "$remaining seconds remaining" );
	
	while ( @timeout )
	{
		sleep( $timeout[0] );
		$remaining = $remaining - shift @timeout;
		$bot->send_chatter( "$remaining seconds remaining" );
	}
	
	$bot->kill_server;
	$bot->start_server;
	
	return 1;
}

1;
	
