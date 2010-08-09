=head1 FancyBot::Plugins::Eliza

=head1 SYNOPSIS
 
=head1 DESCRIPTION

=cut

package FancyBot::Plugins::Vote;

use Moose;
use Data::Dumper;

# Declare the events we listen to, here: chatter
has events =>
	isa     => 'HashRef',
	is      => 'ro',
	default => sub {{
		'pulse' => sub 
		{
			my $args        = shift;
			my $bot         = $args->{bot} || die "No bot reference";
			my $vote        = $bot->plugin_stash->{vote};
			
			return unless $vote && $vote->{in_progress};

			my $time        = $bot->config->{Vote}->{VotingTime}     || 60;
			my $players     = @{ $bot->connected_humans_as_list };
			
			# wait for vote to timeout unless we got only a single human
			return if 
				( $vote->{start_time} + $time > time ) &&
				( $players > 1 );
			
			$vote->{in_progress} = 0;
			
			my $min_turnout = $bot->config->{Vote}->{MinimumTurnout} || 0.25;
			my $min_votes   = int( $min_turnout * $players );
			
			my $yes         = scalar keys %{ $vote->{result}->{yes} };
			my $no          = scalar keys %{ $vote->{result}->{no}  };
			my $all         = $yes + $no;
				
			if ( $all < $min_votes )
			{
				$bot->send_chatter( "Vote failed. Not enough players voted. (Minimum: $min_votes)." );
			}
			elsif ( $yes < $no )
			{
				$bot->send_chatter( "Vote failed. Not enough pro votes ( $yes < $no )." );
			}
			else
			{
				$bot->send_chatter( "Vote succeeded  ( $yes >= $no )." );
				
				$bot->process_command( $vote->{command}, $bot->config->{Server}->{BotName} );
			}
		
			return 1;			
		}
	}};

1;