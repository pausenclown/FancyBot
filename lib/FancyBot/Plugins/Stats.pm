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
		'chatter' => sub 
		{
			my $self   = shift;
			my $bot    = shift;
			my $user   = shift;
			my $text   = shift;
			
			if ( $text =~ /^(.+) has connected\.$/ )
			{
				$bot->raise_event( 'player_connect', { bot => $bot, player => $1 } );
			}
			elsif ( $text =~ /^(.+) has joined\.$/ )
			{
				$bot->raise_event( 'player_join', { bot => $bot, player => $1 } );
			}
			elsif ( $text =~ /^(.+) has commited suicide\.$/ )
			{
				$bot->raise_event( 'player_suicide', { bot => $bot, player => $1 } );
			}
			elsif ( $text =~ /^(.+) has killed (.+)\.$/ )
			{
				$bot->raise_event( 'player_kill', { bot => $bot, player => $1, victim => $2 } ); # or team_kill
			}
			
			return 1;
		},
	}};

1;
