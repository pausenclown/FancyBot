package FancyBot::Commands::Example;

use Moose;

sub execute 
{
	my $self  = shift;
	my $bot   = shift;
	my $user  = shift;
	my $topic = shift;

	for my $cfg ( @{ $bot->config->{Commands}->{Command} } )
	{
		if ( $topic eq $cfg->{Name} )
		{
			$bot->screen->send_long_chatter( 70, ' ', $cfg->{Example} );
			return 1;
		}
	}
	
	return;
}

1;