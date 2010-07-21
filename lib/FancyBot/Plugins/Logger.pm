package FancyBot::Plugins::Logger;

use Moose;

has events =>
	isa     => 'HashRef',
	is      => 'ro',
	default => sub {{
		'notice' => sub {
			print '[NOTICE] ', +shift->{message}, "\n";
		},
		'debug' => sub {
			print '[DEBUG] ', +shift->{message}, "\n";
		},
		'fatal' => sub {
			print '[ERROR] ', +shift->{message}, "\n";
			exit;
		},
		'chatter' => sub {
			print '[CHAT] ', +shift->{message}, "\n";
		},
		'command' => sub {
			my $args  = shift;
			my $bot   = $args->{bot}     || die "No bot reference";
			my $cmd   = $args->{command} || die "No command";
			my $prm   = $args->{params};
			my $user  = $args->{user};		

			print '[COMMAND] ', "$user : $cmd : $prm\n";
		}
	}};

1;