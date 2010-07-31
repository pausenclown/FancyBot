package FancyBot::GUI::Controls::TrickyComboBox;

use Moose;

extends 'FancyBot::GUI::Controls::ComboBox';

sub set_value
{
	my $self    = shift;
	my $value   = shift;
	my $map     = shift;
	
	my $ohwnd = FancyBot::GUI::GetForegroundWindow();	

	$value = FancyBot::GUI::GetListText( $self->hwnd , $value)
		if $value =~ /^\d+$/;
	
	$value = $map->{$value} || $value
		if $map;

	$self->set_raw_value( $value );
	
	FancyBot::GUI::SetForegroundWindow( $ohwnd );	
}

sub set_raw_value
{
	my $self    = shift;
	my $value   = shift;

	FancyBot::GUI::SetForegroundWindow( $self->hwnd );
	FancyBot::GUI::SetFocus(  $self->hwnd  ); 
	FancyBot::GUI::SendKeys("{HOME}"); 
	FancyBot::GUI::SendKeys( $value );

}

1;