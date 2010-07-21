package FancyBot::Commands::Comstar;

use Moose;
use Data::Dumper;

sub execute 
{
	my $self    = shift;
	my $bot     = shift;
	my $user    = shift;
	my $topic   = quotemeta( shift );
	
	my @topics = ( @{ $bot->config->{ComStar}->{Gun} }, @{ $bot->config->{ComStar}->{Mech} } );
	
	my @foundx = grep { $_->{Name} =~ /^${topic}$/i } @topics;
	my @found  = grep { $_->{Name} =~ /$topic/i } @topics;
	
	if ( !@foundx && @found > 1 ) 
	{
		$bot->send_chatter( "Multiple items found: ". join( ', ', map { $_->{Name} } @found ) );
		return;
	}
	
	if ( !@foundx && !@found  ) 
	{
		$bot->send_chatter( "No items found." );
		return;
	}
	
	@found = @foundx if @foundx;
	
	if ( ref $found[0]->{Slots} )
	{
		$found[0]->{Slots} = join ', ', 
			map { $_." (". $found[0]->{Slots}->{$_}. ")" } 
			grep { !ref $found[0]->{Slots}->{$_} } 
			keys %{ $found[0]->{Slots} };
	}
	
	if ( ref $found[0]->{Electronics} )
	{
		$found[0]->{Electronics} = join ', ', 
			grep { $found[0]->{Electronics}->{$_}  } 
			keys %{ $found[0]->{Electronics} };
	}
	
	$bot->send_chatter( join( '; ', map { "$_: ". $found[0]->{$_} } grep { $_ ne 'Name' } keys %{$found[0]} ) );

	return 1;
}

1;
	
