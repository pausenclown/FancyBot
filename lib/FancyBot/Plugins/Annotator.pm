=head1 FancyBot::Plugins::Annotator

=head1 SYNOPSIS
 
=head1 DESCRIPTION

=cut

package FancyBot::Plugins::Annotator;

use Moose;
use Chatbot::Eliza;
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
			
			# Make sure we got a bot reference
			my $bot    = $args->{bot}      || die "No bot reference";
			
			# Make sure we got a player
			my $player = $args->{player}  || die "No message";
			
			my $notes = $bot->config->{Annotator}->{Annotations}->{Join};
			my @notes = ref $notes eq "ARRAY" ? @$notes : ( $notes );
		
			for my $note ( @notes )
			{
				my $re = $note->{Player}; if ( ref( $re ) || $player->name =~ /$re/ ) {
					my $messages = $note->{Message};
					my @messages = ref $messages eq "ARRAY" ? @$messages : ($messages);
					my $msg      = $messages[ int( rand( scalar @messages ) ) ]; 
					
					$msg =~ s/\%player/$player->name/ge;
					
					$bot->screen->send_chatter( $messages[ $msg ] ); 
					return 1;
				}
			}
		},

		'player_kill' => sub 
		{
			# Fetch args from @_
			my $args  = shift;
			
			# Make sure we got a bot reference
			my $bot    = $args->{bot}      || die "No bot reference";
			
			# Make sure we got a player
			my $player = $args->{player}  || die "No message";
			my $victim = $args->{victim}  || die "No victim";
			
			my $notes = $bot->config->{Annotator}->{Annotations}->{Kill};
			my @notes = ref $notes eq "ARRAY" ? @$notes : ( $notes );
		
			for my $note ( @notes )
			{
				my $re  = $note->{Killer}; 
				my $re2 = $note->{Victim}; 
				
				if ( ( ref( $re ) || $player->name =~ /$re/ ) && ( ref( $re2 ) || $victim->name =~ /$re2/ )  ) {
					my $messages = $note->{Message};

					my @messages = ref $messages eq "ARRAY" ? @$messages : ($messages);

					my $i = int( rand( scalar @messages ) );

					my $msg      = $messages[ $i ]; 
					
					$msg =~ s/\%killer/$player->name/ge;
					$msg =~ s/\%victim/$victim->name/ge;
					
					$bot->screen->send_chatter( $msg ); 
					return 1;
				}
			}
		},		
	}};

1;