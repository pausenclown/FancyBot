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
	
	# print Dumper( "NB1 ", $pbot );
	
	my @clans = @{ $self->bot->config->{Autobot}->{Teams}->{Team} };
	my @mechs = @{ $self->bot->config->{Autobot}->{AllowedMechs}->{Mech} };
	my @bots  = @{ $self->bot->config->{Autobot}->{Bots}->{Bot} };
	
	$pbot->{level} ||= int(rand(9))+1;
		
	
	if ( $pbot->{clan} && !$pbot->{name} )
	{
		my $clan = $self->clan( $pbot->{clan}, @clans );
		return unless $clan;
		
		my @members   = grep { $_->{Team} eq $clan->{Name} } @bots;
		
		my $member; for ( @members )
		{
			$member = $_, last
				if !$self->bot->users->{ $clan->{Tag}. ' '. $_->{Name} };
		};
		
		$pbot->{clan} = $clan->{Name};
		$pbot->{tag}  = $clan->{Tag};
		$pbot->{name} = $clan->{Tag}. ' '. $member->{Name};
		$pbot->{mech} = $self->mech_for( $member, $pbot->{mech}, $pbot->{build} )
			unless $pbot->{mech}; 
	}
	elsif( !$pbot->{clan} && $pbot->{name} )
	{
		my $n = quotemeta( $pbot->{name} );
		
		my ($b) = grep { $_->{Name} =~ /$n/ } @bots;
		
		if ( $b )
		{
			my ($clan)     = grep { $_->{Name} eq $b->{Team} } @clans;
			$pbot->{clan}  = $clan->{Name};
			$pbot->{tag}   = $clan->{Tag} || '';
			$pbot->{name}  = $clan->{Tag}. ' '. $b->{Name};
			$pbot->{level} = $b->{Level};
			
			$pbot->{mech}  = $self->mech_for( $b, $pbot->{mech}, $pbot->{build} );
		}
		else
		{
			$pbot->{mech} = $self->mech_for( $pbot->{name}, $pbot->{mech}, $pbot->{build} ); 
		}
	}
	
	$pbot->{position} = scalar keys %{ $self->bot->users };
	
	$self->get_control('txtGameBotName')->set_value( $pbot->{name} );
	$self->get_control('txtBotLevel')->set_value( $pbot->{level} );
	$self->get_control('cmbVariant')->set_value( $pbot->{mech}->{Name} );
	$self->get_control('cmbBotTeam')->set_value( $pbot->{team} )
		if $pbot->{team};
	
	$self->get_control('btnAddBot')->push;
	
	$self->bot->connect_user( $pbot );
	
	$self->assign_mech_for( $pbot->{name}, $pbot->{mech}->{Name}, $pbot->{mech}->{Variant} )
		if $pbot->{mech}->{Variant};
}

