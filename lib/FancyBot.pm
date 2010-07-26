package FancyBot;

use warnings;
use strict;

use FancyBot::GUI;
use FancyBot::User;
use FancyBot::Mech;
use Text::Diff;

use Moose;
use Config::Simple;
use Data::Dumper;
use XML::Simple;
use Win32;
use Win32::Process;
use Win32::GuiTest qw( WMGetText FindWindowLike GetChildWindows GetComboContents SelComboItemText GetClassName);

our $VERSION = 0.02;

has is_updating_player_info =>
	isa     => 'Bool',
	is      => 'rw';

has player_info_dirty =>
	isa     => 'Bool',
	is      => 'rw',
	default => 1;

# holds a reference to an object that represent the current screen of
# the dedicated server process
has screen =>
	isa     => 'FancyBot::GUI',
	is      => 'rw';

# config data as per server.ini
has config =>
	isa     => 'HashRef',
	is      => 'ro',
	default => sub {{}};

# user data
has users =>
	isa     => 'HashRef',
	is      => 'ro',
	default => sub {{}};
	
# holds a reference to an Hash of Arrays; The keys being event names, the 
# latter holding references to listening subroutines
has listeners =>
	isa     => 'HashRef',
	is      => 'ro',
	default => sub {{}};
	

has plugin_stash =>
	isa     => 'HashRef',
	is      => 'ro',
	default => sub {{}};

# the numeric window handle of the main window
# the dedicated server process
has main_hwnd => 
	isa     => 'Int',
	is      => 'rw',
	default => 0;
	
# time of server start
has server_start_time => 
	isa     => 'Int',
	is      => 'rw',
	default => 0;

# Perl Object, representing the dedicated server process
has server_proc => 
	isa     => 'Win32::Process',
	is      => 'rw';

# flag to control the main runloop
has keep_running =>
	isa     => 'Bool',
	is      => 'rw',
	default => 1;

# flag to control the main runloop
has in_game => 
	isa     => 'Bool',
	is      => 'rw',
	default => 0;
	
has last_chatter => 
	isa     => 'Str',
	is      => 'rw',
	default => '';

# Find the handle of the main Dedicated Server window and return it	
sub find_main_hwnd
{
	return (FindWindowLike(0, 'MechWarrior 4 Mercenaries Win32Dedicated Server'))[0];
}

# Returns wether a Dedicated Server is running or not
sub is_server_alive
{
	my $self = shift;
	return $self->find_main_hwnd ? 1 : 0;
}

sub local_hello
{
	my $self = shift;
	print <<"HELLO"
Welcome to the FancyBot version $VERSION.
Hit Ctrl-C to exit.
HELLO
}

sub start_server
{
	my $self        = shift;
	my $keep_config = shift;
	
	# error when server is alive
	die "Server already running.\n"
		if $self->is_server_alive;
		
	# read configuration file
	$self->{config} = XMLin( 'conf/FancyBot.xml' )
		unless keys %{$self->{config}};
	
	# load plugins as configured
	$self->load_plugins;
	
	$self->raise_event( 'notice', { message =>  "Starting Dedicated Server..." } );
	$self->raise_event( 'starting_server', { bot =>  $self } );

	# create a process object for the server
	my $process;
	my $mercs_path = $self->config->{'Server'}->{'PathToMercs'} || '.';
	my $mw4exe     = "$mercs_path\\MW4Mercs.exe";
	
    Win32::Process::Create( $process, $mw4exe, ' -win32dedicated', 0, NORMAL_PRIORITY_CLASS, $mercs_path )
		|| die "Cannot start server. " . Win32::FormatMessage( Win32::GetLastError() );
		
	$self->raise_event( 'server_started', { bot =>  $self } );

	# and wait for the loading to complete
	# TODO: probably better solved with WaitForWindow or somesuch
	sleep( $self->config->{'Monitor'}->{'ServerTimeout'} || 10 );
	
	$self->raise_event( 'fatal', { message => "Cannot start server. Check path_to_mercs and or server_start_timeout in the settings file." } ) 
		unless $process && $self->main_hwnd( $self->find_main_hwnd );
		
	$self->raise_event( 'notice', { message =>  "Started." } );

	# store starting time and the process
	$self->server_start_time( time );
	$self->server_proc($process);
		
	$self->raise_event( 'server_started', { bot => $self } );
	
	$self->raise_event( 'notice', { message =>  "Initializing screen 1/3..." } );
	$self->screen( FancyBot::GUI->new( bot => $self )->start_screen );

	$self->raise_event( 'notice', { message =>  "Initializing screen 2/3..." } );
	$self->screen->next;

	$self->raise_event( 'notice', { message =>  "Waiting for host..." } );
	$self->screen->host;
	
	$self->raise_event( 'notice', { message =>  "Fancybot is up and running." } );

	$self->watch_loop;
}

