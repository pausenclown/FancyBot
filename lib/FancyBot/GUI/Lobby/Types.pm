package FancyBot::GUI::Lobby::Types;

use Moose::Role;
use Data::Dumper;

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

sub select_random_game_type
{
	my $self  = shift;
	my $gtype = shift || '*';
	
	if ( $gtype eq "*" )
	{
		my $gtypes = [ $self->game_types ];
		$gtype = $gtypes->[ int(rand(scalar @$gtypes)) ];
	}
	elsif ( $gtype =~ /,/ )
	{
		my $gtypes = [ split /,/, $gtype ]; 
		$gtype = $gtypes->[ int(rand(scalar @$gtypes)) ];
		# print Dumper( $gtypes, $gtype );
	}
	
	return $self->select_game_type( $gtype );
}


1;
