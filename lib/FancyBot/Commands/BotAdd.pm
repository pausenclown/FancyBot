package FancyBot::Commands::BotAdd;

use Moose;

sub execute 
{
	my $self     = shift;
	my $bot      = shift;
	my $user     = shift;
	my $search   = shift;
	my $cmd      = shift;
	my $args     = shift;
	my $pbot     = { };
	my $teamplay = $bot->screen->teamplay_selected;
	
	my @args   = @$args; 
	
	$pbot->{name} = shift @args if scalar @args %2 != 0;
	
	while ( @args ) 
	{
		my $arg = shift @args;
		my $val = shift @args;
		
		$bot->send_chatter( "Error adding bot: Cannot select 'team' in non teamplay match'." ), return
			if $arg eq 'team' && !$teamplay;
			
		$bot->send_chatter( "Error adding bot: Unknown argument '$arg'." ), return
			unless grep { $_ eq $arg } qw( name clan level team ba light heavy assault chassis mech fill );

		$bot->send_chatter( "Error adding bot: '$arg' already in list." ), return
			if $args eq 'name' && $bot->users->{$val};

		$pbot->{$arg} = $val;
	}
	
	( $pbot->{mech}, $pbot->{build} ) = split /:/, $pbot->{mech} if $pbot->{mech};
	
	$bot->send_chatter( "Error adding bot: Please assgin a team.'." ), return
		if $teamplay && !$pbot->{team};

	$bot->screen->add_pbot( $pbot );
	
	return 1;
}

1;
