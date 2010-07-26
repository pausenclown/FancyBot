package FancyBot::Commands::Comstar;

use Moose;
use Data::Dumper;

sub execute 
{
	my $self    = shift;
	my $bot     = shift;
	my $user    = shift;
	my $topic   = quotemeta( shift ); 
	
	my @topics = ( @{ $bot->config->{Comstar}->{Gun} }, @{ $bot->config->{Comstar}->{Mech} } );
	
	for my $key ( qw( SubType Type Name ) )
	{
	
		my @foundx = grep { $_->{$key} ? $_->{$key} =~ /^${topic}$/i : 0 } @topics;
		my @found  = grep { $_->{$key} ? $_->{$key} =~ /$topic/i : 0  } @topics; 
		
		if ( @foundx == 0 && @found > 1 ) 
		{
			$bot->send_chatter( "Multiple items found: ". join( ', ', map { $_->{Name} } @found ) );
			return;
		}

		next
			if !@foundx && !@found; 
			
		my $found = @foundx ? $foundx[0] : $found[0];
		
		if ( ref $found->{Slots} )
		{
			$found->{Slots} = join ', ', 
				map { $_." (". $found->{Slots}->{$_}. ")" } 
				grep { !ref $found->{Slots}->{$_} } 
				keys %{ $found->{Slots} };
		}
		
		if ( ref $found->{Electronics} )
		{
			$found->{Electronics} = join ', ', 
				grep { $found->{Electronics}->{$_}  } 
				keys %{ $found->{Electronics} };
		}
		
		$bot->send_chatter( join( '; ', map { "$_: ". $found->{$_} } grep { $_ ne 'Name' } keys %{$found} ) );
		
		my @other = grep { $_ !~ /^${topic}$/i } map { $_->{Name} } @found;
		
		$bot->send_chatter( "Other items found: ". join( ', ',  @other ) )
			if @other;
		
		return 1;
	}
	
	$bot->send_chatter( "No items found." );
	return 1;
	
}

1;
	
