=head1 FancyBot::Commands::Login

Try to aquire administrator priviliges

=head1 SYNOPSIS

	-admin 
 
=head1 DESCRIPTION

Try to aquire administrator priviliges. The required token (here 76198A508CDD42879D9E7A3458018DF7)
must be gained by logging in at the webshell.

This command is only useful when Security.Paranoia is in effect.

=cut


# Last part of package name must correspond to the command name, 
# with the first letter uppercase.
package FancyBot::Commands::Login;

use Moose;

# Main function of the command
# Receives references to self, bot, user and the commands argument(s), 
# which is everything that follows the space after the command name.
sub execute 
{
	# Fetch args from @_
	my $self  = shift;
	my $bot   = shift;
	my $user  = shift;
	my $token = shift;

	# Open the token file
	unless ( open my $in, "<", "login/$token" )
	{
		$bot->send_chatter( "Irregular token." );
		return;
	}
	
	# Read contents
	my $line = <$in>; chomp $line;
	my ( $time, $cuser ) = split /:/, $line;
	
	# Detect hijack, user doesnt match user from token
	unless ( $cuser eq $user )
	{
		$bot->send_chatter( "Token Hijack detected. $user be warned." );
		return;
	}
	
	# Detect Timeout
	unless ( $time + ($bot->config->{Security}->{TokenTimeout}||60) > time )
	{
		$bot->send_chatter( "Token timeout. Please relogin at the webshell." );
		return;
	}
	
	# all good, set authorized flag
	$bot->user( $user )->is_authorized(1);
		
	return 1;
}

1;