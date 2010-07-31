package FancyBot::GUI::Controls::ComboBox;

use Moose;

extends 'FancyBot::GUI::Control';

has value =>
	isa    => 'Str',
	is     => 'rw';
	
sub set_value
{
	my $self    = shift;
	my $value   = shift;

	my $ohwnd = FancyBot::GUI::GetForegroundWindow();	

	FancyBot::GUI::SelComboItemText( $self->hwnd, $value );
	FancyBot::GUI::SetForegroundWindow( $ohwnd );	
}


sub get_value
{
	my $self = shift;
	return FancyBot::GUI::WMGetText( $self->hwnd );
}

sub get_list
{
	my $self = shift;
	return FancyBot::GUI::GetComboContents( $self->hwnd );
}

1;