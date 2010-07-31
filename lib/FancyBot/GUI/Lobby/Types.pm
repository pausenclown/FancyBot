package FancyBot::GUI::Lobby::Types;

use Moose::Role;

sub game_type {
	my $self   = shift;
	return $self->get_control( 'tcmbGameTypes')->get_value;
}

sub game_types {
	my $self   = shift;
	return $self->get_control( 'tcmbGameTypes')->get_list;
}

sub select_game_type {
	my $self   = shift;
	my $search = shift;
	
	return $self->get_control( 'tcmbGameTypes')->set_value( $search, {
		b     => 'Battle',
		d     => 'Destruction',
		tb    => 'Team Battle',
		td    => 'Team Destruction',
		cb    => 'Custom Battle',
		ctb   => 'Custom Team Battle',
		'cmp' => 'Custom Mission Play',
		cu    => 'Custom Undefined',
	});
}

1;
