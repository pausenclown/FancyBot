package Catalyst::Engine::CGI;

use Moose;
extends 'Catalyst::Engine';

has _header_buf => (is => 'rw', clearer => '_clear_header_buf', predicate => '_has_header_buf');

=head1 NAME

Catalyst::Engine::CGI - The CGI Engine

=head1 SYNOPSIS

A script using the Catalyst::Engine::CGI module might look like:

    #!/usr/bin/perl -w

    use strict;
    use lib '/path/to/MyApp/lib';
    use MyApp;

    MyApp->run;

The application module (C<MyApp>) would use C<Catalyst>, which loads the
appropriate engine module.

=head1 DESCRIPTION

This is the Catalyst engine specialized for the CGI environment.

=head1 PATH DECODING

Most web server environments pass the requested path to the application using environment variables,
from which Catalyst has to reconstruct the request base (i.e. the top level path to / in the application,
exposed as C<< $c->request->base >>) and the request path below that base.

There are two methods of doing this, both of which have advantages and disadvantages. Which method is used
is determined by the C<< $c->config(use_request_uri_for_path) >> setting (which can either be true or false).

=head2 use_request_uri_for_path => 0

This is the default (and the) traditional method that Catalyst has used for determining the path information.
The path is synthesised from a combination of the C<PATH_INFO> and C<SCRIPT_NAME> environment variables.
The allows the application to behave correctly when C<mod_rewrite> is being used to redirect requests
into the application, as these variables are adjusted by mod_rewrite to take account for the redirect.

However this method has the major disadvantage that it is impossible to correctly decode some elements
of the path, as RFC 3875 says: "C<< Unlike a URI path, the PATH_INFO is not URL-encoded, and cannot
contain path-segment parameters. >>" This means PATH_INFO is B<always> decoded, and therefore Catalyst
can't distinguish / vs %2F in paths (in addition to other encoded values).

=head2 use_request_uri_for_path => 1

This method uses the C<REQUEST_URI> and C<SCRIPT_NAME> environment variables. As C<REQUEST_URI> is never
decoded, this means that applications using this mode can correctly handle URIs including the %2F character
(i.e. with C<AllowEncodedSlashes> set to C<On> in Apache).

Given that this method of path resolution is provably more correct, it is recommended that you use
this unless you have a specific need to deploy your application in a non-standard environment, and you are
aware of the implications of not being able to handle encoded URI paths correctly.

However it also means that in a number of cases when the app isn't installed directly at a path, but instead
is having paths rewritten into it (e.g. as a .cgi/fcgi in a public_html directory, with mod_rewrite in a
.htaccess file, or when SSI is used to rewrite pages into the app, or when sub-paths of the app are exposed
at other URIs than that which the app is 'normally' based at with C<mod_rewrite>), the resolution of
C<< $c->request->base >> will be incorrect.

=head1 OVERLOADED METHODS

This class overloads some methods from C<Catalyst::Engine>.

=head2 $self->finalize_headers($c)

=cut

sub finalize_headers {
    my ( $self, $c ) = @_;

    $c->response->header( Status => $c->response->status );

    $self->_header_buf($c->response->headers->as_string("\015\012") . "\015\012");
}

=head2 $self->prepare_connection($c)

=cut

sub prepare_connection {
    my ( $self, $c ) = @_;
    local (*ENV) = $self->env || \%ENV;

    my $request = $c->request;
    $request->address( $ENV{REMOTE_ADDR} );

  PROXY_CHECK:
    {
        unless ( ref($c)->config->{using_frontend_proxy} ) {
            last PROXY_CHECK if $ENV{REMOTE_ADDR} ne '127.0.0.1';
            last PROXY_CHECK if ref($c)->config->{ignore_frontend_proxy};
        }
        last PROXY_CHECK unless $ENV{HTTP_X_FORWARDED_FOR};

        # If we are running as a backend server, the user will always appear
        # as 127.0.0.1. Select the most recent upstream IP (last in the list)
        my ($ip) = $ENV{HTTP_X_FORWARDED_FOR} =~ /([^,\s]+)$/;
        $request->address($ip);
        if ( defined $ENV{HTTP_X_FORWARDED_PORT} ) {
            $ENV{SERVER_PORT} = $ENV{HTTP_X_FORWARDED_PORT};
        }
    }

    $request->hostname( $ENV{REMOTE_HOST} ) if exists $ENV{REMOTE_HOST};
    $request->protocol( $ENV{SERVER_PROTOCOL} );
    $request->user( $ENV{REMOTE_USER} );  # XXX: Deprecated. See Catalyst::Request for removal information
    $request->remote_user( $ENV{REMOTE_USER} );
    $request->method( $ENV{REQUEST_METHOD} );

    if ( $ENV{HTTPS} && uc( $ENV{HTTPS} ) eq 'ON' ) {
        $request->secure(1);
    }

    if ( $ENV{SERVER_PORT} == 443 ) {
        $request->secure(1);
    }
    binmode(STDOUT); # Ensure we are sending bytes.
}

=head2 $self->prepare_headers($c)

=cut

sub prepare_headers {
    my ( $self, $c ) = @_;
    local (*ENV) = $self->env || \%ENV;
    my $headers = $c->request->headers;
    # Read headers from %ENV
    foreach my $header ( keys %ENV ) {
        next unless $header =~ /^(?:HTTP|CONTENT|COOKIE)/i;
        ( my $field = $header ) =~ s/^HTTPS?_//;
        $headers->header( $field => $ENV{$header} );
    }
}

