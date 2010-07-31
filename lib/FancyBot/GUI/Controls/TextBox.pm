package FancyBot::GUI::Controls::TextBox;

use Moose;

extends 'FancyBot::GUI::Control';

	
sub set_value
{
	my $self    = shift;
	my $value   = shift;
	
	my $ohwnd = FancyBot::GUI::GetForegroundWindow();	

	FancyBot::GUI::WMSetText($self->hwnd, $value);
}


sub get_value
{
	my $self = shift;
	return FancyBot::GUI::WMGetText($self->hwnd);
}


1;