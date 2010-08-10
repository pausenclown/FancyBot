=head1 FancyBot::Plugins::Stats

FancyBot ChatBot Plugin 

=head1 SYNOPSIS
 
=head1 DESCRIPTION

This plugin watches the ingame chat events and looks for statistically relevant information such as 
'UserX has Joined' or 'UserY has killed UserZ', keeps track of it and raises the appropriate events, 
such as kill, suicide or death_streak. 

If the storage settings are defined in the config, the overall statistical information (like e.g., 'KillsTotal')
are persistent between connections, not only per session.

=head1 EVENTS

=head2 kill $killer, $killee

Notifies about someone ($killer), just killed someone else ($killee)

=head2 doublekill 

Notifies the time difference between the last kill and the one before was smaller than the
MultikillTime configuration option.

=head2 multikill (killer) 

come get some, wanna peace of me? et al

=head2 suicide (suicidee)

=head2 killstreak(killer,kills,record)

=head2 deathtreak(killer,kills,record)

=cut


package FancyBot::Plugins::Stats;

use Moose;
use Data::Dumper;

has events =>
	isa     => 'HashRef',
	is      => 'ro',
	default => sub {{
		'game_start' => sub 
		{
			my $bot    = shift->{bot} || die "No bot reference";
			return 1;
		},
		'game_stop' => sub 
		{
			my $bot    = shift->{bot} || die "No bot reference";
			
			foreach my $user ( values %{ $bot->users } )
				{
				$user->is_connected( 0 )
					if $user->is_bot;
			}
			
			return 1;
		},
		'player_join' => sub 
		{
			# Make sure we got a bot reference
			my $bot    = shift->{bot} || die "No bot reference";
			return 1;
		},
		'player_connect' => sub 
		{
			my $args  = shift;
			my $bot    = $args->{bot} || die "No bot reference";

			my $user   = $bot->connect_user( $args->{player_name} );

			$user->times_connected( $user->times_connected+1 );
			$user->is_connected( 1 );

			return 1;
		},
		'player_disconnect' => sub 
		{
			my $args  = shift;
			my $bot    = $args->{bot} || die "No bot reference";
			my $user   = $bot->user( $args->{player} );
			
			$user->is_connected( 0 );
			return 1;
		},
		
		'player_left' => sub 
		{
			# Make sure we got a bot reference
			my $bot    = shift->{bot} || die "No bot reference";
			return 1;
		},
		'chatter' => sub 
		{
			# Fetch args from @_
			my $args   = shift;
			
			# Make sure we got a bot reference
			my $bot    = $args->{bot}      || die "No bot reference";
			
			# Make sure we got a message to parse
			my $text   = $args->{message}  || die "No message";
			
			# Fetch info about the user- and botname
			my $user   = $args->{user};

			return 1 if $args->{user};
			
			if ( $text =~ /^(.+) has connected/ )
			{
				$bot->raise_event( 'player_connect', { bot => $bot, player_name => $1} );
			}
			elsif ( $text =~ /^(.+) has left/ )
			{
				my $player = $bot->user( $1 ); 
				$player->times_connected( $player->times_connected + 1 );
				
				$bot->raise_event( 'player_left', { bot => $bot, player => $player } );
			}			
			elsif ( $text =~ /^(.+) has joined/ )
			{
			
				return 1 if $bot->config->{'Server'}->{'BotName'} eq $1;
				
				my $player = $bot->user( $1 );
				$player->times_joined_this_match( $player->times_joined_this_match + 1 );
				$player->times_joined( $player->times_joined + 1 );
				
				$bot->raise_event( 'player_join', { bot => $bot, player => $player } );
			}
			elsif ( $text =~ /^(.+) Committed Suicide/ )
			{
				my $player = $bot->user( $1 );
				$player->suicides_this_match( $player->suicides_this_match + 1 );
				$player->suicides_overall( $player->suicides_overall + 1 );
				
				$bot->raise_event( 'player_suicide', { bot => $bot, player => $player } );
			}
			elsif ( $text =~ /^(.+) Destroyed (.+)/ )
			{
				my $player = $bot->user( $1 );
				my $victim = $bot->user( $2 );
			
				# could also be a turret or a tank
				# make sure we dont count that
				unless ( $victim )
				{
					$bot->raise_event( 'turret_destroyed', { bot => $bot, player => $player } )
						if $2 eq "a turret";

					$bot->raise_event( 'tank_destroyed', { bot => $bot, player => $player } )
						if $2 eq "Demolisher";
						
					return 1;
				}
				
				$player->kills_this_match( $player->kills_this_match + 1 );
				$player->current_kill_streak( $player->current_kill_streak + 1 );
				$player->kills_overall( $player->kills_overall + 1 );
				$player->current_death_streak( 0 ); 

				if ( $player->current_kill_streak > $player->longest_kill_streak )
				{
					$player->longest_kill_streak( $player->current_kill_streak );
				}



				$victim->deaths_this_match( $victim->deaths_this_match + 1 );
				$victim->current_death_streak( $victim->current_death_streak + 1 );
				$victim->deaths_overall( $victim->deaths_overall + 1 );
				$victim->current_kill_streak( 0 ); 

				if ( $victim->current_death_streak > $victim->longest_death_streak )
				{
					$victim->longest_death_streak( $victim->current_death_streak );
				}

				print "[KILLER] player => ". $player->name. ", kills => ". $player->kills_this_match. ", deaths => ". $player->deaths_this_match. ", killz => ". $player->current_kill_streak. ", deathz => ". $player->current_death_streak. "\n";
				print "[VICTIM] player => ". $victim->name. ", kills => ". $victim->kills_this_match. ", deaths => ". $victim->deaths_this_match. ", killz => ". $victim->current_kill_streak. ", deathz => ". $victim->current_death_streak. "\n";

				if ( !1 ) 
				{
					$bot->raise_event( 'player_team_kill', { 
						bot => $bot, 
						player => $player, 
						victim => $victim 
					} );
				}
				elsif ( $player->current_kill_streak > 2 )
				{
					$bot->raise_event( 'player_kill_streak', { 
						bot => $bot, player => $player
					} ); 
				}
				elsif ( $victim->current_death_streak > 2 )
				{
					$bot->raise_event( 'player_death_streak', { 
						bot => $bot, player => $victim
					} ); 
				}
				else
				{
					$bot->raise_event( 'player_kill', { 
						bot => $bot, 
						player => $player, 
						victim => $victim 
					} ); # or team_kill
				}			
			}
			
			return 1;
		},
	}};

1;
