package FancyBot::GUI::Controls::TrickyCheckBox;

use Moose;

extends 'FancyBot::GUI::Controls::CheckBox';


has caption => 
	is   => 'rw',
	isa  => 'Str';

sub set_value
{
	my $self  = shift;
	my $value = shift;

	my $check = FancyBot::GUI::IsCheckedButton( $self->hwnd );
	
	$value = $self->value( $value );

	return 1 if $value == $check;
	
	FancyBot::GUI::PushChildButton( (FancyBot::GUI::FindWindowLike(0, 'MechWarrior 4 Mercenaries Win32Dedicated Server'))[0], $self->caption );
	
	return 1;
}

1;

