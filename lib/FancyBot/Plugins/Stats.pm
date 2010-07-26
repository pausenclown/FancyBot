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
			$bot->update_player_info;
			print "DEBUG PlayerInfo Updated.\n";
			return 1;
		},
		'game_stop' => sub 
		{
			my $bot    = shift->{bot} || die "No bot reference";
			$bot->player_info_dirty( 1 );
			return 1;
		},
		'player_join' => sub 
		{
			# Make sure we got a bot reference
			my $bot    = shift->{bot} || die "No bot reference";
			$bot->update_player_info;
			return 1;
		},
		'player_connect' => sub 
		{
			# Make sure we got a bot reference
			my $bot    = shift->{bot} || die "No bot reference";
			$bot->player_info_dirty( 1 );
			return 1;
		},
		'player_disconnect' => sub 
		{
			# Make sure we got a bot reference
			my $bot    = shift->{bot} || die "No bot reference";
			$bot->player_info_dirty( 1 );
			return 1;
		},
		'player_left' => sub 
		{
			# Make sure we got a bot reference
			my $bot    = shift->{bot} || die "No bot reference";
			$bot->player_info_dirty( 1 );
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
				my $player = $bot->user( $1 ); 
				$player->times_connected( $player->times_connected + 1 );
				
				$bot->raise_event( 'player_connect', { bot => $bot, player => $player } );
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
				# print Dumper( $player );
				$player->kills_this_match( $player->kills_this_match + 1 );
				$player->kills_overall( $player->kills_overall + 1 );
				$player->current_death_streak( 0 );
				
				if ( $player->current_kill_streak > $player->longest_kill_streak )
				{
					$player->longest_kill_streak( $player->current_kill_streak );
				}
				
				
				my $victim = $bot->user( $2 );
				$victim->deaths_this_match( $victim->deaths_this_match + 1 );
				$victim->deaths_overall( $victim->deaths_overall + 1 );
				$victim->current_kill_streak( 0 ); 
				
				if ( $victim->current_death_streak > $victim->longest_death_streak )
				{
					$victim->longest_death_streak( $victim->current_death_streak );
				}
				
				$bot->raise_event( 'player_kill', { bot => $bot, player => $player, victim => $victim } ); # or team_kill
			}
			
			return 1;
		},
	}};

1;
