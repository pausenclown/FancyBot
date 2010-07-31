package FancyBot::GUI::Control;

use Moose;

has hwnd => 
	is   => 'rw',
	isa  => 'Int';

has name => 
	is   => 'rw',
	isa  => 'Str';

has constants => 
	is    => 'ro',
	isa   => 'HashRef',
	default => sub {{
		BM_SETCHECK => 241,
		WS_VISIBLE  => 0x10000000,
	}};

sub enable {
	return FancyBot::GUI::EnableWindow( +shift->hwnd, 1 )
}

sub disable {
	return FancyBot::GUI::EnableWindow( +shift->hwnd, 0 )
}

sub is_visible
{
	my $self = shift;
	return FancyBot::GUI::IsWindowStyle( $self->hwnd, $self->constants->{WS_VISIBLE} );
}

1;