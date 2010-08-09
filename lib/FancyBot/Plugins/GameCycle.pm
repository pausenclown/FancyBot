=head1 FancyBot::Plugins::GameCycle

=head1 SYNOPSIS
 
=head1 DESCRIPTION

=cut

package FancyBot::Plugins::GameCycle;

use Moose;
use Data::Dumper;

has events =>
	isa     => 'HashRef',
	is      => 'ro',
	default => sub {{
		'game_stop' => sub { configure_game( @_ ) },
		'game_next' => sub { configure_game( @_ ) },
	}}
;

sub configure_game
{
	# Fetch args from @_
	my $args  = shift;
	my $bot   = $args->{bot};
	my $pos   = $bot->config->{GameCycle}->{CyclePosition} || 0;
	my $games = $bot->config->{GameCycle}->{Game};
	my @games = ref $games eq 'ARRAY' ? @$games : ( $games );
	my $game  = $games[ $pos ];

	$bot->screen->select_random_game_type( $game->{GameType} );
	sleep(1);
	
	$bot->screen->select_random_map( $game->{MapName} );
	sleep(1);
	
	$bot->screen->select_random_visibility( $game->{Visbility} ); 
	sleep(1);
	
	$bot->screen->select_random_daytime( $game->{TimeOfDay} ); 
	sleep(1);
	
	$bot->screen->select_random_stock( $game->{Stock} );
	sleep(1);
	
	$bot->screen->select_random_radar( $game->{Radar} );
	sleep(1);
	

	$bot->config->{GameCycle}->{CyclePosition}++;
	
	$bot->config->{GameCycle}->{CyclePosition} = 0
		if $bot->config->{GameCycle}->{CyclePosition} >= @games;
}

1;