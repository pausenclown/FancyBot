package FancyBot::GUI::Lobby;

use Moose;
use Data::Dumper;

use Win32::GuiTest qw( EnableWindow IsWindowStyle GetListText GetListViewContents GetForegroundWindow IsCheckedButton GetComboContents SetForegroundWindow SendMessage MouseClick PushChildButton WMSetText WMGetText SelComboItemText GetListContents GetChildWindows SetFocus SendKeys SendRawKey :VK );
use Time::HiRes qw( usleep );

extends 'FancyBot::GUI';

has _maps => 
	isa     => 'HashRef',
	is      => 'ro',
	default => sub {{
		
	}};
	
sub update_gui
{
	my $self = shift;
	WMSetText( (GetChildWindows( $self->bot->main_hwnd ))[179],  "179" );
	WMSetText( (GetChildWindows( $self->bot->main_hwnd ))[169],  "169" );
	WMSetText( (GetChildWindows( $self->bot->main_hwnd ))[66],  "66" );
	# WMSetText( (GetChildWindows( $self->bot->main_hwnd ))[79],  "79" );
	# $self->send_chatter('test');
	# $self->bot->hosting( 1 );
	# print Dumper ( $self->player_info );
}

sub player_info
{
	my $self   = shift; my @list;
	for (my $i = 0; $i < 24; $i++) 
	{
		for (my $j = $i; $j < 500; $j+=24)
		{
			# print "!", GetListText( (GetChildWindows( $self->bot->main_hwnd ))[$j], 0 ), "\n";
		}
	}
	
	@list = GetListContents( (GetChildWindows( $self->bot->main_hwnd ))[80] );
	my %players;
	
	# print Dumper( \@list );
	
	for (my $i = 0; $i < 24; $i++) 
	{
		my @subcontent;
		for (my $j = $i; $j < @list; $j+=24)
		{
			push @subcontent, $list[$j];
		}
		
		@subcontent = map { s/^ $//; $_ } @subcontent;
		
		last unless grep { $_ } @subcontent;
		
		$subcontent[3] =~ s/\..+//;
		$subcontent[4] =~ s/^.*(\d+).*$/$1/;
		$subcontent[7] =  $subcontent[5] =~ /BL:(\d+)/ ? $1 : 0;
		$subcontent[5] =~ s/(\d+).+/$1/;
	
		$players{ $subcontent[0] } = {
			mech    => $subcontent[1],
			variant => $subcontent[2],
			tonnage => $subcontent[3],
			c_bills => $subcontent[4],
			team    => $subcontent[5],
			status  => $subcontent[6],
			bot     => $subcontent[7],
		};
	}
	
	# print Dumper( \%players );
	
	return \%players;
}
# use Win32::Capture;
 
sub MyGetListContents {
	my $LB_GETTEXTLEN = 0x18A;
	my $LB_GETTEXT    = 0x189;
	my $LB_GETCOUNT   = 0x18B;
	
	my $hwnd = shift;
	
    my $nelems = SendMessage($hwnd, $LB_GETCOUNT, 0, 0);

	my @content;
	
    for (my $i = 0; $i < 24; $i++) 
	{
		my @subcontent;
		for (my $j = $i; $j < $nelems; $j+=24)
		{
			print " $hwnd $j\n ";
			push @subcontent, eval { MyGetListText( $hwnd, $j) };
			print "! $@ / $!\n";
		}
		
		@subcontent = map { s/^ $//; $_ } @subcontent;
		
		last unless grep { $_ } @subcontent;
		
		$subcontent[3] =~ s/\..+//;
		$subcontent[4] =~ s/k//;
		$subcontent[7] =  $subcontent[5] =~ /BL:(\d+)/ ? $1 : 0;
		$subcontent[5] =~ s/(\d+).+/$1/;
			
		push @content, [ @subcontent ];
    }
	
	return @content;
}

sub MyGetListText
{
	my $hwnd  = shift;
	my $index = shift;
	
	my $text;
	
	while ( !defined $text ) { 
		eval { $text = GetListText( $hwnd, $index) };
		die $! if $! && $! !~ /panic/;
		sleep(1) if $!;
	}
	
	return $text;
}

sub send_chatter {
	my $self   = shift;
	my $msg    = shift;
	
	return $self->send_long_chatter( 80, " ", $msg) 
		if  length($msg) > 80;
	
	my $hwnd   = (GetChildWindows( $self->bot->main_hwnd ))[79];
	my $ohwnd  = GetForegroundWindow();
	
	WMSetText( $hwnd, $msg );
	$self->bot->raise_event( 'debug', { bot => $self->bot, message => 'sending chatter' } ); my $i = 1;
	while ( WMGetText( $hwnd ) ) {
		$self->bot->raise_event( 'debug', { message => 'trying ' .$i++ } );
		SetForegroundWindow( $self->bot->main_hwnd );
		SetFocus( $hwnd ); SendKeys("{END}{ENTER}");
	}
	SetForegroundWindow( $ohwnd );
	
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
	
		my $i = rindex( $text, $char , $length );
			
		my $t = substr( $text, 0, $i);

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
	my $ohwnd  = GetForegroundWindow();
	
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
		
	return grep { /$idx/i } @$maps
		if $idx;
		
	return @$maps;
}

sub select_map {
	my $self   = shift;
	my $search = shift;
	
	my @candidates = $self->maps( $search );
	
	@candidates = grep { $_ eq $search } @candidates
		if @candidates > 1;
		
	return 0
		if @candidates > 1 || @candidates == 0;
	
	return $self->set_combo_value( 57, $candidates[0] );
}


sub select_type {
	my $self   = shift;
	my $type   = shift;
	
	return $self->set_combo_value( 55, $type, {
		b     => 'Battle',
		d     => 'Destruction',
		tb    => 'Team Battle',
		td    => 'Team Destruction',
		cb    => 'Custom Battle',
		ctb   => 'Custom Team Battle',
		'cmp' => 'Custom Mission Play',
		cu    => 'Custom Undefined',
	});
}

sub select_weather {
	my $self   = shift;
	my $type   = shift;
	
	$type = 'Off' if $type =~ /^off$/i || $type eq '0';
	$type = 'On'  if $type =~ /^on$/i  || $type eq '1';
	
	return $self->set_combo_value( 72, $type );
}


sub select_heat {
	my $self   = shift;
	my $type   = shift;
	
	$type = 'Off' if $type =~ /^off$/i || $type eq '0';
	$type = 'On'  if $type =~ /^on$/i  || $type eq '1';
	$self->set_checkbox_value( 'Heat Management', $type );
	return 1;
}



sub select_lock {
	my $self   = shift;
	my $type   = shift;
	
	my $hwnd   = (GetChildWindows( $self->bot->main_hwnd ))[53];
	
	$type = 0 if $type =~ /^off$/i || $type eq '0';
	$type = 1  if $type =~ /^on$/i  || $type eq '1';
	
	$self->set_checkbox_value( 'Lock Server', $type );
	
	return 1;
}

sub select_bots {
	my $self    = shift;
	my $type    = shift;

	my @windows = GetChildWindows( $self->bot->main_hwnd );
	
	my ( $command, @args  ) = split / +/, $type;
	
	if ( @args && $args[0] eq 'at'&& $command eq 'off' )
	{
		$command = 'offat'; shift @args;
	}
	
	if ( $command =~ /^\d+$/ && @args == 3 && grep { /^\d+$/ } @args == 3 )
	{
		$self->select_bots_at_start( 'on' );
		$self->select_bot_limit( 'limit', $command );
		$self->select_bot_level( 'level', $args[0], $args[1] );
		$self->select_bots_off_at( 'offat', $args[2] );
		return 1;
	}
	
	my %commands = (
		select_bots_at_start => /^(off|false|true|on)$/,
		select_bot_limit     => /^(limit)$/,
		select_bot_level     => /^(level)$/,
		select_bots_off_at   => /^(of *at)$/,
	);
	
	for ( keys %commands )
	{
		my $re = $commands{$_};
		return $self->$_( $command, @args )
			if $command =~ /$re/;
	}

	return;
}

sub select_bots_off_at
{
	my $self    = shift;
	my $command = shift;
	my @args    = @_;
	my @windows = GetChildWindows( $self->bot->main_hwnd );
		
	$self->set_checkbox_value( $windows[161], $args[0] ? 1 : 0  );
	WMSetText( $windows[162], $args[0] );
	return 1;
	
	return;
}
	
sub select_bots_at_start
{
	my $self    = shift;
	my $command = shift;
	my @args    = @_;
	my @windows = GetChildWindows( $self->bot->main_hwnd );
	
	# Fill Game with Bots at Launch
	$self->set_checkbox_value( $windows[155], 0 ), return 1
		if $command =~ /^(off|false|0)$/i;

	$self->set_checkbox_value( $windows[155], 1 ), return 1
		if $command =~ /^(true|on|1)$/i;
}

sub select_bot_limit
{
	my $self    = shift;
	my $command = shift;
	my @args    = @_;
	my @windows = GetChildWindows( $self->bot->main_hwnd );
	
	$self->set_checkbox_value( $windows[156], 0 ), return 1
		 if !$args[0];
	
	$self->set_checkbox_value( $windows[156], 0 ), return 1
		if $args[0] =~ /^(off|false|0)$/i;

	$self->set_checkbox_value( $windows[156], 1 ), return 1
		if $args[0] =~ /^(true|on|1)$/i;
		
	$self->set_checkbox_value( $windows[156], 1 );
	WMSetText( $windows[157], $args[0] );

	return 1;
}

sub select_bot_level
{
	my $self    = shift;
	my $command = shift;
	my @args    = @_;
	my @windows = GetChildWindows( $self->bot->main_hwnd );
		
	# Bot Level
	$self->set_checkbox_value( $windows[158], 0 ), return 1
		 if !$args[0];

	$self->set_checkbox_value( $windows[158], 0 ), return 1
		if $args[0] =~ /^(off|false|0)$/i;

	$self->set_checkbox_value( $windows[158], 1 ), return 1
		if $args[0] =~ /^(true|on|1)$/i;
		 

	$self->set_checkbox_value( $windows[158], 1 );
	WMSetText( $windows[159], $args[0] );
	WMSetText( $windows[160], $args[1] || $args[0] );
	return 1;
}
	
	
sub select_frag_limit
{
	my $self    = shift;

	my @args    = @_;
	my @windows = GetChildWindows( $self->bot->main_hwnd );
		
	$self->set_checkbox_value( 'Frag Limit', 0 ), 
	EnableWindow( $windows[64], 0 ),
	return 1
		 if !$args[0];

	$self->set_checkbox_value( 'Frag Limit', 0 ), 
	EnableWindow( $windows[64], 0 ),
	return 1
		if $args[0] =~ /^(off|false|0)$/i;

	$self->set_checkbox_value( 'Frag Limit', 1 ), 
	EnableWindow( $windows[64], 1 ),
	return 1
		if $args[0] =~ /^(true|on|1)$/i;
		 

	# $self->set_checkbox_value( $windows[63], 1 );
	$self->set_checkbox_value( 'Frag Limit', 1 );
	EnableWindow( $windows[64], 1 );
	WMSetText( $windows[64], $args[0] );
	return 1;
}


sub select_waves
{
	my $self    = shift;

	my @args    = @_;
	my @windows = GetChildWindows( $self->bot->main_hwnd );

	
	$self->set_checkbox_value( '# of Waves', 0 ),
	EnableWindow( $windows[67], 0 ),
	return 1
		 if !$args[0];

	$self->set_checkbox_value( '# of Waves', 0 ),
	EnableWindow( $windows[67], 0 ),
	return 1
		if $args[0] =~ /^(off|false|0)$/i;

	$self->set_checkbox_value( '# of Waves', 1 ), 
	EnableWindow( $windows[67], 1 ),
	return 1
		if $args[0] =~ /^(true|on|1)$/i;

	$self->set_checkbox_value( '# of Waves', 1 );
	EnableWindow( $windows[67], 1 );
	$self->set_combo_value(67, $args[0] );
	
	return 1;
}

sub select_daytime {
	my $self   = shift;
	my $type   = shift;
	
	$type = 'Day'   if $type =~ /^d(ay)?$/i;
	$type = 'Night' if $type =~ /^n(ight)?/i;
	
	return $self->set_combo_value( 73, $type );
}

sub select_time {
	my $self   = shift;
	my $type   = shift;

	$type = $1 if $type =~ /^(\d+)/;
	$type = 30 unless $type =~ /^\d+/;
	
	$type = (grep { $type <= $_ } qw( 1 2 5 10 15 30 60 90 120 ))[-1];
		
	return $self->set_combo_value( 74, $type );
}

sub select_tonnage {
	my $self   = shift;
	my $type   = shift;
	
	$type = $1 if $type =~ /^(\d+)/;
	$type = 20 unless $type =~ /^\d+/;
	$type = 20 if $type < 20;
	
	$type = (grep { $type >= $_ } qw( 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 ))[-1];
		
	return $self->set_combo_value( 76, "$type Tons" );
}

sub select_cbills {
	my $self   = shift;
	my $type   = shift;
	
	$type = $1 if $type =~ /^(\d+)/;
	$type = 2000000 unless $type =~ /^\d+/;
	$type = 2000000 if $type < 2000000;
	
	$type = (grep { $type >= $_ } map { $_ * 1000000 } ( 2 .. 35 ))[-1];
	
	return $self->set_combo_value( 174, $type );
}

sub select_stock {
	my $self   = shift;
	my $type   = shift;
	
	$type = 'Off' if $type =~ /^off$/i || $type eq '0';
	$type = 'On'  if $type =~ /^on$/i  || $type eq '1';
	
	return $self->set_combo_value( 75, $type );
}

sub select_radar {
	my $self   = shift;
	my $type   = shift;
	
	$type = 'Simple'    if $type =~ /^s(imple)?$/i;
	$type = 'Advanced'  if $type =~ /^a(dvanced)?$/i;
	$type = 'Team Only' if $type =~ /^t(eam)? *(only)?$/i;
	$type = 'No Radar'  if $type =~ /^(n(o)? *(radar)?|o(ff)?)$/i;
	
	return $self->set_combo_value( 77, $type );
}

sub select_visibility {
	my $self   = shift;
	my $type   = shift;

	$type = 'Default'   if $type =~ /^d(efault)?$/i;
	$type = 'Clear'     if $type =~ /^c(lear)?$/i;
	$type = 'Heavy Fog' if $type =~ /^h(eavy)? *(fog)?$/i;
	$type = 'Light Fog' if $type =~ /^l(ight)? *(fog)?$/i;
	
	return $self->set_combo_value( 59, $type );
}

sub in_game 
{
	my $self        = shift;
	my @windows     = GetChildWindows($self->bot->main_hwnd);
	my $WS_VISIBLE  = 0x10000000;
	my $ingame      = IsWindowStyle($windows[150], $WS_VISIBLE);
	
	return $ingame;
}

sub time 
{
	my $self    = shift;
	my @windows = GetChildWindows($self->bot->main_hwnd);
	my $text    = WMGetText( $windows[149] );
	
	return wantarray ? split( /:/, $text ) : $text;
}



1;