sub mech_for
{
	my $self     = shift;
	my $member   = shift;
	my $mechname = shift;
	my $build    = shift;
	my @mechs    = @{ $self->bot->config->{Autobot}->{AllowedMechs}->{Mech} };
	
	my @ok;	
	# print Dumper ( $member, $mechname, $build );
	print "[DEBUG] Mech for ". (ref $member ? $member->{Name} : $member). "...\n";
	if ( $member && ref $member && !$mechname )
	{
		print "[DEBUG] kown bot.\n";
		my @variants  = ref $member->{Variant} eq "ARRAY" ? @{ $member->{Variant} } : ( $member->{Variant} );

		print "[DEBUG]", scalar @variants, " mechs preconfigured.\n";
		for ( @variants )
		{	
			my ($name, $build) = split /:/;


			if ( grep { $_->{Name} eq $name } @mechs )
			{
				push @ok, [$name, $build];
			}
			
			if ( @ok )
			{
				print "[DEBUG]", scalar @variants, " mechs ok.\n";
				my $random = $ok[ int(rand(scalar @ok)) ];
				my $mech = $self->find_mech( $random->[0] );
				$mech->{Variant} = $random->[1];
				print "[DEBUG] Selecting random variant ", $mech->{Variant}, "\n";
				return $mech;
			}

		}
	}

	my $mech;
		
	if ( $mechname )
	{
		print "[DEBUG] Selecting by mechname.\n";
		$mech = $self->find_mech( $mechname );
		my $builds = $self->sorted_builds_for( $mech->{Name} );
		$mech->{Variant} = $build || $builds->[ int(rand(scalar @$builds)) ];
	}
	else
	{
		print "[DEBUG] Selecting random mech.\n";
		$mech = $self->find_mech( $mechs[ int(rand(scalar @mechs)) ]->{Name} );
		my $builds = $self->sorted_builds_for( $mech->{Name} );
		$mech->{Variant} = $builds->[ int(rand(scalar @$builds)) ];
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
	my $build    = shift;
	print "[DEBUG] Assign $mech:$build to $player\n";
	push @{ $self->bot->pending_mech_assignments }, [ $player, $mech, $build ];

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
	my $mech     = shift; # $mech = $mech->{Name} if ref $mech;
	my $build    = shift;
	my $mechfc   = $mech ? substr($mech, 0, 1) : '.';
	my $user     = $self->bot->user( $player );
	my $pos      = sprintf( "%02d", $user->position  );
	
	my $button = $self->get_control( "btnSelectMech$pos" );
	$button->push;
	
	# determine how often we need to press the mechs name first char to find it
	my $mechs  = [ grep { /^$mechfc/ } map { ($_->{NamePrefix}||'') . $_->{Name} } @{ $self->sorted_mechs } ];
	my $builds = $self->sorted_builds_for( $mech );
		
	my $i; 
	
	if ( !$mech || $mech eq "*" )
	{
		$i = int(rand(scalar @$mechs));
	}
	else
	{
		$i = 0; for ( @$mechs )
		{
			last if $mech eq $_;
			$i++;
		}	
	
		$i ++;
		
		# take care of camera ship
		$i ++ if $mechfc eq "C";
	}
	
	
	my $j = 0;

	if ( !$build || $build eq "*" )
	{
		$j = int(rand(scalar @$builds));
	}
	else
	{
		for ( @$builds )
		{
			last if $build eq $_;
			$j++;
		}
	}
	
	# print Dumper( $builds, $j );
	
	my $keys = ( $mechfc x $i )."{RIGHT}".( "{DOWN}" x $j )."{ENTER}";
	print "[DEBUG] btnSelectMech$pos: $keys ( $mech, $build )\n" ;
	FancyBot::GUI::SendKeys( $keys );

	return 1;
}

sub sorted_mechs
{
	my $self = shift;

	my $all = $self->bot->config->{Comstar}->{Mech};
	my $mechs = [ sort { $a->{Name} cmp $b->{Name} } grep { !$_->{NamePrefix}       } @$all ];
	my $elems = [ sort { $a->{Name} cmp $b->{Name} } grep { $_->{NamePrefix} && $_->{NamePrefix} eq '-' } @$all ];
	my $infnt = [ sort { $a->{Name} cmp $b->{Name} } grep { $_->{NamePrefix} && $_->{NamePrefix} eq '~' } @$all ];
	return [ @$elems, @$mechs, @$infnt ];
}

sub sorted_builds_for
{
	my $self = shift;
	my $mech = shift;
	my @files;
	
	opendir DIR, $self->bot->config->{Server}->{PathToMercs}. '\RESOURCE\VariantsMTMP3' 
		or die "Could not read config directory.\n";
		
	while ( my $dir = readdir( DIR ) )
	{
		push @files, $1 if $dir =~ /^$mech ([^~].+)\.mw4$/;
	}
	
	@files = sort { $a cmp $b } @files;
	unshift @files, 'Stock';
	push @files, "~ Stock $mech";

	return \@files;
}

sub select_team_for {
	my $self     = shift;
	my $player   = shift;
	my $team     = shift;
	my $user     = $self->bot->user( $player );
	my $pos      = sprintf( "%02d", $user->position + 1 );

	my $button = $self->get_control( "btnSelectTeam$pos" );
	$button->push;
	FancyBot::GUI::SendKeys("${team}{ENTER}{ENTER}");

	return 1;
}


1;