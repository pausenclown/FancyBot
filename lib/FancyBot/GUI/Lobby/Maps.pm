package FancyBot::GUI::Lobby::Maps;

use Moose::Role;

sub map {
	my $self   = shift;
	return $self->get_control( 'mpbMaps')->get_value;
}

sub maps {
	my $self   = shift;
	my $search = shift;
	
	return $self->get_control( 'mpbMaps')->get_list( $self->game_type, $search );
}

sub select_map {
	my $self   = shift;
	my $search = shift;
	
	my @candidates = $self->maps( $search );
	
	@candidates = grep { $_ eq $search } @candidates
		if @candidates > 1;
		
	return 0
		if @candidates > 1 || @candidates == 0;

	return $self->get_control( 'mpbMaps')->set_value( $search );
}	

1;
