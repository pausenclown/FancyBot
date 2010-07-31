package FancyBot::GUI::Controls::TrickyButton;

use Moose;

extends 'FancyBot::GUI::Control';

has caption => 
	is   => 'rw',
	isa  => 'Str';

sub push
{
	my $self    = shift;
	my $value   = shift;
	
	my $ohwnd  = FancyBot::GUI::GetForegroundWindow();

	FancyBot::GUI::SetFocus( $self->hwnd );
	FancyBot::GUI::SendKeys( '{SPACE}' );
	
	FancyBot::GUI::SetForegroundWindow( $ohwnd );
}


1;