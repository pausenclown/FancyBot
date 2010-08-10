package FancyBot::GUI::Lobby::Settings;

use Moose::Role;

sub select_weather {
	my $self   = shift;
	my $type   = shift;
	
	$type = 'Off' if $type =~ /^off$/i || $type eq '0';
	$type = 'On'  if $type =~ /^on$/i  || $type eq '1';
	
	return $self->get_control('tcmbWeather')->set_value( $type );
}




sub select_heat {
	my $self   = shift;
	my $type   = shift;
	
	return $self->get_control('tcbHeatManagement')->set_value( $type );
}


sub select_lock {
	my $self   = shift;
	my $type   = shift;
	
	return $self->get_control('tcbLockServer')->set_value( $type );
	
	return 1;
}


sub select_daytime {
	my $self   = shift;
	my $type   = shift;
	
	$type = 'Day'   if $type =~ /^d(ay)?$/i;
	$type = 'Night' if $type =~ /^n(ight)?/i;
	
	return $self->get_control('tcmbTimeOfDay')->set_value( $type );
}

sub select_random_daytime
{
	my $self  = shift;
	my $dtime = shift || '*';
	
	if ( $dtime eq "*" )
	{
		my $dtimes = [ 'Day', 'Night' ];
		$dtime = $dtimes->[ int(rand(scalar @$dtimes)) ];
	}
	elsif ( $dtime =~ /,/ )
	{
		my $dtimes = [ split /,/, $dtime ];
		$dtime = $dtimes->[ int(rand(scalar @$dtimes)) ];
	}
	
	return $self->select_daytime( $dtime );
}


sub select_time {
	my $self   = shift;
	my $type   = shift;

	$type = $1 if $type =~ /^(\d+)/;
	$type = 30 unless $type =~ /^\d+/;
	
	$type = (grep { $type <= $_ } qw( 1 2 5 10 15 30 60 90 120 ))[-1];
		
	return $self->get_control('tcmbTimeLimit')->set_value( $type );
}

sub select_tonnage {
	my $self   = shift;
	my $type   = shift;
	
	$type = $1 if $type =~ /^(\d+)/;
	$type = 20 unless $type =~ /^\d+/;
	$type = 20 if $type < 20;
	
	$type = (grep { $type >= $_ } qw( 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 ))[-1];
		
	return $self->get_control('tcmbMaxTonnage')->set_value( $type );
}

sub select_cbills {
	my $self   = shift;
	my $type   = shift;
	
	$type = $1 if $type =~ /^(\d+)/;
	$type = 2000000 unless $type =~ /^\d+/;
	$type = 2000000 if $type < 2000000;
	
	$type = (grep { $type >= $_ } map { $_ * 1000000 } ( 2 .. 35 ))[-1];
	
	return $self->get_control('tcmbMaxCBills')->set_value( $type );
}

sub select_stock {
	my $self   = shift;
	my $type   = shift;
	
	$type = 'Off' if $type =~ /^off$/i || $type eq '0';
	$type = 'On'  if $type =~ /^on$/i  || $type eq '1';
	
	return $self->get_control('tcmbStockMechs')->set_value( $type );
}


sub select_random_stock
{
	my $self  = shift;
	my $stock = shift || '*';
	
	if ( $stock eq "*" )
	{
		my $stocks = [ 'On', 'Off' ];
		$stock = $stocks->[ int(rand(scalar @$stocks)) ];
	}
	elsif ( $stock =~ /,/ )
	{
		my $stocks = [ split /,/, $stock ];
		$stock = $stocks->[ int(rand(scalar @$stocks)) ];
	}
	
	return $self->select_stock( $stock );
}

sub select_radar {
	my $self   = shift;
	my $type   = shift;
	
	$type = 'Simple'    if $type =~ /^s(imple)?$/i;
	$type = 'Advanced'  if $type =~ /^a(dvanced)?$/i;
	$type = 'Team Only' if $type =~ /^t(eam)? *(only)?$/i;
	$type = 'No Radar'  if $type =~ /^(n(o)? *(radar)?|o(ff)?)$/i;
	
	return $self->get_control('tcmbRadar')->set_value( $type );
}


sub select_random_radar
{
	my $self  = shift;
	my $radar = shift || '*';
	
	if ( $radar eq "*" )
	{
		my $radars = [ 'Advanced', 'Simple', 'Team Only', 'No Radar' ];
		$radar = $radars->[ int(rand(scalar @$radars)) ];
	}
	elsif ( $radar =~ /,/ )
	{
		my $radars = [ split /,/, $radar ];
		$radar = $radars->[ int(rand(scalar @$radars)) ];
	}
	
	return $self->select_radar( $radar );
}

sub select_visibility {
	my $self   = shift;
	my $type   = shift;

	$type = 'Default'   if $type =~ /^d(efault)?$/i;
	$type = 'Clear'     if $type =~ /^c(lear)?$/i;
	$type = 'Heavy Fog' if $type =~ /^h(eavy)? *(fog)?$/i;
	$type = 'Light Fog' if $type =~ /^l(ight)? *(fog)?$/i;

	return $self->get_control('tcmbVisibility')->set_value( $type );
}

sub select_random_visibility
{
	my $self  = shift;
	my $visibility = shift || '*';
	
	if ( $visibility eq "*" )
	{
		my $visibilitys = [ 'Default', 'Clear', 'Light Fog', 'Heavy Fog' ];
		$visibility = $visibilitys->[ int(rand(scalar @$visibilitys)) ];
	}
	elsif ( $visibility =~ /,/ )
	{
		my $visibilitys = [ split /,/, $visibility ];
		$visibility = $visibilitys->[ int(rand(scalar @$visibilitys)) ];
	}
	
	return $self->select_visibility( $visibility );
}

sub select_frag_limit
{
	my $self    = shift;
	my $type   = shift;
	
	my $txt = $self->get_control('txtFragLimit');
	my $cb  = $self->get_control('tcbFragLimit');

	$cb->set_value( 0 ), $txt->set_value( '1' ), $txt->disable, return 1
		 if !$type || $type =~ /^(off|false)$/i;

	$cb->set_value( 1 ), $txt->enable, return 1
		if $type =~ /^(true|on)$/i;
	
	$cb->set_value( 1 ), $txt->set_value( $type ), $txt->enable, return 1;
}


sub select_waves
{
	my $self  = shift;
	my $type  = shift;
	my $cb    = $self->get_control( 'tcbNumberOfWaves');
	my $cmb   = $self->get_control( 'tcmbNumberOfWaves');
	
	$cb->set_value( 0 ), $cmb->disable, return 1
		 if !$type || $type =~ /^(off|false|0)$/i;


	$cb->set_value( 1 ), $cmb->enable, return 1
		if $type =~ /^(true|on|1)$/i;

	
	$cb->set_value( 1 ), $cmb->enable, $cmb->set_value( $type ); return 1;
}


1;
