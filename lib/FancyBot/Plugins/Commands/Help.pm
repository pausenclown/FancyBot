package FancyBot::Plugins::Commands::Help;

use Moose;

sub execute 
{
	my $self  = shift;
	my $bot   = shift;
	my $user  = shift;
	my $topic = shift;
	
	$bot->screen->send_chatter( "Type -commands for a list of commands, type -help <command> for further help." );
	# , return
		# unless $topic;
		
	# $bot->raise_event( 'command', { bot => $bot, command => "help -$topic", user => $user, params => '' } );
	
	return 1;
}

1;