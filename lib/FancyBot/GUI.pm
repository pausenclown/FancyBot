package FancyBot::GUI;

use Moose;
use Data::Dumper;		
use Win32::GuiTest qw( :ALL );

use FancyBot::GUI::Multiplayer;
use FancyBot::GUI::Controls::CheckBox;
use FancyBot::GUI::Controls::TrickyCheckBox;
use FancyBot::GUI::Controls::ComboBox;
use FancyBot::GUI::Controls::TrickyComboBox;
use FancyBot::GUI::Controls::TextBox;
use FancyBot::GUI::Controls::Button;
use FancyBot::GUI::Controls::TrickyButton;
use FancyBot::GUI::Controls::ChatBox;
use FancyBot::GUI::Controls::MapBox;

has bot =>
	isa => 'FancyBot',
	is  => 'rw';

has control_map => 
	is    => 'ro',
	isa   => 'HashRef',
	default => sub {{
		cbRestrictMechsAndComponents => 32,  cmbConnection                => 4,   txtTime                      => 149, 
		txtServerName                => 11,  cbPassword                   => 12,  txtPassword                  => 13,
		cbAdvertiseThisGame          => 14,  cbReportGameStats            => 15,  cbAllowJoinInProgress        => 16,
		cmbJoinTimeLimit             => 34,  cbAllowCustomDecals          => 18,  cbServerRecycle              => 19,
		cbDelayBetweenMaps           => 20,	 cmbDelayBetweenMaps          => 36,  cbUseMapCycleList            => 21,
		cbAllowCustomSkins           => 22,  cbForceFirstPersonView       => 24,  cbLimitedAmmunitions         => 25,
		cbHeatManagement             => 26,  cbFriendlyFire               => 27,  cbSplashDamage               => 28,
		cbForceRespawn               => 29,  cbDeadMechsCantTalk          => 30,  cbDeadMechsCantSee           => 31, 
		ctbChat                      => 79,  cmbMaxNumberOfPlayers        => 35,  cbLeaveSlotForHuman          => 37,  
		cmbRadarMode                 => 43,	 tcbLockServer                => 53,  txtMaximumBotLevel           => 160,
		tcmbGameTypes                => 55,	 mpbMaps                      => 57,  tcmbVisibility               => 59,
		txtFragLimit                 => 64,	 tcbNumberOfWaves             => 65,  tcmbNumberOfWaves            => 66,
		tcmbWeather                  => 72,	 tcmbTimeOfDay                => 73,  tcmbTimeLimit                => 74,
		tcmbStockMechs               => 75,  tcmbMaxTonnage               => 76,  tcmbRadar                    => 77,
		txtGameBotName               => 115, txtBotLevel                  => 116, cmbVariant                   => 117,
		cmbBotTeam                   => 118, cbFillGameWithBots           => 155, cbBotLimit                   => 156, 
		txtBotLimit                  => 157, cbBotLevel                   => 158, txtMinimumBotLevel           => 159,
		cbBotsOffAt                  => 161, txtBotsOffAt                 => 162, txtChat                      => 172,
		tcmbMaxCBills                => 174, tcbFragLimit                 => 63,  txtTimeRemaining             => 150,
		txtCountdown                 => 149, lstOverwiew                  => 80,
		
		btnQuit                      => [2, 'QUIT'],		btnHost                      => [8, 'HOST'],
		btnBack                      => [52, 'BACK'],       btnEditRestrictions          => [33, 'EDIT RESTRICTIONS'],
		btnNext                      => [1, 'NEXT'],        btnNFMEditor                 => [39, 'NFM EDITOR'],
		btnLaunch                    => [45, 'LAUNCH'],     btnMekMatchServers           => [40, 'MEKMATCH SERVERS'],           
		btnStop                      => [46, 'STOP'],		btnAddBot                    => [171, 'ADD BOT'],
		btnKillServer                => [48, 'NEXT'],       btnKick                      => [119, 'KICK'],
		btnBan                       => [163, 'BAN'],       
		btnSelectMech01   => [83, ''],  btnSelectTeam01   => [120, ''],
		btnSelectMech02   => [84, ''],  btnSelectTeam02   => [121, ''],
		btnSelectMech03   => [85, ''],  btnSelectTeam03   => [122, ''],
		btnSelectMech04   => [86, ''],  btnSelectTeam04   => [123, ''],
		btnSelectMech05   => [87, ''],  btnSelectTeam05   => [124, ''],
		btnSelectMech06   => [88, ''],  btnSelectTeam06   => [125, ''],
		btnSelectMech07   => [89, ''],  btnSelectTeam07   => [126, ''],
		btnSelectMech08   => [90, ''],  btnSelectTeam08   => [127, ''],
		btnSelectMech09   => [91, ''],  btnSelectTeam09   => [128, ''],
		btnSelectMech10   => [92, ''],  btnSelectTeam10   => [129, ''],
		btnSelectMech11   => [93, ''],  btnSelectTeam11   => [130, ''],
		btnSelectMech12   => [94, ''],  btnSelectTeam12   => [131, ''],
		btnSelectMech13   => [95, ''],  btnSelectTeam13   => [132, ''],
		btnSelectMech14   => [96, ''],  btnSelectTeam14   => [133, ''],
		btnSelectMech15   => [97, ''],  btnSelectTeam15   => [134, ''],
		btnSelectMech16   => [98, ''],  btnSelectTeam16   => [135, ''],
		btnSelectMech17   => [99, ''],  btnSelectTeam17   => [136, ''],
		btnSelectMech18   => [100, ''], btnSelectTeam18   => [137, ''],
		btnSelectMech19   => [101, ''], btnSelectTeam19   => [138, ''],
		btnSelectMech20   => [102, ''], btnSelectTeam20   => [139, ''],
		btnSelectMech21   => [103, ''], btnSelectTeam21   => [140, ''],
		btnSelectMech22   => [104, ''], btnSelectTeam22   => [141, ''],
		btnSelectMech23   => [105, ''], btnSelectTeam23   => [142, ''],
		btnSelectMech24   => [106, ''], btnSelectTeam24   => [143, ''],
	}};

		#( map { "btnSelectMech$_" => $_ } ( 1, 2, 3 ) ),
		#( map { "btnSelectTeam$_" => $_ } ( 1, 2, 3 ) ),
