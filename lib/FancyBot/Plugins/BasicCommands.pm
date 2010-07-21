package FancyBot::Plugins::BasicCommands;

use Moose;
use Data::Dumper;
use FancyBot::User;
use Win32::GuiTest qw( GetListContents GetChildWindows );
use List::Util qw( sum );

# PublicCommands=vote,info,help,fancy,list
# VotableCommands=launch,kick,stop,ban
# AdminCommands=restart,config,launch,stop,kick,ban
# SuperAdminCommands=shutdown,pconfig

use XML::Simple qw(:strict);

my $commands = 
{
	'help -shutdown' => sub {
		my $bot    = shift;
		$bot->screen->send_chatter( "-shutdown takes the server off line.");
		
		return 1;
	},
	shutdown => sub {
		my $bot       = shift;
		my @timeout   = @{ $bot->config->{main}->{'Monitor.ShutdownTime'} };
		my $remaining = shift @timeout;
		
		$bot->raise_event( ['chatter','notice'], { message => $bot->config->{main}->{'Monitor.ShutdownWarning'}->[0] } );
		$bot->raise_event( ['chatter','notice'], { message => "$remaining seconds remaining" } );
		
		while ( @timeout )
		{
			sleep( $timeout[0] );
			$remaining = $remaining - shift @timeout;
			$bot->raise_event( ['chatter','notice'], { message => "$remaining seconds remaining" } );
		}
		
		$bot->shutdown;
		
		return 1;
	},
	'help -restart' => sub {
		my $bot    = shift;
		$bot->screen->send_chatter( "-restarts the server, taking config changes per -config into account. ");
	},
	restart => sub {
		my $bot  = shift;
		$bot->kill_server;
		$bot->start_server;
		
		return 1;
	},
	'help -info' => sub {
		my $bot    = shift;
		$bot->screen->send_chatter( "Syntax for -info is '-info <playername>'." );
	},
	info => sub {
		my $bot    = shift;
		my $user   = shift;
		my $player = shift;
		
		my $players = $bot->screen->player_info;
		
		$bot->info_help, return
			unless $player;
			
		if ( $players->{ $player } )
		{
			$bot->screen->send_chatter( "$player is using a ".  $players->{ $player }->{tonnage}. " tons ". $players->{ $player }->{mech} );
		}
		else
		{
			$bot->screen->send_chatter( "No player '$player' connected." );
		}
		
		return 1;
	},
	stats => sub {
		my $bot    = shift;
		my $user   = shift;
		my $player = shift;
		
		if ( my $user = $bot->users->{ $player } )
		{

			my %map = (
				Connections         => 'times_connected',
				Joins               => 'times_joined',
				KillsOverall        => 'kills_overall',
				KillsThisMatch      => 'kills_this_match',
				CurrentKillStreak   => 'current_kill_streak',
				LongestKillStreak   => 'longest_kill_streak',
				HeaviestKillStreak  => 'longest_kill_streak',
				DeathsOverall       => 'deaths_overall',
				DeathsThisMatch     => 'deaths_this_match',
				CurrentDeathStreak  => 'current_death_streak',
				LongestDeathStreak  => 'longest_death_streak'
			);
			
			my @lstats ;
			my @stats;
			
			while ( my ($key,$sub) = each %map )
			{
				next unless $bot->config->{main}->{"UserStats.$key"} && $bot->config->{main}->{"UserStats.$key"} =~ /1|true/i;
				
				push @stats, " $key = ". $user->$sub();
			}
			
			$bot->screen->send_chatter( "Stats for $player: " );
			$bot->screen->send_long_chatter( 100, " / ", join " / ", @stats );
		}
		else
		{
			$bot->screen->send_chatter( "No user '$player' connected." );
		}
		
		return 1;
	},	
	'help -help' => sub {
		my $bot    = shift;
		$bot->screen->send_chatter( "Haha. Funny!" );
		
		return 1;
	},
	help => sub {
		my $bot   = shift;
		my $user  = shift;
		my $topic = shift;
		
		$bot->screen->send_chatter( "Type -commands for a list of commands, type -help <command> for further help." ), return
			unless $topic;
			
		$bot->raise_event( 'command', { bot => $bot, command => "help -$topic", user => $user, params => '' } );
		
		return 1;
	},
	'help -launch' => sub {
		my $bot    = shift;
		$bot->screen->send_chatter( "Starts the mission immideatly." );
		return 1;
	},	
	launch => sub {
		my $bot   = shift;
		my $user  = shift;
		
		$bot->screen->launch;
			
		$bot->raise_event( 'drop_start', { bot => $bot, user => $user, params => time } );
		
		return 1;
	},
	'help -stop' => sub {
		my $bot    = shift;
		$bot->screen->send_chatter( "Stops the mission immideatly." );
		return 1;
	},		
	stop => sub {
		my $bot   = shift;
		my $user  = shift;
		
		$bot->screen->stop_map;
			
		$bot->raise_event( 'drop_stop', { bot => $bot, user => $user, params => time } );
		
		return 1;
	},
	'help -maps' => sub {
		my $bot    = shift;
		$bot->screen->send_chatter( "Syntax for -maps is '-maps <search term>'. The search term is optional. If ommitted lists all maps." );
		return 1;
	},		
	maps => sub {
		my $bot    = shift;
		my $user   = shift;
		my $search = shift;
	
		$bot->screen->send_long_chatter( 100, ", ", join ", ", $bot->screen->maps( $search ) ); 
		
		return 1;
	},
	'help -maps' => sub {
		my $bot    = shift;
		$bot->screen->send_chatter( "Syntax for -maps is '-maps <search term>'. The search term is optional. If ommitted lists all maps." );
		return 1;
	},		
	maps => sub {
		my $bot    = shift;
		my $user   = shift;
		my $search = shift;
	
		$bot->screen->send_long_chatter( 70, ", ", join ", ", $bot->screen->maps( $search ) ); 
		
		return 1;
	},	
	
	'help -map' => sub {
		my $bot    = shift;
		$bot->screen->send_chatter( "Selects a map. Syntax is '-map <search term>'. The search must lead to a unique result." );
		return 1;
	},	
	map => sub {
		my $bot    = shift;
		my $user   = shift;
		my $search = shift;
	
		if ( $bot->screen->select_map( $search ) )
		{
			$bot->screen->send_chatter( "Map selected." ); 
		}
		else
		{
			$bot->screen->send_chatter( "Error selecting map." ); 
		}
		
		
		return 1;
	},	
	mmap => sub {
		my $bot    = shift;
		my $user   = shift;
		my $search = shift;
	
		$bot->screen->send_chatter( "-map $search" ); 
		
		return 1;
	},		
	'help -timeline' => sub {
		my $bot    = shift;
		$bot->screen->send_chatter( "Selects a time. That means weapons and Mechs are restricted to a year, according to the BT-Wiki. Syntax is '-timeline <year>'." );
		return 1;
	},
	'help -config' => sub {
		my $bot    = shift;
		$bot->screen->send_chatter( "Allows to configurate the server (aka changing the ini file). Syntax is '-config Key=Value'" );
		return 1;
	},
	config => sub {
		my $bot     = shift;
		my $user    = shift;
		my ($k, $v) = split /=/, +shift, 2;
		my $old    = $bot->config->{main}->{ $k };
		$bot->config->{main}->{ $k } = $v;
		$bot->screen->send_long_chatter( 80, ' ', "Changed Config Value '$k' from '$old' to '$v'. You must restart the server for changes to take effect." );

		# saving the changes back to file:
		
		
		return 1;
	},

	'help -version' => sub {
		my $bot    = shift;
		$bot->screen->send_chatter( "Shows the version number of the bot." );
		return 1;
	},
	version => sub {
		my $bot     = shift;
		$bot->screen->send_chatter( "FancyBot Version ". $FancyBot::VERSION );
		return 1;
	}	
};
	
