package FancyBot::Commands::Vote;

use Moose;

sub execute 
{
	my ( $self, $bot, $user, $args, $command, $parsed_args ) = @_;
	
	my $stash = $bot->plugin_stash->{'vote'};

	if ( $stash->{in_progress} )
	{
		$bot->send_chatter( 'Vote in progress.' );
	}
	else
	{
		$bot->send_chatter( $user->name. " started a vote to '$args'..." );

		$bot->plugin_stash->{'vote'} = 
		{
			in_progress => 1,
			start_time  => time,
			initiator   => $user,
			command     => "-$args",
			result      => {
				yes => {
					$user->name => 1
				},
				no => {},
			}
		};
	}
}

1;
