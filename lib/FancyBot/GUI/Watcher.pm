package FancyBot::GUI::Watcher;

use threads;
use threads::shared;

use warnings;
use strict;

use Win32::GuiTest qw( GetListContents );
use JSON;
use Data::Dumper;

our $listbox_dirty  : shared;
our $last_update    : shared;
our %nplayer_info   : shared;
our %iplayer_info   : shared;

sub start
{
	my $hwnd = shift;
	
	threads->new( 
		sub { 
			my $hwnd = shift;
			$last_update = 0;
			
			while (1) {
				my @list; eval {
					@list = GetListContents( $hwnd );
				};
				
				next if $listbox_dirty;
	
				my ($players, $iplayers) = parse_player_list( @list );
	
				if ( $players ) 
				{
					my $data = to_json( $players );
					my $idata = to_json( $iplayers );
					
					lock( %nplayer_info ); 
					lock( %iplayer_info );
					
					$nplayer_info{$hwnd} = $data;
					$iplayer_info{$hwnd} = $idata;
					
					$last_update = time;
					
					$listbox_dirty = 0;
				}
			}
		},
		$hwnd
	);
}


sub player_info {
	my $hwnd  = shift;
	my $index = shift;
	my $data  = $nplayer_info{$hwnd};
	
	return {} unless $data;
	
	$data = from_json( $data );

	return $index ? $data->{ $index } : $data;
}

sub iplayer_info {
	my $hwnd  = shift;
	my $index = shift;
	my $data  = $iplayer_info{$hwnd};
	
	return [] unless $data;
	
	$data = from_json( $data );

	return $index ? $data->[ $index ] : $data;
}

sub parse_player_list
{
	my @list = @_;
	my %players; my @players;
	
	for (my $i = 0; $i < @list; $i++) 
	{
		my @record;

		for (my $j = $i; $j < 164; $j+=24)
		{
			my $v = defined $list[$j] ? $list[$j] : '';  
			$v =~ s/^ +$//;
			push @record, $v;
		}

		last unless $record[0];

		return unless 
			$record[3] =~ /^\d+\.\d$/ &&
			$record[4] =~ /^\d+k$/ &&
			$record[6] =~ /^(Accepted|Ready|Denied)$/;

		
		$record[3] =~ s/\..+//;
		$record[4] =~ s/^.*(\d+).*$/$1/;

		$record[5] =~ s/ \(BL:(\d+)\)//;
		$record[5] = 0 if $record[5] eq '-';
		$record[7] =  $1||0; 
		
		my $player = {
			position => $i,
			name     => $record[0],
			mech     => $record[1],
			variant  => $record[2],
			tonnage  => $record[3],
			c_bills  => $record[4],
			team     => $record[5],
			status   => $record[6],
			bot      => $record[7],
		};
		
		$players{ $player->{name} } = $player;
		push @players, $player;
	}
	
	return (\%players, \@players);
}

1;
