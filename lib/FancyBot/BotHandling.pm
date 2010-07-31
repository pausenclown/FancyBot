package FancyBot::BotHandling;

use Moose::Role;


has pending_mech_assignments =>
	is      => 'ro',
	isa     => 'ArrayRef',
	default => sub { [] };
	
has pending_team_assignments =>
	is      => 'ro',
	isa     => 'ArrayRef',
	default => sub { [] };


sub assign_mech_for
{
	+shift->screen->assign_mech_for( @_ );
}

sub assign_team_for
{
	+shift->screen->assign_team_for( @_ );
}

sub select_mech_for
{
	+shift->screen->select_mech_for( @_ );
}

sub select_team_for
{
	+shift->screen->select_team_for( @_ );
}

1;