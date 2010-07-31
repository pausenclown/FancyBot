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
			my $bot  = $args->{bot}         || die 'No bot reference';
		
			my $mecha = $bot->pending_mech_assignments;
			my $teama = $bot->pending_team_assignments;
			
			print Dumper ( ["assignments", $mecha, $teama] );
			
			if ( @$teama )
			{
				for ( @$teama )
				{
					$bot->select_team_for( $_->[0], $_->[1]  );
				}					
				return;
			}
			
			if ( @$mecha )
			{
				for ( @$mecha )
				{
					$bot->select_mech_for( $_->[0], $_->[1]  );
				}					
				return;
			}
			
			# let the processing continue unless we messed with the list
			return 1;
		}
	}};

1;
