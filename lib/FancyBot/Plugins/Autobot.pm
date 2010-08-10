=head1 FancyBot::Plugins::Autobot

=head1 SYNOPSIS
 
=head1 DESCRIPTION

=cut

package FancyBot::Plugins::Autobot;

use Moose;
use Data::Dumper;

has events =>
	isa     => 'HashRef',
	is      => 'ro',
	default => sub {{
		'player_info_updated' => sub 
		{
			# Fetch arguments
			my $args  = shift;

			# Make sure we got a bot reference
			my $bot  = $args->{bot} || die 'No bot reference';

			if ( @{ $bot->pending_team_assignments } )
			{
				while ( @{ $bot->pending_team_assignments } )
				{
					my $assignment = shift @{ $bot->pending_team_assignments };
					$bot->select_team_for( @$assignment  );
				}					
				return;
			}
			
			if ( @{ $bot->pending_mech_assignments } )
			{
				for ( @{ $bot->pending_mech_assignments } )
				{
					my $assignment = shift @{ $bot->pending_mech_assignments };
					$bot->select_mech_for( @$assignment );
				}					
				return;
			}
			
			# let the processing continue unless we messed with the list
			return 1;
		}
	}};

1;
