package FancyBot::GUI::Controls::Button;

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

	FancyBot::GUI::PushChildButton( (FancyBot::GUI::FindWindowLike(0, 'MechWarrior 4 Mercenaries Win32Dedicated Server'))[0], $self->caption||$self->hwnd );
	
	FancyBot::GUI::SetForegroundWindow( $ohwnd );
}


1;