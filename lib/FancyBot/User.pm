package FancyBot::User;

use Moose;
use FancyBot::Mech;

has known_unit =>
	isa     => 'Str',
	is      => 'rw',
	default => '';

has name =>
	isa     => 'Str',
	is      => 'rw',
	default => '';
	
has team =>
	isa     => 'Int',
	is      => 'rw',
	default => '0';
	
has mech =>
	isa     => 'FancyBot::Mech',
	is      => 'rw',
	default => sub {
		FancyBot::Mech->new(
			name    => 'Camera',
			tonnage => 0,
			c_bills => 0,
			variant => 'Stock'
		);
	};

has is_bot =>
	isa     => 'Bool',
	is      => 'rw',
	default => 0;

has is_server_bot =>
	isa     => 'Bool',
	is      => 'rw',
	default => 0;
	
has is_super_admin =>
	isa     => 'Bool',
	is      => 'rw',
	default => 0;
	
has is_admin =>
	isa     => 'Bool',
	is      => 'rw',
	default => 0;

has is_authorized =>
	isa     => 'Bool',
	is      => 'rw',
	default => 0;

has times_connected =>
	isa     => 'Int',
	is      => 'rw',
	default => 0;

has is_connected =>
	isa     => 'Bool',
	is      => 'rw',
	default => 0;
	
has is_joined =>
	isa     => 'Int',
	is      => 'rw',
	default => 0;
	
has times_joined_this_match =>
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

has teamkills_overall =>
	isa     => 'Int',
	is      => 'rw',
	default => 0;

has teamkills_this_match =>
	isa     => 'Int',
	is      => 'rw',
	default => 0;
	
has suicides_overall =>
	isa     => 'Int',
	is      => 'rw',
	default => 0;

has suicides_this_match =>
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
	
has times_kicked =>
	isa     => 'Int',
	is      => 'rw',
	default => 0;	

has last_kick =>
	isa     => 'Int',
	is      => 'rw',
	default => 0;	

has position =>
	isa     => 'Int',
	is      => 'rw',
	default => -1;	

has stash =>
	isa     => 'HashRef',
	is      => 'ro',
	default => sub {{}};
	
sub is_allowed_to {
	my $self     = shift;
	my $command  = shift;
	my $paranoia = shift;
	
	
	return 
		if $command->{IsSuperAdminCommand} && !$self->is_super_admin;

	return 
		if $command->{IsAdminCommand} && !$self->is_admin;
		
	return
		if $paranoia && ( $command->{IsSuperAdminCommand} || $command->{IsAdminCommand} ) && !$self->is_authorized;

	return 1;
}

sub annotate
{
	my $self = shift;
	my $type = shift;
	my $msg  = shift;
	
	for my $method qw( name times_joined_this_match kills_overall kills_this_match suicides_overall suicides_this_match current_kill_streak longest_kill_streak deaths_overall deaths_this_match current_death_streak longest_death_streak )
	{
		$msg =~ s/\%${type}_${method}/$self->$method/ge;
	}
	
	for my $method qw( name tonnage variant c_bills )
	{
		$msg =~ s/\%${type}_mech_${method}/$self->mech->$method/ge;
	}
	
	my $unit = $self->known_unit||'Your Team';
	$msg =~ s/\%${type}_unit/$unit/g;
	
	
	return $msg;
}

1;