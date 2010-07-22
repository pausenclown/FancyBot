package Catalyst::Restarter;

use Moose;

use Cwd qw( abs_path );
use File::ChangeNotify;
use File::Spec;
use FindBin;
use namespace::clean -except => 'meta';

has start_sub => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);

has argv =>  (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1,
);

has _watcher => (
    is  => 'rw',
    isa => 'File::ChangeNotify::Watcher',
);

has _filter => (
    is      => 'rw',
    isa     => 'RegexpRef',
);

has _child => (
    is  => 'rw',
    isa => 'Int',
);

sub pick_subclass {
    my $class = shift;

    my $subclass;
    $subclass =
        defined $ENV{CATALYST_RESTARTER}
            ? $ENV{CATALYST_RESTARTER}
            :  $^O eq 'MSWin32'
            ? 'Win32'
            : 'Forking';

    $subclass = 'Catalyst::Restarter::' . $subclass;

    eval "use $subclass";
    die $@ if $@;

    return $subclass;
}

sub BUILD {
    my $self = shift;
    my $p    = shift;

    delete $p->{start_sub};

    $p->{filter} ||= qr/(?:\/|^)(?![.#_]).+(?:\.yml$|\.yaml$|\.conf|\.pm)$/;

    my $app_root = abs_path( File::Spec->catdir( $FindBin::Bin, '..' ) );

    # Monitor application root dir
    $p->{directories} ||= $app_root;

    # exclude t/, root/ and hidden dirs
    $p->{exclude} ||= [
        File::Spec->catdir($app_root, 't'),
        File::Spec->catdir($app_root, 'root'),
        qr(/\.[^/]*/?$),    # match hidden dirs
    ];

    # keep filter regexp to make sure we don't restart on deleted
    # files or directories where we can't check -d
    $self->_filter( $p->{filter} );

    # We could make this lazily, but this lets us check that we
    # received valid arguments for the watcher up front.
    $self->_watcher( File::ChangeNotify->instantiate_watcher( %{$p} ) );
}

sub run_and_watch {
    my $self = shift;

    $self->_fork_and_start;

    return unless $self->_child;

    $self->_restart_on_changes;
}

sub _restart_on_changes {
    my $self = shift;

    # We use this loop in order to avoid having _handle_events() call back
    # into this method. We used to do that, and the end result was that stack
    # traces became longer and longer with every restart. Using this loop, the
    # portion of the stack trace that covers this code does not grow.
    while (1) {
        my @events = $self->_watcher->wait_for_events();
        $self->_handle_events(@events);
    }
}

sub _handle_events {
    my $self   = shift;
    my @events = @_;

    my @files;
    # Filter out any events which are the creation / deletion of directories
    # so that creating an empty directory won't cause a restart
    for my $event (@events) {
        my $path = $event->path();
        my $type = $event->type();
        if (   ( $type ne 'delete' && -f $path )
            || ( $type eq 'delete' && $path =~ $self->_filter ) )
        {
            push @files, { path => $path, type => $type };
        }
    }

    if (@files) {
        print STDERR "\n";
        print STDERR "Saw changes to the following files:\n";

        for my $f (@files) {
            my $path = $f->{path};
            my $type = $f->{type};
            print STDERR " - $path ($type)\n";
        }

        print STDERR "\n";
        print STDERR "Attempting to restart the server\n\n";

        $self->_kill_child;

        $self->_fork_and_start;
    }
}

sub DEMOLISH {
    my $self = shift;

    $self->_kill_child;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Catalyst::Restarter - Uses File::ChangeNotify to check for changed files and restart the server

=head1 SYNOPSIS

    my $class = Catalyst::Restarter->pick_subclass;

    my $restarter = $class->new(
        directories => '/path/to/MyApp',
        regex       => '\.yml$|\.yaml$|\.conf|\.pm$',
        start_sub => sub { ... }
    );

    $restarter->run_and_watch;

=head1 DESCRIPTION

This is the base class for all restarters, and it also provide
functionality for picking an appropriate restarter subclass for a
given platform.

This class uses L<File::ChangeNotify> to watch one or more directories
of files and restart the Catalyst server when any of those files
changes.

=head1 METHODS

=head2 pick_subclass

Returns the name of an appropriate subclass for the given platform.

=head2 new ( start_sub => sub { ... }, ... )

This method creates a new restarter object, but should be called on a
subclass, not this class.

The "start_sub" argument is required. This is a subroutine reference
that can be used to start the Catalyst server.

=head2 run_and_watch

This method forks, starts the server in a child process, and then
watched for changed files in the parent. When files change, it kills
the child, forks again, and starts a new server.

=head1 SEE ALSO

L<Catalyst>, L<File::ChangeNotify>

=head1 AUTHORS

Catalyst Contributors, see Catalyst.pm

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
