package FancyBot::GUI::Controls::ChatterBox

use Moose;

extends 'FancyBot::GUI::Control';
	
sub set_value
{
	my $self   = shift;
	my $text   = shift;
	my $char   = shift || " ";
	my $length = shift || 100;

	my $ohwnd  = FancyBot::GUI::GetForegroundWindow();
	
	while ( $text )
	{
		$self->_send_value( $text ), last
			if length($text) < $length;	
	
		my $i = rindex( $text, $char , $length );
			
		my $t = substr( $text, 0, $i);

		substr( $text, 0, ($i + length($char)) ) = '';
		$self->_send_value( $t );
	}

	FancyBot::GUI::SetForegroundWindow( $ohwnd );
	
	return 1;
}

sub _send_value {
	my $self   = shift;
	my $msg    = shift;
	
	FancyBot::GUI::WMSetText( $hwnd, $msg );

	while ( WMGetText( $hwnd ) ) {
		FancyBot::GUI::SetForegroundWindow( $self->bot->main_hwnd );
		FancyBot::GUI::SetFocus( $hwnd ); FancyBot::GUI::SendKeys("{END}{ENTER}");
	}
}

1;