
package FancyBot;

use warnings;
use strict;

use FancyBot::GUI;
use FancyBot::User;

use Moose;
use Config::Simple;
use Data::Dumper;
use XML::Simple;
use Win32;
use Win32::Process;
use Win32::GuiTest qw( WMGetText FindWindowLike GetChildWindows GetComboContents SelComboItemText GetClassName);

our $VERSION = 0.01;

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
	my $self = shift;
	
	# error when server is alive
	die "Server already running.\n"
		if $self->is_server_alive;
		
	# read configuration file
	$self->{config} = XMLin( 'conf/FancyBot.xml' );
	# print Dumper( $self->config->{ComStar}->{Mech} );
	# my ($c, $ad, $sa, $u);
	# $c = $self->command( 'shutdown' );
	# $sa = $self->user( 'DSA_Tailgnnr_SGT' ); print $sa->is_admin, $sa->is_super_admin;
	# $ad = $self->user( 'DSA_Warhorse_CO' );  print $ad->is_admin, $ad->is_super_admin;
	# $u  = $self->user( 'DSA_X' ); print $u->is_admin, $u->is_super_admin;
	
	# print Dumper( $c, $sa );
	
	# load plugins as configured
	$self->load_plugins;
	
	$self->raise_event( 'notice', { message =>  "Starting Dedicated Server...\n" } );
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
	
	$self->raise_event( 'fatal', { message => "Cannot start server. Check path_to_mercs and or server_start_timeout in the settings file.\n" } ) 
		unless $process && $self->main_hwnd( $self->find_main_hwnd );
		
	$self->raise_event( 'notice', { message =>  "Started.\n" } );

	# store starting time and the process
	$self->server_start_time( time );
	$self->server_proc($process);
		
	$self->raise_event( 'notice', { message =>  "Fancybot is up and running." } );

	$self->raise_event( 'server_started', { bot => $self } );
	
	$self->screen( FancyBot::GUI->new( bot => $self )->start_screen );
	$self->screen->next;
	$self->screen->host;
	sleep 5;
	
	# $self->raise_event( 'command', { command =>  "shutdown", bot => $self } );
	# $self->screen->quit;
	

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

		print "Loading Plugin: $plugin_name\n";
		eval $code;

		die "Error loading Plugin: $@\n"
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
	my $cmd  = shift;
	
	my $cfgs = [ grep { $_->{Name} eq $cmd } @{ $self->config->{Commands}->{Command} } ];

	if ( @$cfgs )
	{
		if ( @$cfgs == 1 )
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
	my $mod  = "FancyBot::Commands::$name"; print "/// $name\n";
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
	
use Text::Diff;

sub watch_loop
{
	my $self = shift;
	
	$self->raise_event( 'debug', { message => 'enter watch loop' } );
	
	while ( $self->keep_running )
	{
		if ( $self->is_server_alive )
		{
			# my $i = 0;
			# for ( GetChildWindows($self->main_hwnd) ) { 
				# print $i++, ' ', $self->main_hwnd, " ! ", WMGetText($_), '==', GetClassName($_), "\n" ;
				# # $g{GetClassName($_)}++;
			# }	
			# print '-' x 60, "\n";
			if ( ref $self->screen eq 'FancyBot::GUI::Lobby' )
			{
				my $last    = $self->last_chatter;
				my $chatter = WMGetText( ( GetChildWindows($self->main_hwnd) )[172] ); 
				my $new     = diff \$last, \$chatter; 
				#print 'L1 ', length($new), "\n";
				#chop $new;
				#print 'L2 ', length($new), "\n";
				#for (split //, $new) { print $_, '(', ord($_), ') '  };
				#print "\n";
				for my $msg ( split /(\x0D\x0A|\x0D|\x0A)/, $new )
				{
					
					next unless $msg =~ /^\+/;

					my ($user, $text) = $msg =~ /^\+(.*):> (.*)/; $user ||= '';
					next unless $text;
					
					$text =~ s/^-list (maps|players)/-list-$1/;
					
					if ( $text =~ /^-([a-z-]+) ?(.*)/ )
					{
						$self->raise_event( 'command', { bot => $self, command => $1, user => $user, params => $2 } );
					}
					else
					{
						$self->raise_event( 'chatter', { bot => $self, user => $user, message => $text } );
					}
				}
				
				$self->last_chatter( $chatter );
			}

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

	# print Dumper( $events );
	# print ref( $events ), "\n";
	for my $event ( ref( $events ) ? (@$events) : ($events) )
	{
		# print "EV $event\n";
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

sub user
{
	my $self = shift;
	my $name = shift;
	return FancyBot::User->new( name => $name, is_admin => $self->is_admin($name), is_super_admin => $self->is_super_admin($name) );
}

sub is_admin
{
	my $self   = shift;
	my $name = shift;
	
	return 1 if $self->is_super_admin($name);

	my $admins = $self->config->{Security}->{Admins}->{Admin}; 
	   $admins = [$admins] unless ref $admins;

	return 1 if grep { $_ eq $name } @$admins;
	return 0;
}

sub is_super_admin
{
	my $self   = shift;
	my $name = shift;

	my $admins = $self->config->{Security}->{SuperAdmins}->{Admin}; 
	   $admins = [$admins] unless ref $admins;

	return 1 if grep { $_ eq $name } @$admins;
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
