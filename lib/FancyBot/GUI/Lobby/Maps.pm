package FancyBot::GUI::Lobby::Maps;

use Moose::Role;
use Data::Dumper;

sub map {
	my $self   = shift;
	return $self->get_control( 'mpbMaps')->get_value;
}

sub maps {
	my $self   = shift;
	my $search = shift;
	my @maps   = $self->get_control( 'mpbMaps')->get_list( $self->map, $search );

	# Due to a glitch in the Tangle map it will add 4 bots when selected
	# This breaks the bot handling code so strip it
	@maps = grep { !/^tangle/i } @maps if $self->game_type eq "Team Battle";
	
	return @maps;
}

sub select_map {
	my $self   = shift;
	my $search = shift;


	# Due to a glitch in the Tangle map it will add 4 bots when selected
	# This breaks the bot handling code so strip it
	return 0 if $search =~/^tangle/i && $self->game_type eq "Team Battle";

	print "SM $search\n";
	my @candidates = $self->maps( $search );
	
	@candidates = grep { $_ eq $search } @candidates
		if @candidates > 1;
		
	return 0
		if @candidates > 1 || @candidates == 0;

	print "SM! $search\n";
	return $self->get_control( 'mpbMaps')->set_value( $search );
}

sub select_random_map
{
	my $self = shift;
	my $map  = shift || '*';
	print "SRM $map\n";
	if ( $map eq "*" )
	{
		my $maps = [ $self->maps ];
		$map = $maps->[ int(rand(scalar @$maps)) ];
		print "SRM! $map\n";
	}
	elsif ( $map =~ /,/ )
	{
		my $maps = [ split /,/, $map ];
		$map = $maps->[ int(rand(scalar @$maps)) ];
	}
	
	return $self->select_map( $map );
}

1;
