package FancyBot::User;

use Moose;

has name =>
	isa     => 'Str',
	is      => 'rw';

has is_super_admin =>
	isa     => 'Bool',
	is      => 'rw',
	default => 0;
	
has is_admin =>
	isa     => 'Bool',
	is      => 'rw',
	default => 0;

has times_connected =>
	isa     => 'Int',
	is      => 'rw',
	default => 0;
	
has times_joined =>
	isa     => 'Int',
	is      => 'rw',
	default => 0;
	
has kills_overall =>
	isa     => 'Int',
	is      => 'rw',
	default => 0;

has kills_this_match =>
	isa     => 'Int',
	is      => 'rw',
	default => 0;
	
has current_kill_streak =>
	isa     => 'Int',
	is      => 'rw',
	default => 0;	

has longest_kill_streak =>
	isa     => 'Int',
	is      => 'rw',
	default => 0;	
	
has deaths_overall =>
	isa     => 'Int',
	is      => 'rw',
	default => 0;

has deaths_this_match =>
	isa     => 'Int',
	is      => 'rw',
	default => 0;

has current_death_streak =>
	isa     => 'Int',
	is      => 'rw',
	default => 0;	

has longest_death_streak =>
	isa     => 'Int',
	is      => 'rw',
	default => 0;	

has stash =>
	isa     => 'HashRef',
	is      => 'ro',
	default => sub {{}};
	
sub is_allowed_to {
	my $self    = shift;
	my $command = shift;
	
	return 
		if $command->{IsSuperAdminCommand} && !$self->is_super_admin;

	return 
		if $command->{IsAdminCommand} && !$self->is_admin;

	return 1;
}

1;