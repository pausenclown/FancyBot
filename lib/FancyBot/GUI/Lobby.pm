package FancyBot::GUI::Lobby;

use Moose;

extends 'FancyBot::GUI';

with 'FancyBot::GUI::Lobby::Chat';
with 'FancyBot::GUI::Lobby::Maps';
with 'FancyBot::GUI::Lobby::Bots';
with 'FancyBot::GUI::Lobby::Types';
with 'FancyBot::GUI::Lobby::Settings';
with 'FancyBot::GUI::Lobby::KickBan';

use FancyBot::GUI::Watcher;

has _maps => 
	isa     => 'HashRef',
	is      => 'ro',
	default => sub {{
		
	}};
	
sub update_gui
{
	my $self = shift;

	my @windows = FancyBot::GUI::GetChildWindows( $self->bot->main_hwnd );
	
	for ( my $i = 0; $i<24; $i++ )
	{
		my $hm = $windows[83+$i];
		my $ht = $windows[120+$i];
		my $ps = sprintf( "%02d", $i+1);
				
		FancyBot::GUI::WMSetText( $hm, "M$ps" );
		FancyBot::GUI::WMSetText( $ht, "T$ps" );
	}

	FancyBot::GUI::Watcher::start( (FancyBot::GUI::GetChildWindows( $self->bot->main_hwnd ))[80] );
}

sub player_info
{
	my $self = shift;
	return FancyBot::GUI::Watcher::player_info( (FancyBot::GUI::GetChildWindows( $self->bot->main_hwnd ))[80] );
}

sub iplayer_info
{
	my $self = shift;
	return FancyBot::GUI::Watcher::iplayer_info( (FancyBot::GUI::GetChildWindows( $self->bot->main_hwnd ))[80] );
}

sub launch {
	my $self   = shift;
	my $ohwnd  = FancyBot::GUI::GetForegroundWindow();
	FancyBot::GUI::PushChildButton( $self->bot->main_hwnd, 'LAUNCH' );
	FancyBot::GUI::SetForegroundWindow( $ohwnd );
}

sub stop_map {
	my $self   = shift;
	my $ohwnd  = FancyBot::GUI::GetForegroundWindow();
	FancyBot::GUI::PushChildButton( $self->bot->main_hwnd, 'STOP' );
	FancyBot::GUI::SetForegroundWindow( $ohwnd );
}

sub in_game 
{
	my $self        = shift;
	return $self->get_control( 'txtTimeRemaining' )->is_visible;
}

sub time 
{
	my $self    = shift;
	my $text    = $self->get_control( 'txtCountdown' )->get_value;
	return wantarray ? split( /:/, $text ) : $text;
}



sub clan
{
	my $self   = shift;
	my $search = shift;
	my @clans  = @_;
	
	for my $clan ( @clans )
	{
		my $n = $clan->{Name};
		my $m = quotemeta($clan->{Tag});
		my $s = $clan->{Tag}; $s =~ s/[^A-Z]+//gi;

		return $clan 
			if lc($search) eq lc($n) || $search =~ /^$m/i || $search =~ /\b$s\b/i;
	}
	
	return;
}

sub tag
{
	my $self   = shift;
	my $search = shift;
	my @clans  = @_;
	
	for my $clan ( @clans )
	{
		my $n = $clan->{Name};
		my $m = quotemeta($clan->{Tag});
		my $s = $clan->{Tag}; # $s =~ s/[^A-Z]+//gi;

		return $s 
			if lc($search) eq lc($n) || $search =~ /^$m/i || $search =~ /\b$s\b/i;
	}
	
	return;
}
sub clan_members
{
	my $self = shift;
	my $clan = shift;
	my @bots = @_;
	
	my @members;
	
	for my $bot ( @bots )
	{
		my $n = $bot->{Name};
		my $m = $bot->{Match};
		my $s = $bot->{Match}; $s = s/[^A-Z]+//gi;
		
		push @members, $bot 
			if $bot->{Team} eq $n || $bot->{Team} =~ /\b($m|$s)\b/;
	}
	
	return @members;
}

sub teamplay_selected
{
	return +shift->game_type !~ /^(Custom )?(Destruction|Battle)$/;
}

1;









