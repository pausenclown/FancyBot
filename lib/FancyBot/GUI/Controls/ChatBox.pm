package FancyBot::GUI::Controls::ChatBox;

use Moose;

extends 'FancyBot::GUI::Control';
	
sub set_value
{
	my $self   = shift;
	my $text   = shift;
	my $char   = shift || " ";
	my $length = shift || 90;

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
	
	FancyBot::GUI::WMSetText( $self->hwnd, $msg );

	while ( my $s = FancyBot::GUI::WMGetText( $self->hwnd ) ) {
		print "!$s!\n";
		FancyBot::GUI::SetForegroundWindow( (FancyBot::GUI::FindWindowLike(0, 'MechWarrior 4 Mercenaries Win32Dedicated Server'))[0] );
		FancyBot::GUI::SetFocus( $self->hwnd ); FancyBot::GUI::SendKeys("{END}{ENTER}");
	}
}

1;