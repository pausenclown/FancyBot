package FancyBot::Commands::Commands;

use Moose;

sub execute 
{
	my $self  = shift;
	my $bot   = shift;
	my $user  = shift;
	my $all   = shift;

	my @cmds; my @vcmds;
	
	for my $cfg ( @{ $bot->config->{Commands}->{Command} } )
	{
		if ( $user->is_allowed_to( $cfg ) && ( $cfg->{IsImplemented} || $all ) )
		{
			push @cmds, $cfg;
		}
		elsif ( $cfg->{IsVotableCommand} )
		{
			push @vcmds, $cfg;
		}
	}
	
	$bot->send_chatter( 'Available Commands: '. join( ', ', map { $_->{Name} } @cmds ), ', ' );
	$bot->send_chatter( 'Votable Commands: '. join( ', ', map { $_->{Name} } @vcmds ), ', ' )
		if @vcmds;
	
	return 1;
}

1;