package FancyBot::Plugins::Logger;

use Moose;
use Carp qw( confess );
use POSIX qw( strftime );

has events =>
	isa     => 'HashRef',
	is      => 'ro',
	default => sub {{
		'starting_server' => sub {
			my $args  = shift;
			my $bot   = $args->{bot}     || confess "No bot reference";
			
			for ( qw( ChatLogFile ErrorLogFile LogFile ) )
			{
				my $file = $bot->config->{Logger}->{$_};
				$bot->config->{Logger}->{$_} = IO::File->new( ">> $file" );
			}
		},
		'notice' => sub {
			my $args  = shift;
			my $bot   = $args->{bot}     || confess "No bot reference";
			
			print '[NOTICE] ', $args->{message}, "\n";
			$bot->config->{Logger}->{LogFile}->print( '[NOTICE:', strftime('%x %X', localtime), '] ', $args->{message}, "\n" );
		},
		'debug' => sub {
			my $args  = shift;
			my $bot   = $args->{bot}     || confess "No bot reference";
	
			print '[DEBUG] ', $args->{message}, "\n";
			$bot->config->{Logger}->{LogFile}->print( '[DEBUG:', strftime('%x %X', localtime), '] ', $args->{message}, "\n" );
		},
		'fatal' => sub {
			my $args  = shift;
			my $bot   = $args->{bot}     || confess "No bot reference";

			print '[ERROR] ', $args->{message}, "\n";
			$bot->config->{Logger}->{ErrorLogFile}->print( '[ERROR:', strftime('%x %X', localtime), '] ', $args->{message}, "\n" );
			exit;
		},
		'error' => sub {
			my $args  = shift;
			my $bot   = $args->{bot}     || confess "No bot reference";

			print '[ERROR] ', $args->{message}, "\n";
			$bot->config->{Logger}->{ErrorLogFile}->print( '[ERROR:', strftime('%x %X', localtime), '] ', $args->{message}, "\n" );
		},

		'warning' => sub {
			my $args  = shift;
			my $bot   = $args->{bot}     || confess "No bot reference";

			print '[WARNING] ', $args->{message}, "\n";
			$bot->config->{Logger}->{ErrorLogFile}->print( '[WARNING:', strftime('%x %X', localtime), '] ', $args->{message}, "\n" );
		},
		'chatter' => sub {
			my $args  = shift;
			my $bot   = $args->{bot}     || confess "No bot reference";

			print '[CHAT] ', $args->{message}, "\n";
			$bot->config->{Logger}->{ChatLogFile}->print( '[CHAT:', strftime('%x %X', localtime), '] ', $args->{message}, "\n" );
		},
		'command' => sub {
			my $args  = shift;
			my $bot   = $args->{bot}     || confess "No bot reference";
			my $cmd   = $args->{command} || '';
			my $prm   = $args->{params};
			my $user  = $args->{user};		

			print '[COMMAND] ', "$user : $cmd : $prm\n";
		}
	}};

1;