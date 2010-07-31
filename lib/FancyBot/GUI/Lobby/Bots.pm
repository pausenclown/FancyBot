package FancyBot::GUI::Lobby::Bots;

use Moose::Role;
use Data::Dumper;

sub select_bots {
	my $self    = shift;
	my $type    = shift;

	my @windows = FancyBot::GUI::GetChildWindows( $self->bot->main_hwnd );
	
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
	my @windows = FancyBot::GUI::GetChildWindows( $self->bot->main_hwnd );
		
	$self->set_checkbox_value( $windows[161], $args[0] ? 1 : 0  );
	FancyBot::GUI::WMSetText( $windows[162], $args[0] );
	return 1;
	
	return;
}
	
sub select_bots_at_start
{
	my $self    = shift;
	my $command = shift;
	my @args    = @_;
	my @windows = FancyBot::GUI::GetChildWindows( $self->bot->main_hwnd );
	
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
	my @windows = FancyBot::GUI::GetChildWindows( $self->bot->main_hwnd );
	
	$self->set_checkbox_value( $windows[156], 0 ), return 1
		 if !$args[0];
	
	$self->set_checkbox_value( $windows[156], 0 ), return 1
		if $args[0] =~ /^(off|false|0)$/i;

	$self->set_checkbox_value( $windows[156], 1 ), return 1
		if $args[0] =~ /^(true|on|1)$/i;
		
	$self->set_checkbox_value( $windows[156], 1 );
	FancyBot::GUI::WMSetText( $windows[157], $args[0] );

	return 1;
}

sub select_bot_level
{
	my $self    = shift;
	my $command = shift;
	my @args    = @_;
	my @windows = FancyBot::GUI::GetChildWindows( $self->bot->main_hwnd );
		
	# Bot Level
	$self->set_checkbox_value( $windows[158], 0 ), return 1
		 if !$args[0];

	$self->set_checkbox_value( $windows[158], 0 ), return 1
		if $args[0] =~ /^(off|false|0)$/i;

	$self->set_checkbox_value( $windows[158], 1 ), return 1
		if $args[0] =~ /^(true|on|1)$/i;
		 

	$self->set_checkbox_value( $windows[158], 1 );
	FancyBot::GUI::WMSetText( $windows[159], $args[0] );
	FancyBot::GUI::WMSetText( $windows[160], $args[1] || $args[0] );
	return 1;
}
	
	

sub add_pbot
{
	my ( $self, $pbot ) = @_;
	
	my @clans = @{ $self->bot->config->{Autobot}->{Teams}->{Team} };
	my @mechs = @{ $self->bot->config->{Autobot}->{AllowedMechs}->{Mech} };
	my @bots  = @{ $self->bot->config->{Autobot}->{Bots}->{Bot} };
	
	$pbot->{level} ||= int(rand(9))+1;

	if ( $pbot->{clan} && !$pbot->{name} )
	{
		my $clan = $self->clan( $pbot->{clan}, @clans );
		
		return unless $clan;
		
		my @members   = grep { $_->{Team} eq $clan->{Name} } @bots;
		my $member    = $members[ int(rand(scalar @members)) ];
		
		
		$pbot->{clan} = $clan;
		$pbot->{tag}  = $pbot->{clan} ? $pbot->{clan}->{Tag}. ' ' : '';
		$pbot->{name} = $pbot->{tag}. $member->{Name};
		$pbot->{mech} = $self->mech_for( $member ); 
	}
	elsif( !$pbot->{clan} && $pbot->{name} )
	{
		my $n = quotemeta( $pbot->{name} );
		
		my ($b) = grep { $_->{Name} =~ /$n/ } @bots;
		
		if ( $b )
		{
			$pbot->{clan}  = $self->clan( $b->{Team}, @clans );
			$pbot->{tag}   = $pbot->{clan} ? $pbot->{clan}->{Tag}. ' ' : '';
			$pbot->{name}  = $b->{Name};
			$pbot->{level} = $b->{Level};
			$pbot->{mech}  = $self->mech_for( $b ); 
		}
	}
	
	$self->get_control('txtGameBotName')->set_value( $pbot->{name} );
	$self->get_control('txtBotLevel')->set_value( $pbot->{level} );
	$self->get_control('cmbVariant')->set_value( $pbot->{mech}->{Name} );
	$self->get_control('cmbBotTeam')->set_value( $pbot->{team} )
		if $pbot->{team};
	
	$self->get_control('btnAddBot')->push;
	
	$self->bot->user( $pbot );
	
	$self->select_mech_and_Variant( $pbot->{name}, $pbot->{mech}->{Name}, $pbot->{mech}->{Variant} );
}

sub select_mech_and_Variant
{
	my $self    = shift;
	my $player  = shift;
	my $mech    = shift;
	my $variant = shift;

	my $user = $self->bot->user( $player );
	my $pos  = sprintf( "%02d", $user->position );
	print "btnSelectMech$pos", "!!\n";
	my $btn = $self->get_control("btnSelectMech$pos");
	
	FancyBot::GUI::WMSetText( $btn->hwnd, "M$pos");
	FancyBot::GUI::PushChildButton( $self->bot->main_hwnd, 'M$pos' );
	FancyBot::GUI::SendKeys( "W{RIGHT}{DOWN}{DOWN}{ENTER}" );
}

sub mech_for
{
	my $self   = shift;
	my $member = shift;
	my @mechs  = @{ $self->bot->config->{Autobot}->{AllowedMechs}->{Mech} };
		
	my @variants  = ref $member->{Variant} eq "ARRAY" ? @{ $member->{Variant} } : ( $member->{Variant} );
	
	my @ok;

	for ( @variants )
	{	
		my ($name, $build) = split /:/;
		
		if ( grep { $_->{Name} eq $name } @mechs )
		{
			push @ok, [$name, $build];
		}
	}
	

	my $mech;
	
	if ( @ok )
	{
		my $random = $ok[ int(rand(scalar @ok)) ];
		$mech = $self->find_mech( $random->[0] );
		$mech->{Variant} = $random->[1]
	}
	else
	{
		$mech = $self->find_mech( $ok[ int(rand(scalar @mechs)) ] );
	}
	
	return $mech;
}

sub find_mech
{
	my ($self, $name) = @_;
	for my $mech ( @{ $self->bot->config->{Comstar}->{Mech} } )
	{
		if ( $mech->{Name} eq $name )
		{
			return $mech;
		}
	}
	
	return;
}

sub assign_mech_for {
	my $self     = shift;
	my $player   = shift;
	my $mech     = shift;
		
	push @{ $self->bot->pending_mech_assignments }, [ $player, $mech ];

	return 1;
}

sub assign_team_for {
	my $self     = shift;
	my $player   = shift;
	my $team     = shift;
		
	push @{ $self->bot->pending_team_assignments }, [ $player, $team ];

	return 1;
}

sub select_mech_for {
	my $self     = shift;
	my $player   = shift;
	my $mech     = shift;
		
	print "SMF $player, $mech\n";

	return 1;
}

sub select_team_for {
	my $self     = shift;
	my $player   = shift;
	my $team     = shift;
		
	print "STF $player, $team\n";

	return 1;
}


1;