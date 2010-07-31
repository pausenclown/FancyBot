package FancyBot::GUI::Controls::CheckBox;

use Moose;
use Moose::Util::TypeConstraints;

extends 'FancyBot::GUI::Control';

subtype 'FancyBot::GUI::Controls::CheckBox::Value' => as 'Bool';

coerce 'FancyBot::GUI::Controls::CheckBox::Value'
	=> from 'Any'
	=> via { 
		print "X $_ ";
		$_ = 1 if /^(true|on|1)$/i;
		$_ = 0 if /^(false|off|0)$/i;
		print "Y $_\n";
		$_;
	};
	
has value =>
	is     => 'rw',
	isa    => 'FancyBot::GUI::Controls::CheckBox::Value',
	coerce => 1;
		
sub set_value
{
	my ($self, $value) = @_;

	my $check = FancyBot::GUI::IsCheckedButton( $self->hwnd );

	$value = $self->value( $value );
	
	return 1 if $value == $check;
	
	FancyBot::GUI::SendMessage(  $self->hwnd , $self->constants->{BM_SETCHECK}, $value, 0);
	
	return FancyBot::GUI::IsCheckedButton( $self->hwnd );
}

sub get_value
{
	my $self = shift;
	return FancyBot::GUI::IsCheckedButton( $self->hwnd );
}

1;