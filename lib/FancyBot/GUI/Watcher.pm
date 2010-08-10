package FancyBot::GUI::Watcher;

use warnings;
use strict;

use threads;
use threads::shared;

use JSON;
use File::Slurp qw( read_file write_file );
use Win32::GuiTest qw( GetListContents );
use Data::Dumper;

our $last_update : shared;
our %json;

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
				}; # print Dumper( \@list );
	
				my ($players, $iplayers) = parse_player_list( @list );
				
				if ( $players )
				{
					eval {
						write_file( "tmp/player_info.$hwnd", to_json( [$players, $iplayers] ) );
						$last_update = time;
					};
					
					print "[WARN] Could not write playerinfo file: $@\n"
						if $@;
				}
			}
		},
		$hwnd
	);
}


sub player_info 
{
	my $hwnd  = shift || die "No handle for player_info!\n";
	my $index = shift;

	if ( -e "tmp/player_info.$hwnd" )
	{
		$json{$hwnd} = from_json( read_file( "tmp/player_info.$hwnd" ) );
		unlink( "tmp/player_info.$hwnd" );
	}
	
	return {} unless $json{$hwnd};
	
	return $index ? $json{$hwnd}->[0]->{ $index } : $json{$hwnd}->[0];
}

sub iplayer_info 
{
	my $hwnd  = shift || die "No handle for player_info!\n";
	my $index = shift;

	if ( -e "tmp/player_info.$hwnd" )
	{
		$json{$hwnd} = from_json( read_file( "tmp/player_info.$hwnd" ) );
		unlink( "tmp/player_info.$hwnd" );
	}
	
	return {} unless $json{$hwnd};
	
	return $index ? $json{$hwnd}->[1]->[ $index ] : $json{$hwnd}->[1];
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
			1;
			# $record[6] =~ /(Accepted|Ready|Denied)/;

		
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
