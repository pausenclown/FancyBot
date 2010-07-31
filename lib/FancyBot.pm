package FancyBot;

use Moose;

use FancyBot::GUI;

with 'FancyBot::Events';
with 'FancyBot::Commands';
with 'FancyBot::StartStop';
with 'FancyBot::UserHandling';
with 'FancyBot::BotHandling';

our $VERSION = 0.03;

# holds a reference to an object that represent the current screen of
# the dedicated server process
has screen =>
	isa     => 'FancyBot::GUI',
	is      => 'rw';

# config data as per server.ini
has config =>
	isa     => 'HashRef',
	is      => 'ro',
	default => sub {{}};

# user data
has users =>
	isa     => 'HashRef',
	is      => 'ro',
	default => sub {{}};
	
# holds a reference to an Hash of Arrays; The keys being event names, the 
# latter holding references to listening subroutines
has listeners =>
	isa     => 'HashRef',
	is      => 'ro',
	default => sub {{}};

has plugin_stash =>
	isa     => 'HashRef',
	is      => 'ro',
	default => sub {{}};

# the numeric window handle of the main window
# the dedicated server process
has main_hwnd => 
	isa     => 'Int',
	is      => 'rw',
	default => 0;
	
# time of server start
has server_start_time => 
	isa     => 'Int',
	is      => 'rw',
	default => 0;

# Perl Object, representing the dedicated server process
has server_proc => 
	isa     => 'Win32::Process',
	is      => 'rw';

# flag to control the main runloop
has keep_running =>
	isa     => 'Bool',
	is      => 'rw',
	default => 1;


# Find the handle of the main Dedicated Server window and return it	
sub find_main_hwnd
{
	return (FancyBot::GUI::FindWindowLike(0, 'MechWarrior 4 Mercenaries Win32Dedicated Server'))[0];
}

# Returns wether a Dedicated Server is running or not
sub is_server_alive
{
	my $self = shift;
	return $self->find_main_hwnd ? 1 : 0;
}


sub window_dump
{
	my $self = shift;
	my $hwnd = shift || $self->main_hwnd;
	
	my $i = 0;
	print '-' x 60, "\n";
	print "confess: $hwnd\n";
	print 'SourceHandle: ', $hwnd, ", Text: ", FancyBot::GUI::WMGetText($hwnd), ', Class: ', FancyBot::GUI::GetClassName($hwnd), "\n" ;
	for ( FancyBot::GUI::GetChildWindows($hwnd) ) { 
		print $i++, ' ', $hwnd, ", Text: ", FancyBot::GUI::WMGetText($_), ', Class: ', FancyBot::GUI::GetClassName($_), "\n" ;
	}	
	print '-' x 60, "\n";
}

sub in_game 
{
	return shift->screen->in_game;
}

sub send_chatter 
{
	return shift->screen->send_chatter( @_ );
}

sub update_gui
{
	my $self = shift;
	$self->screen->update_gui
}

=head1 NAME

FancyBot - A control bot for the Mechwarrior 4 dedicated server!

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Nothing to see here, go away.

Or better,

Read the code, Luke!

=head1 EXPORT

=head1 AUTHOR

Tailgunner, C<< <tailgunner at somewhere.com> >>

=cut

1;
		