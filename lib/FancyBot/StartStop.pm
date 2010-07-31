package FancyBot::StartStop;

use Moose::Role;

use XML::Simple;
use Win32::Process;
use Data::Dumper;

sub start_server
{
	my $self          = shift;
	my $keep_config   = shift;

	# error when server is alive
	die "Server already running.\n"
		if $self->is_server_alive;
	
	# read configuration file
	$self->{config} = XMLin( 'conf/FancyBot.xml', SuppressEmpty => '')
		unless keys %{$self->{config}};
	
	# load plugins as configured
	$self->load_plugins;

	$self->raise_event( 'starting_server', { bot =>  $self } );
	$self->raise_event( 'notice', { bot => $self, message =>  "Starting Dedicated Server..." } );
	
	# create a process object for the server
	my $process;
	my $mercs_path = $self->config->{'Server'}->{'PathToMercs'} || '.';
	my $mw4exe     = "$mercs_path\\MW4Mercs.exe";
	
    Win32::Process::Create( $process, $mw4exe, ' -win32dedicated', 0, NORMAL_PRIORITY_CLASS, $mercs_path )
		|| die "Cannot start server. " . Win32::FormatMessage( Win32::GetLastError() );
		
	$self->raise_event( 'server_started', { bot =>  $self } );

	# and wait for the loading to complete
	# TODO: probably better solved with WaitForWindow or somesuch
	sleep( $self->config->{'Monitor'}->{'ServerTimeout'} || 12 );
	
	$self->raise_event( 'fatal', { bot => $self, message => "Cannot start server. Check path_to_mercs and or server_start_timeout in the settings file." } ) 
		unless $process && $self->main_hwnd( $self->find_main_hwnd );
		
	$self->raise_event( 'notice', { bot => $self, message =>  "Started." } );

	# store starting time and the process
	$self->server_start_time( time );
	$self->server_proc($process);
		
	$self->raise_event( 'server_started', { bot => $self } );
	
	
	$self->raise_event( 'notice', {  bot => $self, message =>  "Initializing screen 1/3..." } );
	
	$self->screen( FancyBot::GUI->new( bot => $self )->start_screen );
	print Dumper( $self->screen->control_map );
	$self->raise_event( 'notice', { bot => $self, message =>  "Initializing screen 2/3..." } );
	$self->screen->next;

	$self->raise_event( 'notice', { bot => $self, message =>  "Waiting for host..." } );
	$self->screen->host;
	
	$self->raise_event( 'notice', { bot => $self, message =>  "Fancybot is up and running." } );

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
			my $lconfig = XMLin( "conf/${plugin_name}.xml", SuppressEmpty => '' );
			
			for ( keys %$lconfig )
			{
				
				$self->config->{ $plugin_name }->{ $_ } = $lconfig->{ $_ };
			}
			
			
		}
	}
}

sub shutdown
{
	my $self = shift;
	$self->raise_event( 'notice', { bot => $self, message => 'Shutting down...' } );
	$self->keep_running(0);
	$self->kill_server;
	open my $out, '>', 'stop_bot'; print $out 'stopped.'; close $out;
}

sub kill_server
{
	my $self = shift;

	$self->raise_event( 'notice', { bot => $self, message => 'Stopping server...' } );
	$self->server_proc->Kill(1);
	$self->raise_event( 'notice', { bot => $self, message => 'Stopped.' } );
}

1;