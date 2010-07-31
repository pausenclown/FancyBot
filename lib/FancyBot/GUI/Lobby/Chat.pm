package FancyBot::GUI::Lobby::Chat;

use Moose::Role;
use Text::Diff;
use Data::Dumper;

has last_chatter => 
	isa     => 'Str',
	is      => 'rw',
	default => '';

sub send_chatter
{
	my $self = shift;
	return $self->get_control( 'ctbChat')->set_value( @_ );
}

sub new_chatter
{
	my $self    = shift;
	my $last    = $self->last_chatter; # print "\nWAS\n$last";
	my $chatter = $self->get_control('txtChat')->get_value; # print "\nNOW\n$chatter";
	my $diff    = diff \$last, \$chatter; substr( $diff, 0, index( $diff, chr(10) ) + 1 ) = ""; # print "\nDIFF\n$diff";

	my @new     = map { s/^\+//; $_ } grep { /^\+/ } split /\x0D\x0A/, $diff; 
	my $new     = join ("\x0D\x0A", @new); # print "\nNEW\n$new";
	
	$self->last_chatter( $chatter );

	return wantarray ? @new : $new;
}

1;
