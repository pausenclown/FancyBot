package FancyBot::GUI;

use Moose;

use Win32::GuiTest qw( PushButton PushChildButton WMGetText MouseClick SendMessage IsCheckedButton GetForegroundWindow SetForegroundWindow SetFocus SendKeys IsWindowEnabled PostMessage GetChildWindows);
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
	my $BM_SETCHECK   = 241;
	my $BST_CHECKED   = 1;
	my $BST_UNCHECKED = 0;

	my ($self, $hwnd, $value) = @_;
	
	$value = 0              if !defined $value;
	$value = $BST_CHECKED   if $value =~ /(true|on)/i;
	$value = $BST_UNCHECKED if $value =~ /(false|off)/i;
	
	if ( $hwnd =~ /^\d+$/ )
	{
		my $check = IsCheckedButton($hwnd);

		return 1 if $value && IsCheckedButton($hwnd);
		return 1 if !$value && !IsCheckedButton($hwnd);

		SendMessage( $hwnd, $BM_SETCHECK, $value, 0);
	}
	else
	{
        for my $child ( GetChildWindows($self->bot->main_hwnd) ) 
		{
			if ( WMGetText( $child ) eq  $hwnd )
			{
				return 1 if $value && IsCheckedButton($child);
				return 1 if !$value && !IsCheckedButton($child);
				
				PushChildButton($self->bot->main_hwnd, $hwnd);
			}
		}
	}
	
	return;
	

}

sub set_combo_value
{
	my $self    = shift;
	my $index   = shift;
	my $sel     = shift;
	my $map     = shift;
	my @windows = GetChildWindows( $self->bot->main_hwnd );
	
	my $hwnd   = $windows[$index];
	
	my $ohwnd = GetForegroundWindow();	
	
	return if $map && !$map->{ $sel };
	
	SetForegroundWindow( $self->bot->main_hwnd );
	SetFocus( $hwnd ); SendKeys("{HOME}"); sleep(3); SendKeys( $map ? $map->{ $sel } : $sel );
	SetForegroundWindow( $ohwnd );
}

1;