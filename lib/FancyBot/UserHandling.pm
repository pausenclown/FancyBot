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

	return 1 if grep { print "* $_ eq $name\n"; ref $_ ? ( $_->{content} eq $name ) : $_ eq $name } @$admins;
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

sub connected_users
{
	my $self  = shift;
	my $users = $self->users;
	
	return 
	{ 
		map  { $_ => $users->{$_}         }
		grep { $users->{$_}->is_connected }
		keys %$users
	};
}

sub connected_users_as_list
{
	my $self  = shift;
	my $users = $self->connected_users;
	print Dumper( $users, $self->users );
	return 
	[ 
		sort   { $a->position <=> $b->position } 
		values %$users
	];
}


sub connected_humans
{
	my $self  = shift;
	my $users = $self->users;
	
	return 
	{ 
		map  { $_ => $users->{$_}         }
		grep { $users->{$_}->is_connected }
		grep { !$users->{$_}->is_bot }
		grep { !$users->{$_}->is_server_bot }
		keys %$users
	};
}

sub connected_humans_as_list
{
	my $self  = shift;
	my $users = $self->connected_users;
	
	return 
	[ 
		sort   { $a->position <=> $b->position }
		grep   { !$_->is_bot }
		grep   { !$_->is_server_bot }
		values %$users
	];
}


sub connect_user
{
	my $self = shift;
	my $name = shift;

	my ( $mech, $bot, $team, $position );
	
	if ( ref $name )
	{
		$mech = $name->{mech};
		$bot  = $name->{level} ?  1 : 0;
		$team = $name->{team} || 0;
		$position = $name->{position};
		$name = $name->{name};
	}
	else
	{
		$team = 0;
		$bot  = 0;
		$position = -1;
		$mech = { Name => 'Camera Ship', Weight => 0, Variant => 'Stock' };
	}
	
	$mech = FancyBot::Mech->new( 
		name => $mech->{Name}, tonnage => $mech->{Weight}, variant => $mech->{Variant} || '' 
	);
	
	if ( my $user = $self->users->{ $name } )
	{
		
		$user->bot( $bot );
		$user->team( $team );
		$user->mech( $mech );
		$user->position( -1 );
		$user->is_admin( $self->is_admin($name) ); 
		$user->is_super_admin( $self->is_super_admin($name) ); 
	}
	else
	{
		$self->users->{ $name } = FancyBot::User->new( 
			bot      => $bot,
			team     => 0,
			name     => $name, 
			mech     => $mech,
			position => $position,
			is_admin => $self->is_admin($name), 			
			is_super_admin => $self->is_super_admin($name),
			is_server_bot  => $self->{config}->{Server}->{BotName} eq $name,
		)
	}
}

sub user
{
	my $self = shift;
	my $name = shift;

	return $self->users->{ $name };
}

sub update_player_info
{
	my $self = shift;
	
	if ( $self->last_update == $FancyBot::GUI::Watcher::last_update )
	{
		return;
	}
	else
	{
		my $info = FancyBot::GUI::Watcher::player_info( (FancyBot::GUI::GetChildWindows( $self->main_hwnd ))[80] );
		
		for my $name ( keys %$info )
		{
			my $user = $self->user( $name );
			
			next unless $user;
			
			$user->position     ( $info->{$name}->{position} );
			$user->is_bot       ( $info->{$name}->{bot}>0 );
			$user->team         ( $info->{$name}->{team} );
			$user->is_connected ( 1 );
			
			$user->mech         
			( 
				FancyBot::Mech->new
				(
					name    => $info->{$name}->{mech},
					tonnage => $info->{$name}->{tonnage},
					variant => $info->{$name}->{variant}
				)
			);
		}
		
		for my $name ( keys %{ $self->{users} } )
		{
			$self->{users}->{$name}->is_connected( 0 )
				unless $info->{ $name };
		}
		
		$self->last_update( $FancyBot::GUI::Watcher::last_update );
		print "[DEBUG] player info up to date\n";

		$self->raise_event( 'player_info_updated', { bot => $self } );
	}
}

sub delete_user
{
	my $self = shift;
	my $name = shift;
	
	delete $self->users->{$name};
}

1;