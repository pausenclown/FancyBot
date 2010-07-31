package FancyBot::Commands;

use Moose::Role;
use Data::Dumper;

sub is_command
{
	my $self = shift;
	my $txt   = shift;

	($_) = $self->parse_command( $txt );
	return defined $_ ? 1 : 0;
}

sub parse_command
{
	my $self = shift;
	my $txt   = shift;
		
	$txt =~ s/^-list (maps|players|bots|types)/-list-$1/;
	$txt =~ s/^-bot add/-bot-add/;
	$txt =~ s/^-add bot/-bot-add/;
			
	if ( $txt =~ /^-([a-z-]+) ?(.*)/ )
	{
		return ($1, $2);
	}
	
	return;
}

sub command
{
	my $self = shift;
	my $args = shift;
	my $cmd  = $args->{command};
	
	my ( $stgs, $cfgs, $scfg);

	$stgs = [ grep { $self->config->{Server}->{PublicSettings}->{$_} eq $cmd } keys %{ $self->config->{Server}->{PublicSettings} } ];
	
	if ( scalar @$stgs )
	{
		$args->{params} = $stgs->[0] . ' ' . $args->{params};
		$cmd  = 'settings';
	}

	$cfgs = [ grep { $_->{Name} eq $cmd } @{ $self->config->{Commands}->{Command} } ];
	
	if ( scalar @$cfgs )
	{
		if ( scalar @$cfgs == 1 )
		{
			$self->instantiate_command_object( $cfgs->[0] )
				unless $cfgs->[0]->{CommandObject};
			
			return $cfgs->[0];
		}
		else
		{
			die "Error, duplicate command '$cmd' in config.";
		}
	}
	else
	{
		$self->send_chatter( "Error, unknown command '$cmd'." );
	}
	
	return;
}
			
sub instantiate_command_object
{
	my $self = shift;
	my $cfg  = shift;
	my $name = ucfirst( $cfg->{Name} );  $name =~ s/-(.)/uc($1)/ge; 
	my $mod  = "FancyBot::Commands::$name";
	my $code = "use $mod; \$cfg->{CommandObject} = $mod->new;";

	eval $code;

	$self->raise_event( 'notice', { bot => $self, message => "Error loading command ". $cfg->{Name}. ": $@" } ),
	$self->send_chatter( "Command '". $cfg->{Name}. "' doesn't exist or can't be loaded. May be not yet implemented.\n" ), return
		unless $cfg->{CommandObject};
		
	return $cfg->{CommandObject};
	
}

1;
