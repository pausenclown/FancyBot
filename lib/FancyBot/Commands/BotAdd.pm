package FancyBot::Commands::BotAdd;

use Moose;

sub execute 
{
	my $self     = shift;
	my $bot      = shift;
	my $user     = shift;
	my $search   = shift;
	my $pbot     = { };
	my $teamplay = $bot->screen->teamplay_selected;
	
	my @args   = split / /, $search;
	
	$pbot->{name} = shift @args if scalar @args %2 != 0;
	
	while ( @args ) 
	{
		my $arg = shift @args;
		my $val = shift @args;
		
		$bot->send_chatter( "Error adding bot: Cannot select 'team' in non teamplay match'." )
			if $arg eq 'team' && !$teamplay;
			
		$bot->send_chatter( "Error adding bot: Unknown argument '$arg'." )
			unless grep { $_ eq $arg } qw( name clan level team ba light heavy assault chassis mech fill );

		$pbot->{$arg} = $val;
	}

	$bot->send_chatter( "Error adding bot: Please assgin a team.'." )
		if $teamplay && !$pbot->{team};

	$bot->screen->add_pbot( $pbot );
	
	return 1;
}

1;
