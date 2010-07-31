package FancyBot::UserHandling;

use Moose::Role;

use FancyBot::User;
use FancyBot::Mech;
use Data::Dumper;
use JSON;

has last_update =>
	is      => 'rw',
	isa     => 'Int',
	default => 0;

has pending_kicks =>
	is      => 'ro',
	isa     => 'ArrayRef',
	default => sub { [] };

	
sub is_admin
{
	my $self   = shift;
	my $name = shift;
	
	return 1 if $self->is_super_admin($name);

	my $admins = $self->config->{Security}->{Admins}->{Admin}; 
	   $admins = [$admins] unless ref $admins  eq "ARRAY";

	return 1 if grep { ref $_ ? ( $_->{content} eq $name ) : $_ eq $name } @$admins;
	return 0;
}

sub is_super_admin
{
	my $self   = shift;
	my $name = shift;

	my $admins = $self->config->{Security}->{SuperAdmins}->{Admin}; 
	   $admins = [$admins] unless ref $admins eq "ARRAY";

	return 1 if grep { ref $_ ? ( $_->{content} eq $name ) : $_ eq $name } @$admins;
	return 0;
}

sub kick_a_player
{
	+shift->screen->kick_a_player();
}

sub kick_player
{
	+shift->screen->kick_player( @_ );
}

sub user
{
	my $self = shift;
	my $name = shift;
	my ( $mech, $bot, $team );
	
	if ( ref $name )
	{
		$mech = $name->{mech};
		$bot  = $name->{level} > 1;
		$team = $name->{team} || 0;
		$name = $name->{name};
	}
	else
	{
		$team = 0;
		$bot  = 0;
		$mech = { Name => 'Camera Ship', Weight => 0, Variant => 'Stock' };
	}
	
	$self->users->{ $name } = FancyBot::User->new( 
		name => $name, 
		is_admin => $self->is_admin($name), 
		is_super_admin => $self->is_super_admin($name),
		bot => $bot,
		mech => FancyBot::Mech->new( name => $mech->{Name}, tonnage => $mech->{Weight}, variant => $mech->{Variant} )
	)
	unless defined $self->users->{ $name };

	return $self->users->{ $name };
}


1;