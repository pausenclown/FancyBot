package FancyBot::Mech;

use Moose;

has name =>
	isa     => 'Str',
	is      => 'rw';

has variant =>
	isa     => 'Str',
	is      => 'rw';
	
has tonnage =>
	isa     => 'Int',
	is      => 'rw',
	default => 0;

has c_bills =>
	isa     => 'Int',
	is      => 'rw',
	default => 0;
	
1;