=head2 $self->prepare_path($c)

=cut

# Please don't touch this method without adding tests in
# t/aggregate/unit_core_engine_cgi-prepare_path.t
sub prepare_path {
    my ( $self, $c ) = @_;
    local (*ENV) = $self->env || \%ENV;

    my $scheme = $c->request->secure ? 'https' : 'http';
    my $host      = $ENV{HTTP_HOST}   || $ENV{SERVER_NAME};
    my $port      = $ENV{SERVER_PORT} || 80;
    my $script_name = $ENV{SCRIPT_NAME};
    $script_name =~ s/([^$URI::uric])/$URI::Escape::escapes{$1}/go if $script_name;

    my $base_path;
    if ( exists $ENV{REDIRECT_URL} ) {
        $base_path = $ENV{REDIRECT_URL};
        $base_path =~ s/\Q$ENV{PATH_INFO}\E$//;
    }
    else {
        $base_path = $script_name || '/';
    }

    # If we are running as a backend proxy, get the true hostname
  PROXY_CHECK:
    {
        unless ( ref($c)->config->{using_frontend_proxy} ) {
            last PROXY_CHECK if $host !~ /localhost|127.0.0.1/;
            last PROXY_CHECK if ref($c)->config->{ignore_frontend_proxy};
        }
        last PROXY_CHECK unless $ENV{HTTP_X_FORWARDED_HOST};

        $host = $ENV{HTTP_X_FORWARDED_HOST};

        # backend could be on any port, so
        # assume frontend is on the default port
        $port = $c->request->secure ? 443 : 80;
        if ( $ENV{HTTP_X_FORWARDED_PORT} ) {
            $port = $ENV{HTTP_X_FORWARDED_PORT};
        }
    }

    my $path_info   = $ENV{PATH_INFO};
    if ($c->config->{use_request_uri_for_path}) {
        # RFC 3875: "Unlike a URI path, the PATH_INFO is not URL-encoded,
        # and cannot contain path-segment parameters." This means PATH_INFO
        # is always decoded, and the script can't distinguish / vs %2F.
        # See https://issues.apache.org/bugzilla/show_bug.cgi?id=35256
        # Here we try to resurrect the original encoded URI from REQUEST_URI.
        if (my $req_uri = $ENV{REQUEST_URI}) {
            if (defined $script_name) {
                $req_uri =~ s/^\Q$script_name\E//;
            }
            $req_uri =~ s/\?.*$//;
            $path_info = $req_uri if $req_uri;
        }
    }

    # set the request URI
    my $path = $base_path . ( $path_info || '' );
    $path =~ s{^/+}{};

    # Using URI directly is way too slow, so we construct the URLs manually
    my $uri_class = "URI::$scheme";

    # HTTP_HOST will include the port even if it's 80/443
    $host =~ s/:(?:80|443)$//;

    if ( $port !~ /^(?:80|443)$/ && $host !~ /:/ ) {
        $host .= ":$port";
    }

    # Escape the path
    $path =~ s/([^$URI::uric])/$URI::Escape::escapes{$1}/go;
    $path =~ s/\?/%3F/g; # STUPID STUPID SPECIAL CASE

    my $query = $ENV{QUERY_STRING} ? '?' . $ENV{QUERY_STRING} : '';
    my $uri   = $scheme . '://' . $host . '/' . $path . $query;

    $c->request->uri( bless(\$uri, $uri_class)->canonical );

    # set the base URI
    # base must end in a slash
    $base_path .= '/' unless $base_path =~ m{/$};

    my $base_uri = $scheme . '://' . $host . $base_path;

    $c->request->base( bless \$base_uri, $uri_class );
}

=head2 $self->prepare_query_parameters($c)

=cut

around prepare_query_parameters => sub {
    my $orig = shift;
    my ( $self, $c ) = @_;
    local (*ENV) = $self->env || \%ENV;

    if ( $ENV{QUERY_STRING} ) {
        $self->$orig( $c, $ENV{QUERY_STRING} );
    }
};

=head2 $self->prepare_request($c, (env => \%env))

=cut

sub prepare_request {
    my ( $self, $c, %args ) = @_;

    if ( $args{env} ) {
        $self->env( $args{env} );
    }
}

=head2 $self->prepare_write($c)

Enable autoflush on the output handle for CGI-based engines.

=cut

around prepare_write => sub {
    *STDOUT->autoflush(1);
    return shift->(@_);
};

=head2 $self->write($c, $buffer)

Writes the buffer to the client.

=cut

around write => sub {
    my $orig = shift;
    my ( $self, $c, $buffer ) = @_;

    # Prepend the headers if they have not yet been sent
    if ( $self->_has_header_buf ) {
        $buffer = $self->_clear_header_buf . $buffer;
    }

    return $self->$orig( $c, $buffer );
};

=head2 $self->read_chunk($c, $buffer, $length)

=cut

sub read_chunk { shift; shift; *STDIN->sysread(@_); }

=head2 $self->run

=cut

sub run { shift; shift->handle_request( env => \%ENV ) }

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Engine>

=head1 AUTHORS

Catalyst Contributors, see Catalyst.pm

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
no Moose;

1;
