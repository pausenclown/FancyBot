package FancyBot::GUI::Lobby::KickBan;

use Moose::Role;
use Data::Dumper;

sub prepare_player_kick {
	my $self     = shift;
	my $player   = shift;
	my $user     = $self->bot->user( $player );
	# print Dumper($user);
	$self->bot->send_chatter( "Kick failed, no such player '$player'." ), return
		unless $user->is_bot || $user->is_connected;
		
	$self->bot->send_chatter( "Prepare for KICK $player..." );
	
	push @{ $self->bot->pending_kicks }, $player;

	return 1;
}

sub kick_a_player 
{
	my $self    = shift; 
	my $kickees = $self->bot->pending_kicks;

	if ( @$kickees )
	{
		return $self->kick_player( shift @$kickees );
	}
	
	return;
}

sub kick_player
{
	my $self = shift;
	my $name = shift; print "K $name\n";
	my $user = $self->bot->user( $name );

	my $position = $user->position;
	my $button   = $self->get_control('btnKick');
	
	$self->bot->send_chatter( "Kicking $name..." );
	
	$button->push;
	#FancyBot::GUI::SendKeys( $name );
	#FancyBot::GUI::SendKeys( '{ENTER}' );
		
	FancyBot::GUI::SendKeys( ( '{DOWN}' x ( $position + 1 ) ). '{ENTER}' );
	
	
	# remove the user from the list if it is a bot
	if ( $user->is_bot )
	{
		$self->bot->delete_user( $name );
	}
	else
	{
		$user->times_kicked( $user->times_kicked + 1 );
		$user->last_kick( time )
	}
	
	return 1;
}



1;