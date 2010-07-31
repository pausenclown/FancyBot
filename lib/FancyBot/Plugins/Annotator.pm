=head1 FancyBot::Plugins::Annotator

=head1 SYNOPSIS
 
=head1 DESCRIPTION

=cut

package FancyBot::Plugins::Annotator;

use Moose;

use Win32::GuiTest qw( SetForegroundWindow GetForegroundWindow );

use Data::Dumper;
# Declare the events we listen to, here: chatter
has events =>
	isa     => 'HashRef',
	is      => 'ro',
	default => sub {{

		'player_join' => sub 
		{
			# Fetch args from @_
			my $args  = shift;
			
			return $args->{bot}->send_chatter( $args->{player}->annotate( 'player',
				find_message( $args->{bot}, $args->{player}, 'Join', 'Player' )
			));
		},

		'player_kill_streak' => sub 
		{
			# Fetch args from @_
			my $args  = shift;
			
			return $args->{bot}->send_chatter( $args->{player}->annotate( 'player',
				find_message( $args->{bot}, $args->{player}, 'KillStreak', 'Player' )
			));
		},

		'player_death_streak' => sub 
		{
			# Fetch args from @_
			my $args  = shift;
			
			return $args->{bot}->send_chatter( $args->{player}->annotate( 'player',
				find_message( $args->{bot}, $args->{player}, 'DeathStreak', 'Player' )
			));
		},
		
		'player_suicide' => sub 
		{
			# Fetch args from @_
			my $args  = shift;
			
			return $args->{bot}->send_chatter( $args->{player}->annotate( 'player',
				find_message( $args->{bot}, $args->{player}, 'Suicide', 'Player' )
			));
		},

		'player_team_kill' => sub 
		{
			# Fetch args from @_
			my $args  = shift;
			
			return $args->{bot}->send_chatter( $args->{player}->annotate( 'player', $args->{victim}->annotate( 'victim',
				find_message( $args->{bot}, $args->{player}, 'Suicide', 'Player' )
			)));
		},

		'player_kill' => sub 
		{
			# Fetch args from @_
			my $args  = shift;
			
			$args->{bot}->send_chatter( $args->{player}->annotate( 'killer', $args->{victim}->annotate( 'victim',
				find_message_kill( $args->{bot}->config->{Annotator}->{Annotations}->{Kill}, 'Killer', $args->{player}->name, 'Victim', $args->{victim}->name )
			)));
			
			return 1;
		},		
	}}
;

sub find_message
{
	my ( $bot, $player, $key, $tag ) = @_;
	
	# Make sure we got a bot reference
	$bot or die "No bot reference";
		
	# Make sure we got a player
	$player or die "No message";


	my $notes = $bot->config->{Annotator}->{Annotations}->{$key};
	my @notes = ref $notes eq "ARRAY" ? @$notes : ( $notes );
	my @messages;
	
	for my $note ( @notes )
	{
		my $re = $note->{$tag}; if ( !$re  || $player->name =~ /$re/ ) {
			my $messages = $note->{Message};
			push @messages, ref $messages eq "ARRAY" ? @$messages : ($messages);
		}
	}

	return $messages[ int( rand( scalar @messages ) ) ];
}

sub find_message_kill {
	my ( $notes, $ktag, $kname, $vtag, $vname ) = @_;
	
	my @notes = ref $notes eq "ARRAY" ? @$notes : ( $notes );
	my @messages;

	for my $note ( @notes )
	{
		my $re  = $note->{Killer}; $re  ||= qr/.?/;
		my $re2 = $note->{Victim}; $re2 ||= qr/.?/;
		
		if ( $kname =~ /$re/ && $vname =~ /$re2/ )  {
			
			my $messages = $note->{Message};
			push @messages, ref $messages eq "ARRAY" ? @$messages : ($messages);
		}
	}

	my $i = int( rand( scalar @messages ) );

	return $messages[ $i ]; 
}

1;