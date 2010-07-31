=head1 FancyBot::Plugin::Commands

FancyBot Command Plugin 

=head1 SYNOPSIS
 
=head1 DESCRIPTION

This plugin reacts to commands that typed in game chat. Recognized commands must have the form of 

=over 4

=item a minus sign

=item the command name , optionally followed by

=item a space

=item and the commands' argument(s).

=back

The argument(s) is/are sent do the command as a string. If there are multiple arguments, the command 
is responsible to parse them out of that string on its own.

=cut

package FancyBot::Plugins::Commands;

use Moose;
use Data::Dumper;

# Declare the events we listen to, here: command
has events =>
	isa     => 'HashRef',
	is      => 'ro',
	default => sub {{
		# React to a command
		'command' => sub 
		{
			# Fetch arguments
			my $args  = shift;
			
			# Make sure we got a bot reference
			my $bot  = $args->{bot} || die 'No bot reference';
			
			# Fetch the config info for the command from the bot, 
			# step out if the command is not recognized.
			my $cmd  = $bot->command( $args ) || return;
			# print Dumper( $cmd );
			
			# Fetch a FancyBot::User Object from the bot
			my $user = $bot->user( $args->{user} );

			# Check if user is authorized for the command
			if ( $user->is_allowed_to( $cmd, $bot->config->{Security}->{Paranoia} ) )
			{
				# If so, fetch the FancyBot::Plugin::Command object
				my $co = $cmd->{CommandObject};
				# print Dumper( $co );
				if ( $co )
				{
					# Execute the command...
					eval { $co->execute( $bot, $user, $args->{params}, $cmd ) };

					# and complain if there is an error.
					$_ = "Error executing command '". $cmd->{Name}. "': $@",
					$bot->send_chatter( $_ ),
					$bot->raise_event( 'notice', { bot => $bot, message => $_ } )
						if $@;
				} 
			}
			else
			{
				# if not, inform the user.
				$bot->send_chatter( 'Denied.' )
			}
		}
	}};

1;
