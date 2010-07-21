package FancyBot::Commands::Help;

use Moose;

sub execute 
{
	my $self  = shift;
	my $bot   = shift;
	my $user  = shift;
	my $topic = shift;
	
	$bot->screen->send_chatter( "Type -commands for a list of commands, type -help <command> for further help." ), return
		unless $topic;

	for my $cfg ( @{ $bot->config->{Commands}->{Command} } )
	{
		if ( $topic eq $cfg->{Name} )
		{
			$bot->screen->send_long_chatter( 70, ' ', $cfg->{Help} );
			return 1;
		}
	}
	
	return;
}

1;