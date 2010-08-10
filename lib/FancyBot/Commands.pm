package FancyBot::Commands;

use Moose::Role;
use Data::Dumper;
use Text::Balanced qw( extract_delimited );


sub process_command
{
	my $self = shift;
	my $txt  = shift;
	my $user = shift;

	my ( $command, $params, $pparams ) = $self->parse_command( $txt );

	$self->raise_event( 'command', { 
		bot => $self, 
		command => $command, 
		user => $user, 
		params => $params, 
		params_array => $pparams 
	} );
}

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

	$txt = $self->replace_aliases( $txt );
			
	if ( $txt =~ /^-([a-z-]+) ?(.*)/ )
	{
		my ( $command, $args, $argsa, @args ) = ( $1, $2, $2 );
		
		while ( $argsa )
		{
			if ( my $sextracted = extract_delimited( $argsa, "'" ) )
			{
				push @args, substr($sextracted,1,length($sextracted)-2);
			}
			elsif ( my $dextracted = extract_delimited( $argsa, '"' ) )
			{
				push @args, substr($dextracted,1,length($dextracted)-2);
			}
			elsif ( $argsa =~ s/([^ ]+) // )
			{
				push @args, $1;
			}
			else
			{
				push @args, $argsa; $argsa = '';
			}
		}
		
		return ( $command, $args, \@args );
	}
	
	return;
}

sub replace_aliases
{
	my $self = shift;
	my $txt  = shift;
	
	my %aliases;
	
	for my $command ( @{ $self->config->{Commands}->{Command} } )
	{
		if ( $command->{Alias} )
		{
			my @aliases = ref $command->{Alias} ? @{ $command->{Alias} }  : ( $command->{Alias} );
			
			for ( @aliases )
			{
				$aliases{ $_ } = $command->{Name};
			}
		}
	}
	
	my $re_alias = '^-('. join( '|', keys %aliases ). ')';
	
	$txt =~ s/$re_alias/-$aliases{$1}/g;

	return $txt;
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