sub load_plugins
{
	my $self = shift;
	
	for my $plugin_name ( @{ $self->{config}->{PlugIns}->{PlugIn} } )
	{
		my $plugin; my $code = "
			use FancyBot::Plugins::$plugin_name;
			\$plugin = FancyBot::Plugins::$plugin_name->new();
		";

		print "[INIT] Loading Plugin: $plugin_name\n";
		eval $code;

		die "[FATAL] Error loading Plugin: $@\n"
			if $@;
		
		$self->register_events( $plugin );
		
		if ( -e "conf/${plugin_name}.xml" )
		{
			my $lconfig = XMLin( "conf/${plugin_name}.xml" );
			
			for ( keys %$lconfig )
			{
				$self->config->{ $plugin_name }->{ $_ } = $lconfig->{ $_ };
			}
		}
	}
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

sub send_chatter
{
	my $self = shift;
	$self->screen->send_chatter( @_ )
		if $self->screen;
}

sub send_long_chatter
{
	my $self = shift;
	$self->screen->send_long_chatter( @_ )
		if $self->screen;
}
			
sub instantiate_command_object
{
	my $self = shift;
	my $cfg  = shift;
	my $name = ucfirst( $cfg->{Name} );  $name =~ s/-(.)/uc($1)/ge; 
	my $mod  = "FancyBot::Commands::$name";
	my $code = "use $mod; \$cfg->{CommandObject} = $mod->new;";

	eval $code;

	$self->raise_event( 'notice', { message => "Error loading command ". $cfg->{Name}. ": $@" } ),
	$self->send_chatter( "Command '". $cfg->{Name}. "' doesn't exist or can't be loaded. May be not yet implemented.\n" ), return
		unless $cfg->{CommandObject};
		
	return $cfg->{CommandObject};
	
}

sub register_events {
	my $self   = shift;
	my $plugin = shift;
	
	for my $event_name ( keys %{ $plugin->events } )
	{
		push @{ $self->listeners->{ $event_name } }, $plugin->events->{ $event_name };
	}
}


	
sub watch_loop
{
	my $self = shift;
	
	$self->raise_event( 'debug', { message => 'enter watch loop' } );

	while ( $self->keep_running )
	{
		if ( $self->is_server_alive )
		{
			$self->raise_event( 'pulse', { bot => $self } );
			$self->do_events;
			sleep( $self->config->{'Monitor'}->{'EventLoopInterval'} );
		}
		else
		{
			if ( 1 )
			{
				$self->keep_running(0);
			}
			else
			{
				$self->start_server
			}
		}
	}
}

sub myconfess
{
	my $self = shift;
	my $i = 0;

	for ( GetChildWindows($self->main_hwnd) ) { 
		print $i++, ' ', $self->main_hwnd, " ! ", WMGetText($_), '==', GetClassName($_), "\n" ;
	}	
	print '-' x 60, "\n";

}
	
sub do_events
{
	my $self = shift;

	# $self->myconfess;

	my @windows;
	@windows =  GetChildWindows($self->main_hwnd);

	if ( ref $self->screen eq 'FancyBot::GUI::Lobby' )
	{
		my $ingame = $self->screen->in_game;
		
		$self->raise_event( 'game_stop', { bot => $self } )
			if $self->in_game && !$ingame;
		
		$self->raise_event( 'game_start', { bot => $self } )
			if ( !$self->in_game && $ingame );

		$self->in_game( $ingame ? 1 : 0 );
		
		my $last    = $self->last_chatter;
		my $chatter = WMGetText( $windows[172] ); 
		my $new     = diff \$last, \$chatter; 

		$self->last_chatter( $chatter );
		
		for my $msg ( split /(\x0D\x0A|\x0D|\x0A)/, $new )
		{
			next unless $msg =~ /^\+/;

			my ($user, $text) = $msg =~ /^\+(.*):> (.*)/; $user ||= '';
			next unless $text;
			
			$text =~ s/^-list (maps|players|bots|types)/-list-$1/;
			
			if ( $text =~ /^-([a-z-]+) ?(.*)/ )
			{
				$self->raise_event( 'command', { bot => $self, command => $1, user => $user, params => $2 } );
			}
			else
			{
				$self->raise_event( 'chatter', { bot => $self, user => $user, message => $text } );
			}
		}
	}
}

sub shutdown
{
	my $self = shift;
	$self->raise_event( 'notice', { message => 'Shutting down...' } );
	$self->keep_running(0);
	$self->kill_server;
}

sub kill_server
{
	my $self = shift;

	$self->raise_event( 'notice', { message => 'Stopping server...' } );
	$self->server_proc->Kill(1);
	
	$self->raise_event( 'notice', { message => 'Stopped.' } );
}

sub raise_event 
{
	my $self   = shift;
	my $events = shift;
	my $args   = shift;

	# print Dumper( [ $events ] ) unless $events eq 'pulse';
	# print ref( $events ), "\n";
	for my $event ( ref( $events ) ? (@$events) : ($events) )
	{
		print "[DEBUG] Event raised: $event $args\n" unless $event =~ /(pulse|debug|notice)/;
		if ( $self->listeners->{ $event } )
		{
			for my $listener ( @{ $self->listeners->{ $event } } )
			{
				return 
					unless $listener->( $args );
			}
		}
	}
		
	return;
}

sub update_gui
{
	my $self = shift;
	$self->screen->update_gui
}


sub player_info
{
	my $self = shift;

	# $self->send_chatter( 'Determining player info...');
	$self->is_updating_player_info(1);
	my $info =  $self->screen->player_info;
	
	$self->player_info_dirty( 0 );
	$self->do_events;
	
	if ( $self->player_info_dirty )
	{
		print "[DEBUG] Info dirty.\n";
		return $self->player_info;
	}
	else
	{
		$self->is_updating_player_info(0);
		return $info;
	}
}

sub update_player_info
{
	my $self  = shift;
	my $force = shift;
	print "[DEBUG] update player info...\n";
	
	return if $self->is_updating_player_info;
	print "[DEBUG] is not updating.\n";
	return if !$self->player_info_dirty && !$force;
	print "[DEBUG] is dirty.\n";
	
	my $info = $self->player_info;
	print Dumper($info);

	for my $player ( keys %$info )
	{
		my $user = $self->user( $player );
		
		$user->team( $info->{$player}->{team} );
		$user->is_bot( $info->{$player}->{bot} ? 1 : 0 );
		$user->mech( FancyBot::Mech->new(
			name    => $info->{$player}->{mech},
			tonnage => $info->{$player}->{tonnage},
			c_bills => $info->{$player}->{c_bills},
			variant => $info->{$player}->{variant}
		) );
	}
}




sub user
{
	my $self = shift;
	my $name = shift;
	
	while ( !$self->is_updating_player_info )
	{
		$self->users->{ $name } = FancyBot::User->new( name => $name, is_admin => $self->is_admin($name), is_super_admin => $self->is_super_admin($name) )
			unless defined $self->users->{ $name };
			
		$self->users->{ $name }->known_unit( $self->identfy_unit( $name ) );

		return $self->users->{ $name };
	}
}

sub identfy_unit
{
	my $self = shift;
	my $name = shift;
	
	my @units = ref $self->config->{ KnownUnits }->{ Unit } eq "ARRAY" ? 
				@{ $self->config->{ KnownUnits }->{ Unit } } :
				( $self->config->{ KnownUnits }->{ Unit } );
				
	for my $unit ( @units )
	{
		my $re = $unit->{Match}; 
		return $unit->{Name} if $name =~ /$re/
	}
		
	return '';
}

sub is_admin
{
	my $self   = shift;
	my $name = shift;
	
	return 1 if $self->is_super_admin($name);

	my $admins = $self->config->{Security}->{Admins}->{Admin}; 
	   $admins = [$admins] unless ref $admins  eq "ARRAY";

	return 1 if grep { ref $_ ? ( $_->{content} eq $name ) : $_ eq $name } @$admins;
	return 0;
}

sub is_super_admin
{
	my $self   = shift;
	my $name = shift;

	my $admins = $self->config->{Security}->{SuperAdmins}->{Admin}; 
	   $admins = [$admins] unless ref $admins eq "ARRAY";

	return 1 if grep { ref $_ ? ( $_->{content} eq $name ) : $_ eq $name } @$admins;
	return 0;
}





=head1 NAME

FancyBot - A control bot for the Mechwarrior 4 dedicated server!

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Nothing to see here, go away.

Or better,

Read the code, Luke!

=head1 EXPORT

=head1 AUTHOR

Tailgunner, C<< <tailgunner at somewhere.com> >>

=cut

1;
		