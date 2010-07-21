package FancyBot::GUI::Lobby;

use Moose;

use Win32::GuiTest qw( GetListViewContents GetForegroundWindow GetComboContents SetForegroundWindow SendMessage MouseClick PushChildButton WMSetText WMGetText SelComboItemText GetListContents GetChildWindows SetFocus SendKeys SendRawKey :VK );
use FancyBot::GUI::HostSetup;

extends 'FancyBot::GUI';

has _maps => 
	isa     => 'HashRef',
	is      => 'ro',
	default => sub {{
		
	}};
	

use Data::Dumper;


sub update_gui
{
	my $self = shift;
	WMSetText( (GetChildWindows( $self->bot->main_hwnd ))[179],  "179" );
	WMSetText( (GetChildWindows( $self->bot->main_hwnd ))[169],  "169" );
	WMSetText( (GetChildWindows( $self->bot->main_hwnd ))[66],  "66" );
	# WMSetText( (GetChildWindows( $self->bot->main_hwnd ))[79],  "79" );
	# $self->send_chatter('test');
	# $self->bot->hosting( 1 );
}

sub player_info
{
	my $self   = shift;
	
	my @list = grep { $_ ne ' ' } GetListContents( (GetChildWindows( $self->bot->main_hwnd ))[80] );
	my $count = @list / 7;
	my %players;
		
	if ( @list > 4 )
	{
		for ( my $i=0; $i<$count; $i++ ) 
		{
			$list[$i+(5*$count)] =~ s/^(\d+)(.+)/$1/;
			
			$players{ $list[$i] } = {
				mech    => $list[$i+(1*$count)], 
				variant => $list[$i+(2*$count)],
				tonnage => $list[$i+(3*$count)],
				c_bills => $list[$i+(4*$count)],
				team    => $list[$i+(5*$count)],
				status  => $list[$i+(6*$count)],
			};
			
			
		}
	}
	
	return \%players;
}

sub send_chatter {
	my $self   = shift;
	my $msg    = shift;
	
	return $self->send_long_chatter( 80, " ", $msg) 
		if  length($msg) > 80;
	
	my $hwnd   = (GetChildWindows( $self->bot->main_hwnd ))[79];
	my $ohwnd  = GetForegroundWindow();
	
	WMSetText( $hwnd, $msg );
	$self->bot->raise_event( 'debug', { message => 'sending chatter' } ); my $i = 1;
	while ( WMGetText( $hwnd ) ) {
		$self->bot->raise_event( 'debug', { message => 'trying ' .$i++ } );
		SetForegroundWindow( $self->bot->main_hwnd );
		SetFocus( $hwnd ); SendKeys("{END}{ENTER}");
	}
	
}

sub send_chatter2 {
	my $self   = shift;
	my $msg    = shift;
	my $hwnd   = (GetChildWindows( $self->bot->main_hwnd ))[79];
	my $ohwnd  = GetForegroundWindow();
	
	WMSetText( $hwnd, $msg );
	$self->bot->raise_event( 'debug', { message => 'sending chatter' } ); my $i = 1;
	while ( WMGetText( $hwnd ) ) {
		$self->bot->raise_event( 'debug', { message => 'trying ' .$i++ } );
		SetForegroundWindow( $self->bot->main_hwnd );
		SetFocus( $hwnd ); 
		SendKeys("{END}{ENTER}");
	}
	
}

sub send_long_chatter 
{
	my $self   = shift;
	my $length = shift;
	my $char   = shift || " ";
	my $text   = shift;
		
	while ( $text )
	{
		$self->send_chatter( $text ), last
			if length($text) < $length;	
	
		print "T $text\n";
		my $i = rindex( $text, $char , $length );
		print "i $i\n";
			
		my $t = substr( $text, 0, $i);
		print "t $text\n";
		substr( $text, 0, ($i + length($char)) ) = '';
		$self->send_chatter( $t );
		

	}
	
	return 1;
}

sub launch {
	my $self   = shift;
	my $ohwnd  = GetForegroundWindow();
	PushChildButton( $self->bot->main_hwnd, 'LAUNCH' );
	SetForegroundWindow( $ohwnd );
}

sub stop_map {
	my $self   = shift;
	my $ohwnd  = GetForegroundWindow();
	PushChildButton( $self->bot->main_hwnd, 'STOP' );
	SetForegroundWindow( $ohwnd );
}

sub game_type {
	my $self   = shift;
	my $hwnd   = (GetChildWindows( $self->bot->main_hwnd ))[55];
	return WMGetText( $hwnd )
}

sub game_types {
	my $self   = shift;
	my $hwnd   = (GetChildWindows( $self->bot->main_hwnd ))[55];
	return GetListContents( $hwnd )
}

sub select_game_type {
	my $self   = shift;
	my $idx    = shift;
	my $hwnd   = (GetChildWindows( $self->bot->main_hwnd ))[55];
	
	if ( $idx =~ /^\d+$/ )
	{
		SelComboItem($hwnd, $idx);
	}
	else
	{
		SelComboItemText( $hwnd, $idx )
	}
	return 1;
}

sub map {
	my $self   = shift;
	my $hwnd   = (GetChildWindows( $self->bot->main_hwnd ))[57];
	return WMGetText( $hwnd )
}

sub maps {
	my $self   = shift;
	my $hwnd   = (GetChildWindows( $self->bot->main_hwnd ))[57];
	my $idx    = shift;
	my $type   = $self->game_type;
	my $maps; 
	
	unless ( $self->_maps->{ $type } )
	{
		for ( GetComboContents( $hwnd ) )
		{
			$self->_maps->{ $type }->{ $1 } = $_
				if /^(.+?) - [^\-]+$/;
		}
	}
	
	$maps = [ sort keys %{ $self->_maps->{ $type } } ];
		
	return grep { /$idx/ } @$maps
		if $idx;
		
	return @$maps;
}

sub select_map {
	my $self   = shift;
	my $idx    = shift;
	my $hwnd   = (GetChildWindows( $self->bot->main_hwnd ))[57];
	my $ohwnd = GetForegroundWindow();	
	my $type   = $self->game_type;
	
	# if ( $idx =~ /^\d+$/ )
	# {
		# SelComboItem($hwnd, $idx);
		# return 1;
	# }
	my @candidates = $self->maps( $idx );
	
	@candidates = grep { $_ eq $idx } @candidates
		if @candidates > 1;

		
	return 0
		if @candidates > 1 || @candidates == 0;
	
	my $map = $self->_maps->{ $type }->{ $candidates[0] };
	
	$self->send_chatter2( "Selecting map $map" );
	SetForegroundWindow( $self->bot->main_hwnd );
	SetFocus( $hwnd ); SendKeys("{HOME}"); sleep(3); SendKeys( $map );
	SetForegroundWindow( $ohwnd );
	
	
	return 1;
}


1;









