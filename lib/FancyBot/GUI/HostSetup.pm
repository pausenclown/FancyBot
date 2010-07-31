package FancyBot::GUI::HostSetup;

use Moose; 

use FancyBot::GUI::Multiplayer;
use FancyBot::GUI::Lobby;

extends 'FancyBot::GUI';

has bot =>
	isa => 'FancyBot',
	is  => 'rw';
	
sub update_gui
{
	my $self = shift;

	for (qw( 
		AdvertiseThisGame AllowCustomDecals ForceFirstPersonView LimitedAmmunitions HeatManagement 
		AllowJoinInProgress FriendlyFire SplashDamage ForceRespawn DeadMechsCantTalk DeadMechsCantSee 
		RestrictMechsAndComponents ServerRecycle
	))
	{
		$self->get_control("cb$_")->set_value( $self->bot->config->{'Server'}->{$_} );
	}
	
	for (qw( 
		RadarMode MaxNumberOfPlayers JoinTimeLimit DelayBetweenMaps
	))
	{
		$self->get_control( "cmb$_" )->set_value( $self->bot->config->{'Server'}->{$_} );
	}
	
	$self->get_control('txtServerName')->set_value( $self->bot->config->{'Server'}->{'Name'}. "!" );
	$self->get_control('txtPassword')->set_value( $self->bot->config->{'Server'}->{'Password'} );
	$self->get_control('cbPassword')->set_value( 1 ) if $self->bot->config->{'Server'}->{'Password'};
}

sub host
{
	my $self = shift;
	
	while ( !$self->get_window_handle('btnBan') )
	{
		$self->get_control('btnHost')->push;
		sleep(15);
	}
	
	$self->bot->raise_event( 'notice', { bot => $self->bot, message =>  "Initializing screen 3/3..." } );
	$self->bot->screen( FancyBot::GUI::Lobby->new( bot => $self->bot ) );
	$self->bot->update_gui;
}

sub back 
{
	my $self = shift;
	$self->get_control( 'btnBack' )->push;
	$self->bot->screen( FancyBot::GUI::Multiplayer->new( bot => $self->bot ) );
}

1;