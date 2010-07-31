package FancyBot::Commands::Commands;

use Moose;

sub execute 
{
	my $self  = shift;
	my $bot   = shift;
	my $user  = shift;
	my $all   = shift;

	my @cmds;
	
	for my $cfg ( @{ $bot->config->{Commands}->{Command} } )
	{
		if ( $user->is_allowed_to( $cfg ) )
		{
			if ( $cfg->{IsImplemented} || $all )
			{
				push @cmds, $cfg;
			}
		}
	}
	
	$bot->send_chatter( join( ', ', map { $_->{Name} } @cmds ), ', ' );
	
	return 1;
}

1;