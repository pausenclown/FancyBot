package FancyBot::GUI;

use Moose;

use Win32::GuiTest qw( SendMessage );
use FancyBot::GUI::Multiplayer;

has bot =>
	isa => 'FancyBot',
	is  => 'rw';
	

sub start_screen
{
	my $self = shift;
	my $scr  = FancyBot::GUI::Multiplayer->new( bot => $self->bot );
	$scr->update_gui;
	
	return $scr;
}

sub set_checkbox_value
{
	my $BM_SETCHECK = 241;
	my $BST_CHECKED = 1;
	my $BST_UNCHECKED = 0;

	my ($self, $hwnd, $value) = @_;
		
	$value = 0              if !defined $value;
	$value = $BST_CHECKED   if $value =~ /true/i;
	$value = $BST_UNCHECKED if $value =~ /false/i;
		
	SendMessage( $hwnd, $BM_SETCHECK, $value, 0);
}

1;