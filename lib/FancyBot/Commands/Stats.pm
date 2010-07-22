package FancyBot::Commands::Stats;

use Moose;

sub execute 
{
	my $self    = shift;
	my $bot     = shift;
	my $chatter = shift;
	my $player  = shift;
	
	if ( my $user = $bot->user( $player ) )
	{
		my %map = (
			Connections         => 'times_connected',
			Joins               => 'times_joined',
			KillsOverall        => 'kills_overall',
			KillsThisMatch      => 'kills_this_match',
			CurrentKillStreak   => 'current_kill_streak',
			LongestKillStreak   => 'longest_kill_streak',
			HeaviestKillStreak  => 'longest_kill_streak',
			DeathsOverall       => 'deaths_overall',
			DeathsThisMatch     => 'deaths_this_match',
			CurrentDeathStreak  => 'current_death_streak',
			LongestDeathStreak  => 'longest_death_streak'
		);
		
		my @lstats ;
		my @stats;
		
		while ( my ($key,$sub) = each %map )
		{
			push @stats, " $key = ". $user->$sub();
		}
		
		$bot->screen->send_chatter( "Stats for $player: " );
		$bot->screen->send_long_chatter( 100, " / ", join " / ", @stats );
	}
	else
	{
		$bot->screen->send_chatter( "No user '$player' connected." );
	}
	
	return 1;
}

1;
	