has controls => 
	is      => 'ro',
	isa     => 'HashRef',
	default => sub {{
	}};
	
has window_handles =>
	is      => 'rw',
	isa     => 'ArrayRef',
	default => sub {[
	]};
	

sub start_screen
{
	my $self = shift;
	my $scr  = FancyBot::GUI::Multiplayer->new( bot => $self->bot );
	$scr->update_gui;
	
	return $scr;
}

sub get_window_handles
{
	my $self = shift;
	
	$self->window_handles( [ GetChildWindows($self->bot->main_hwnd) ] )
		if scalar @{ $self->window_handles } < 180;

	return $self->window_handles;
}

sub get_window_handle
{
	my $self   = shift;
	my $control = shift;
	my $index   = ref $self->control_map->{ $control } ? $self->control_map->{ $control }->[0] : $self->control_map->{ $control };
	# print "CI $index\n";
	my $hwnds = $self->get_window_handles;
	
	return $hwnds->[ $index ] if $index;
}

sub get_window_caption
{
	my $self   = shift;
	my $control = shift;

	return $self->control_map->{ $control } ? $self->control_map->{ $control }->[1] : '';
}

sub get_control
{
	my $self   = shift;
	my $control = shift;
	# print "GC $control\n";
	$control = $self->controls->{ $control } || $self->create_control( $control );
	
	return $control;
}

