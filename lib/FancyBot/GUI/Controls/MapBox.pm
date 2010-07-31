package FancyBot::GUI::Controls::MapBox;

use Moose;

extends 'FancyBot::GUI::Controls::TrickyComboBox';

has map_cache =>
	isa     => 'HashRef',
	is      => 'ro',
	default => sub {{}};

sub get_list
{
	my $self   = shift;
	my $type   = shift;
	my $search = shift;
	
	unless ( $self->map_cache->{$type} )
	{
		for ( FancyBot::GUI::GetComboContents( $self->hwnd ) )
		{
			push @{$self->map_cache->{ $type }}, $1
				if /^(.+?) - [^\-]+$/;
		}
		$self->map_cache->{ $type } = [ sort @{ $self->map_cache->{ $type } } ];
	}
	
	my $maps = $self->map_cache->{ $type };
		
	return $search ? grep { /$search/i } @$maps : @$maps;
}

1;