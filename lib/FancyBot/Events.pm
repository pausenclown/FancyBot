package FancyBot::Events;

use Moose::Role;

# holds a reference to an Hash of Arrays; The keys being event names, the 
# latter holding references to listening subroutines
has listeners =>
	isa     => 'HashRef',
	is      => 'ro',
	default => sub {{}};

# Flag showing wether a game is running or not
has in_game => 
	isa     => 'Bool',
	is      => 'rw',
	default => 0;


sub register_events {
	my $self   = shift;
	my $plugin = shift;
	
	for my $event_name ( keys %{ $plugin->events } )
	{
		push @{ $self->listeners->{ $event_name } }, $plugin->events->{ $event_name };
	}
}

sub watch_loop
{
	my $self = shift;
	
	$self->raise_event( 'debug', { bot => $self, message => 'enter watch loop' } );
	
	while ( $self->keep_running )
	{
		if ( $self->is_server_alive )
		{
			eval {
				$self->update_player_info;
			};

			$self->raise_event( 'warning', { bot => $self, message => $@ } )
				if $@;

			eval 
			{
				$self->raise_event( 'pulse', { bot => $self } );
				$self->do_events;

				sleep( $self->config->{'Monitor'}->{'EventLoopInterval'} );
			};

			$self->raise_event( 'error', { bot => $self, message => $@ } )
				if $@;
		}
		else
		{
			if ( 1 )
			{
				$self->keep_running(0);
			}
			else
			{
				$self->start_server
			}
		}
	}
}

sub raise_event 
{
	my $self   = shift;
	my $events = shift;
	my $args   = shift;

	for my $event ( ref( $events ) ? (@$events) : ($events) )
	{
		print "[DEBUG] Event raised: $event $args\n" unless $event =~ /(pulse|debug|notice)/;
		if ( $self->listeners->{ $event } )
		{
			for my $listener ( @{ $self->listeners->{ $event } } )
			{
				return 
					unless $listener->( $args );
			}
		}
	}
		
	return;
}

sub do_events
{
	my $self = shift;

	if ( ref $self->screen eq 'FancyBot::GUI::Lobby' )
	{
		my $ingame = $self->screen->in_game;
		
		$self->raise_event( 'game_stop', { bot => $self } )
			if $self->in_game && !$ingame;
		
		$self->raise_event( 'game_start', { bot => $self } )
			if ( !$self->in_game && $ingame );

		$self->in_game( $ingame ? 1 : 0 );

		for my $msg ( $self->screen->new_chatter )
		{
			my ($user, $text) = $msg =~ /^(.*):> (.*)/; $user ||= ''; next unless $text;

			if ( $self->is_command( $text ) )
			{
				$self->process_command( $text, $user );
			}
			else
			{
				$self->raise_event( 'chatter', { bot => $self, user => $user, message => $text } );
			}
		}
	}
}

1;