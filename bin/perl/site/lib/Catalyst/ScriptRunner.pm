package Catalyst::ScriptRunner;
use Moose;
use FindBin;
use lib;
use File::Spec;
use namespace::autoclean;

sub run {
    my ($self, $class, $scriptclass) = @_;
    my $classtoload = "${class}::Script::$scriptclass";

    lib->import(File::Spec->catdir($FindBin::Bin, '..', 'lib'));

    unless ( eval { Class::MOP::load_class($classtoload) } ) {
        warn("Could not load $classtoload - falling back to Catalyst::Script::$scriptclass : $@\n")
            if $@ !~ /Can't locate/;
        $classtoload = "Catalyst::Script::$scriptclass";
        Class::MOP::load_class($classtoload);
    }
    $classtoload->new_with_options( application_name => $class )->run;
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Catalyst::ScriptRunner - The Catalyst Framework script runner

=head1 SYNOPSIS

    # Will run MyApp::Script::Server if it exists, otherwise
    # will run Catalyst::Script::Server.
    Catalyst::ScriptRunner->run('MyApp', 'Server');

=head1 DESCRIPTION

This class is responsible for running scripts, either in the application specific namespace
(e.g. C<MyApp::Script::Server>), or the Catalyst namespace (e.g. C<Catalyst::Script::Server>)

=head1 METHODS

=head2 run ($application_class, $scriptclass)

Called with two parameters, the application classs (e.g. MyApp)
and the script class, (i.e. one of Server/FastCGI/CGI/Create/Test)

=head1 AUTHORS

Catalyst Contributors, see Catalyst.pm

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
