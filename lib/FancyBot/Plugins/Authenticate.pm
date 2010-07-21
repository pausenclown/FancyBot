package FancyBot::Plugins::Security;

use Moose;
use Data::Dumper;
use Win32::GuiTest qw( GetListContents GetChildWindows );

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
				return unless 
					$bot->users->{ $user }->is_allowed_to( $cmd );
					
				$commands->{ $cmd }->( $bot, $user, $prm );
			}
			
			return 1;
		},
	}};

1;