sub create_control
{
	my $self   = shift;
	my $control = shift;
	my $args    = shift;
	
	# print "CC $control\n";
	my $hwnd = $self->get_window_handle( $control );
	# print "CH $hwnd\n";
	
	die "Unknown control '$control'.\n" unless $hwnd;
	
	if ( $control =~ /^txt/ )
	{
		return $self->controls->{ $control } = FancyBot::GUI::Controls::TextBox->new( name => $control, hwnd => $hwnd,  );
	}
	if ( $control =~ /^cmb/ )
	{
		return $self->controls->{ $control } = FancyBot::GUI::Controls::ComboBox->new( name => $control, hwnd => $hwnd );
	}
	if ( $control =~ /^tcmb/ )
	{
		return $self->controls->{ $control } = FancyBot::GUI::Controls::TrickyComboBox->new( name => $control, hwnd => $hwnd );
	}
	if ( $control =~ /^cb/ )
	{
		return $self->controls->{ $control } = FancyBot::GUI::Controls::CheckBox->new( name => $control, hwnd => $hwnd );
	}
	if ( $control =~ /^tcb/ )
	{
		return $self->controls->{ $control } = FancyBot::GUI::Controls::TrickyCheckBox->new( name => $control, hwnd => $hwnd );
	}
	if ( $control =~ /^btn/ )
	{
		return $self->controls->{ $control } = FancyBot::GUI::Controls::Button->new( name => $control, hwnd => $hwnd, caption => $self->get_window_caption( $control ) );
	}
	if ( $control =~ /^tbtn/ )
	{
		return $self->controls->{ $control } = FancyBot::GUI::Controls::TrickyButton->new( name => $control, hwnd => $hwnd, caption => $self->get_window_caption( $control ) );
	}

	if ( $control =~ /^ctb/ )
	{
		return $self->controls->{ $control } = FancyBot::GUI::Controls::ChatBox->new( name => $control, hwnd => $hwnd );
	}
	if ( $control =~ /^mpb/ )
	{
		return $self->controls->{ $control } = FancyBot::GUI::Controls::MapBox->new( name => $control, hwnd => $hwnd );
	}
		
	die "Unknown control Type '$control'\n";
}


1;
__DATA__


78 6226838 ! Off==ComboBox
79 6226838 ! ==Edit
80 6226838 ! ==ListBox
81 6226838 ! Team==Static
82 6226838 ! Status==Static
107 6226838 ! ==ComboBox
108 6226838 ! Team:==Static
109 6226838 ! ==ComboBox
110 6226838 ! ==ComboBox
111 6226838 ! Minimum:==Static
112 6226838 ! Maximum:==Static
113 6226838 ! Players:==Static
114 6226838 ! 0/16==Static
120 6226838 ! ...==Button
121 6226838 ! ...==Button
122 6226838 ! ...==Button
123 6226838 ! ...==Button
124 6226838 ! ...==Button
125 6226838 ! ...==Button
126 6226838 ! ...==Button
127 6226838 ! ...==Button
128 6226838 ! ...==Button
129 6226838 ! ...==Button
130 6226838 ! ...==Button
131 6226838 ! ...==Button
132 6226838 ! ...==Button
133 6226838 ! ...==Button
134 6226838 ! ...==Button
135 6226838 ! ...==Button
136 6226838 ! ...==Button
137 6226838 ! ...==Button
138 6226838 ! ...==Button
139 6226838 ! ...==Button
140 6226838 ! ...==Button
141 6226838 ! ...==Button
142 6226838 ! ...==Button
143 6226838 ! ...==Button
144 6226838 ! 'Mech==Static
145 6226838 ! Team==Static
146 6226838 ! NFM Editor==Button
147 6226838 ! Maximum Total:==Static
148 6226838 ! ==ComboBox


173 cmbMaxCBills==Static
174 6226838 ! 35000000==ComboBox
175 6226838 ! Tonnage:==Static
176 6226838 ! C-Bills:==Static
177 6226838 ! ==ComboBox
178 6226838 ! ==ComboBox
179 6226838 ! 179==Edit
180 6226838 ! C-Bills==Static
181 6226838 ! Team Ranges==Button
------------------------------------------------------------
[DEBUG] Event raised: chatter HASH(0x189c58c)