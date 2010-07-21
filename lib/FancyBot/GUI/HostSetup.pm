package FancyBot::GUI::HostSetup;

use Moose; 


use Win32::GuiTest qw( SetForegroundWindow PushChildButton WMSetText SelComboItemText GetChildWindows );
use FancyBot::GUI::Multiplayer;
use FancyBot::GUI::Lobby;

extends 'FancyBot::GUI';

has bot =>
	isa => 'FancyBot',
	is  => 'rw';
	
sub connection 
{
	my $self = shift;
	my $conn = shift;
	SelComboItemText( (GetChildWindows( $self->bot->main_hwnd ))[4], $conn );
}

sub update_gui
{
	my $self = shift;
	sleep(1);
	my @windows = GetChildWindows( $self->bot->main_hwnd );
	
	WMSetText( $windows[11], $self->bot->config->{'Server'}->{'Name'} );
	SelComboItemText( $windows[35], $self->bot->config->{'Server'}->{'Players'} );
	
	if ( $self->bot->config->{'Server'}->{'Password'} && ref $self->bot->config->{'Server'}->{'Password'} ne 'HASH' ) {
		$self->set_checkbox_value( $windows[12], 1 );
		WMSetText( $windows[13], $self->bot->config->{'Server'}->{'Password'} );
	}
	
	$self->set_checkbox_value( $windows[14], $self->bot->config->{'Server'}->{'AdvertiseGame'} );

	$self->set_checkbox_value( $windows[16], $self->bot->config->{'Server'}->{'AllowJoinInProgress'} );

	if ( $self->bot->config->{'Server'}->{'AllowJoinInProgress'} eq '1' || $self->bot->config->{'Server'}->{'AllowJoinInProgress'} =~ /true/i ) {

		if ( my $limit = $self->bot->config->{'Server'}->{'JoinTimeLimit'} || 'Unlimited' )
		{
			if ( $limit =~ /unlimited/i ) {
				$limit = 'Unlimited';
			}
			else
			{
				if ( $limit =~ /(45|30|15|10)/ ) {
					$limit = "$1 min.";
				}
				else
				{
					warn "Cannot parse JoinTimeLimit. Must be 30, 15, 10, 5 or 'Unlimited' is '$limit'\n";
				}
			}

			SelComboItemText( $windows[34], $limit );
		}
	}


	
	my $delay = $self->bot->config->{'Server'}->{'DelayBetweenMaps'} || '2';

	if ( $delay =~ /(10|5|2|1)/ ) {
		$delay = "$1 min.";
	}
	else
	{
		warn "Cannot parse DelayBetweenMaps. Must be 1, 2, 5  or 10\n";
	}

	SelComboItemText( $windows[36], $delay );


	my $radar = $self->bot->config->{'Server'}->{'DefaultRadarMode'} || 'Advanced';

	if ( $radar =~ /(simple|off|team|adv)/i ) {
		
		$radar = "Simple"    if $radar =~ /simple/i;
		$radar = "Advanced"  if $radar =~ /adv/i;
		$radar = "No Radar"  if $radar =~ /off/i;
		$radar = "Team Only" if $radar =~ /team/i;
	}
	else
	{
		warn "Cannot parse DefaultRadarMode. Must Simple, Team, Advanced or Off\n";
	}

	SelComboItemText( $windows[43], $radar );



	$self->set_checkbox_value( $windows[18], $self->bot->config->{'Server'}->{'AllowCustomDecals'} );
	$self->set_checkbox_value( $windows[24], $self->bot->config->{'Server'}->{'ForceFirstPersonView'} );
	$self->set_checkbox_value( $windows[25], $self->bot->config->{'Server'}->{'LimitedAmmunitions'} );
	$self->set_checkbox_value( $windows[26], $self->bot->config->{'Server'}->{'HeatManagement'} );
	$self->set_checkbox_value( $windows[27], $self->bot->config->{'Server'}->{'FriendlyFire'} );
	$self->set_checkbox_value( $windows[28], $self->bot->config->{'Server'}->{'SplashDamage'} );
	$self->set_checkbox_value( $windows[29], $self->bot->config->{'Server'}->{'ForceRespawn'} );
	$self->set_checkbox_value( $windows[30], $self->bot->config->{'Server'}->{'DeadMechsCantTalk'} );
	$self->set_checkbox_value( $windows[31], $self->bot->config->{'Server'}->{'DeadMechsCantSee'} );
	$self->set_checkbox_value( $windows[32], $self->bot->config->{'Server'}->{'RestrictMechs'} );
}

sub host
{
	my $self = shift;
	while ( !(GetChildWindows( $self->bot->main_hwnd ))[79] )
	{
		SetForegroundWindow( $self->bot->main_hwnd );
		PushChildButton( $self->bot->main_hwnd, 'HOST GAME' );
		sleep(5);
	}
	
	
	$self->bot->screen( FancyBot::GUI::Lobby->new( bot => $self->bot ) );
	$self->bot->update_gui;
}

sub back 
{
	my $self = shift;
	PushChildButton( $self->bot->main_hwnd, 'BACK' );
	$self->bot->screen( FancyBot::GUI::Multiplayer->new( bot => $self->bot ) );
	$self->bot->update_gui;
}

1;