$commands->{commands} = sub {
	my $bot  = shift;
	$bot->screen->send_chatter( join ', ', sort grep { !/help/ } keys %$commands );
};



has events =>
	isa     => 'HashRef',
	is      => 'ro',
	default => sub {{
		'command' => sub 
		{
			my $args  = shift;
			
			my $bot  = $args->{bot}     || die "No bot reference";
			my $cmd  = $args->{command} || die "No command";
			my $prm  = $args->{params};
			my $user = $args->{user};
			
			if ( $commands->{ $cmd } )
			{
				$commands->{ $cmd }->( $bot, $user, $prm );
			}
		},
		'chatter' => sub 
		{
			my $args  = shift;
			print "FancyBot::Plugins::BC::chatter\n";
			my $txt  = $args->{message}  || die "No message";
			my $bot  = $args->{bot}     || die "No bot reference";
			print "********* $txt ***********\n";
			if ( $txt =~ /(.+) has connected$/ )
			{
				print "** $1 **\n";
				if ( defined $bot->users->{$1} )
				{
					print Dumper( $bot->users->{$1} );
					$bot->users->{$1}->stash->{overall_stats}->{connections}++;
					print "*** ",  $bot->users->{$1}->stash->{overall_stats}->{connections}, "**\n";
				}
				else
				{
					$bot->users->{$1} = FancyBot::User->new( name => $1 );
				}
			}
			
			if ( $txt =~ /(.+) has joined$/ )
			{
				if ( defined $bot->users->{$1} )
				{
					$bot->users->{$1}->stash->{overall_stats}->{joins}++;
				}
			}
			
			return 1;
		},
	}};

1;