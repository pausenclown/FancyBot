package FancyBot::GUI::Multiplayer;

use Moose;

use Win32::GuiTest qw( SetForegroundWindow PushChildButton SelComboItemText GetChildWindows );
use FancyBot::GUI::HostSetup;

extends 'FancyBot::GUI';

sub connection 
{
	my $self = shift;
	my $conn = shift;
	$self->get_control('cmbConnection')->set_value( $conn );
}

sub quit
{
	my $self = shift;
	$self->get_control( 'btnQuit' )->push;
}

sub next 
{
	my $self = shift;
	
	while ( !$self->get_window_handle('cmbRadarMode') )
	{
		$self->get_control( 'btnNext' )->push;
		sleep(3);
	}
	
	$self->bot->screen( FancyBot::GUI::HostSetup->new( bot => $self->bot ) );
	$self->bot->update_gui;
}

sub update_gui
{
	my $self = shift;
	$self->connection( $self->bot->config->{'Server'}->{'Connection'} );
}
1;
