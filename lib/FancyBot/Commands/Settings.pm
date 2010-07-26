package FancyBot::Commands::Settings;

use Moose;

sub execute 
{
	my $self  = shift;
	my $bot   = shift;
	my $user  = shift;
	my $search = shift;
	
	if ( $search =~ /([A-Z][a-z]+(?:[A-Z][a-z]+)*) (.+)/ )
	{
		$bot->send_chatter( "Denied." ), return
			unless $bot->config->{Server}->{PublicSettings}->{$1};
		
		my $n = $1; my $v = $2;
		
		$v = 0 if $v =~ /^(off|false)$/i;
		$v = 1 if $v =~ /^(on|true)$/i;
		
		$bot->send_chatter( "Settings changed. $n / $v This requires a restart." );
		$bot->config->{Server}->{$n} = $v; 
	}
	
	return 1;
}

1;
