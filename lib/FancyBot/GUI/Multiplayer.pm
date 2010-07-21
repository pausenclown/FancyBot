package FancyBot::GUI::Multiplayer;

use Moose;

use Win32::GuiTest qw( SetForegroundWindow PushChildButton SelComboItemText GetChildWindows );
use FancyBot::GUI::HostSetup;

extends 'FancyBot::GUI';

sub connection 
{
	my $self = shift;
	my $conn = shift;
	SelComboItemText( (GetChildWindows( $self->bot->main_hwnd ))[4], $conn );
}

sub quit
{
	my $self = shift;
	PushChildButton( $self->bot->main_hwnd, 'QUIT' );
}

sub next 
{
	my $self = shift;
	
	while ( !(GetChildWindows( $self->bot->main_hwnd ))[11] )
	{
		SetForegroundWindow( $self->bot->main_hwnd );
		PushChildButton( $self->bot->main_hwnd, 'NEXT' );
		sleep(5);
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
