package Catalyst::View::TT;

use strict;
use warnings;

use base qw/Catalyst::View/;
use Data::Dump 'dump';
use Template;
use Template::Timer;
use MRO::Compat;
use Scalar::Util qw/blessed/;

our $VERSION = '0.34';

__PACKAGE__->mk_accessors('template');
__PACKAGE__->mk_accessors('include_path');

*paths = \&include_path;

=head1 NAME

Catalyst::View::TT - Template View Class

=head1 SYNOPSIS

# use the helper to create your View

    myapp_create.pl view TT TT

# configure in lib/MyApp.pm (Could be set from configfile instead)

    __PACKAGE__->config(
        name         => 'MyApp',
        root         => MyApp->path_to('root'),
        default_view => 'TT',
        'View::TT' => {
            # any TT configurations items go here
            INCLUDE_PATH => [
              MyApp->path_to( 'root', 'src' ),
              MyApp->path_to( 'root', 'lib' ),
            ],
            TEMPLATE_EXTENSION => '.tt',
            CATALYST_VAR => 'c',
            TIMER        => 0,
            # Not set by default
            PRE_PROCESS        => 'config/main',
            WRAPPER            => 'site/wrapper',
            render_die => 1, # Default for new apps, see render method docs
        },
    );

# render view from lib/MyApp.pm or lib/MyApp::Controller::SomeController.pm

    sub message : Global {
        my ( $self, $c ) = @_;
        $c->stash->{template} = 'message.tt2';
        $c->stash->{message}  = 'Hello World!';
        $c->forward( $c->view('TT') );
    }

# access variables from template

    The message is: [% message %].

    # example when CATALYST_VAR is set to 'Catalyst'
    Context is [% Catalyst %]
    The base is [% Catalyst.req.base %]
    The name is [% Catalyst.config.name %]

    # example when CATALYST_VAR isn't set
    Context is [% c %]
    The base is [% base %]
    The name is [% name %]

=cut

sub _coerce_paths {
    my ( $paths, $dlim ) = shift;
    return () if ( !$paths );
    return @{$paths} if ( ref $paths eq 'ARRAY' );

    # tweak delim to ignore C:/
    unless ( defined $dlim ) {
        $dlim = ( $^O eq 'MSWin32' ) ? ':(?!\\/)' : ':';
    }
    return split( /$dlim/, $paths );
}

sub new {
    my ( $class, $c, $arguments ) = @_;
    my $config = {
        EVAL_PERL          => 0,
        TEMPLATE_EXTENSION => '',
        %{ $class->config },
        %{$arguments},
    };
    if ( ! (ref $config->{INCLUDE_PATH} eq 'ARRAY') ) {
        my $delim = $config->{DELIMITER};
        my @include_path
            = _coerce_paths( $config->{INCLUDE_PATH}, $delim );
        if ( !@include_path ) {
            my $root = $c->config->{root};
            my $base = Path::Class::dir( $root, 'base' );
            @include_path = ( "$root", "$base" );
        }
        $config->{INCLUDE_PATH} = \@include_path;
    }

    # if we're debugging and/or the TIMER option is set, then we install
    # Template::Timer as a custom CONTEXT object, but only if we haven't
    # already got a custom CONTEXT defined

    if ( $config->{TIMER} ) {
        if ( $config->{CONTEXT} ) {
            $c->log->error(
                'Cannot use Template::Timer - a TT CONTEXT is already defined'
            );
        }
        else {
            $config->{CONTEXT} = Template::Timer->new(%$config);
        }
    }

    if ( $c->debug && $config->{DUMP_CONFIG} ) {
        $c->log->debug( "TT Config: ", dump($config) );
    }

    my $self = $class->next::method(
        $c, { %$config },
    );

    # Set base include paths. Local'd in render if needed
    $self->include_path($config->{INCLUDE_PATH});

    $self->config($config);

    # Creation of template outside of call to new so that we can pass [ $self ]
    # as INCLUDE_PATH config item, which then gets ->paths() called to get list
    # of include paths to search for templates.

    # Use a weakend copy of self so we dont have loops preventing GC from working
    my $copy = $self;
    Scalar::Util::weaken($copy);
    $config->{INCLUDE_PATH} = [ sub { $copy->paths } ];

    if ( $config->{PROVIDERS} ) {
        my @providers = ();
        if ( ref($config->{PROVIDERS}) eq 'ARRAY') {
            foreach my $p (@{$config->{PROVIDERS}}) {
                my $pname = $p->{name};
                my $prov = 'Template::Provider';
                if($pname eq '_file_')
                {
                    $p->{args} = { %$config };
                }
                else
                {
                    if($pname =~ s/^\+//) {
                        $prov = $pname;
                    }
                    else
                    {
                        $prov .= "::$pname";
                    }
                    # We copy the args people want from the config
                    # to the args
                    $p->{args} ||= {};
                    if ($p->{copy_config}) {
                        map  { $p->{args}->{$_} = $config->{$_}  }
                                   grep { exists $config->{$_} }
                                   @{ $p->{copy_config} };
                    }
                }
                local $@;
                eval "require $prov";
                if(!$@) {
                    push @providers, "$prov"->new($p->{args});
                }
                else
                {
                    $c->log->warn("Can't load $prov, ($@)");
                }
            }
        }
        delete $config->{PROVIDERS};
        if(@providers) {
            $config->{LOAD_TEMPLATES} = \@providers;
        }
    }

    $self->{template} =
        Template->new($config) || do {
            my $error = Template->error();
            $c->log->error($error);
            $c->error($error);
            return undef;
        };


    return $self;
}

sub process {
    my ( $self, $c ) = @_;

    my $template = $c->stash->{template}
      ||  $c->action . $self->config->{TEMPLATE_EXTENSION};

    unless (defined $template) {
        $c->log->debug('No template specified for rendering') if $c->debug;
        return 0;
    }

    local $@;
    my $output = eval { $self->render($c, $template) };
    if (my $err = $@) {
        return $self->_rendering_error($c, $err);
    }
    if (blessed($output) && $output->isa('Template::Exception')) {
        $self->_rendering_error($c, $output);
    }

    unless ( $c->response->content_type ) {
        $c->response->content_type('text/html; charset=utf-8');
    }

    $c->response->body($output);

    return 1;
}

sub _rendering_error {
    my ($self, $c, $err) = @_;
    my $error = qq/Couldn't render template "$err"/;
    $c->log->error($error);
    $c->error($error);
    return 0;
}

sub render {
    my ($self, $c, $template, $args) = @_;

    $c->log->debug(qq/Rendering template "$template"/) if $c && $c->debug;

    my $output;
    my $vars = {
        (ref $args eq 'HASH' ? %$args : %{ $c->stash() }),
        $self->template_vars($c)
    };

    local $self->{include_path} =
        [ @{ $vars->{additional_template_paths} }, @{ $self->{include_path} } ]
        if ref $vars->{additional_template_paths};

    unless ( $self->template->process( $template, $vars, \$output ) ) {
        if (exists $self->{render_die}) {
            die $self->template->error if $self->{render_die};
            return $self->template->error;
        }
        $c->log->debug('The Catalyst::View::TT render() method of will die on error in a future release. Unless you are calling the render() method manually, you probably want the new behaviour, so set render_die => 1 in config for ' . blessed($self) . '. If you are calling the render() method manually and you wish it to continue to return the exception rather than throwing it, add render_die => 0 to your config.') if $c->debug;
        return $self->template->error;
    }
    return $output;
}

sub template_vars {
    my ( $self, $c ) = @_;

    return  () unless $c;
    my $cvar = $self->config->{CATALYST_VAR};

    defined $cvar
      ? ( $cvar => $c )
      : (
        c    => $c,
        base => $c->req->base,
        name => $c->config->{name}
      )
}


1;

__END__

=head1 DESCRIPTION

This is the Catalyst view class for the L<Template Toolkit|Template>.
Your application should defined a view class which is a subclass of
this module.  The easiest way to achieve this is using the
F<myapp_create.pl> script (where F<myapp> should be replaced with
whatever your application is called).  This script is created as part
of the Catalyst setup.

    $ script/myapp_create.pl view TT TT

This creates a MyApp::View::TT.pm module in the F<lib> directory (again,
replacing C<MyApp> with the name of your application) which looks
something like this:

    package FooBar::View::TT;

    use strict;
    use warnings;

    use base 'Catalyst::View::TT';

    __PACKAGE__->config(DEBUG => 'all');

Now you can modify your action handlers in the main application and/or
controllers to forward to your view class.  You might choose to do this
in the end() method, for example, to automatically forward all actions
to the TT view class.

    # In MyApp or MyApp::Controller::SomeController

    sub end : Private {
        my( $self, $c ) = @_;
        $c->forward( $c->view('TT') );
    }

But if you are using the standard auto-generated end action, you don't even need
to do this!

    # in MyApp::Controller::Root
    sub end : ActionClass('RenderView') {} # no need to change this line

    # in MyApp.pm
    __PACKAGE__->config(
        ...
        default_view => 'TT',
    );

This will Just Work.  And it has the advantages that:

=over 4

=item *

If you want to use a different view for a given request, just set 
<< $c->stash->{current_view} >>.  (See L<Catalyst>'s C<< $c->view >> method
for details.

=item *

<< $c->res->redirect >> is handled by default.  If you just forward to 
C<View::TT> in your C<end> routine, you could break this by sending additional
content.

=back

See L<Catalyst::Action::RenderView> for more details.

=head2 CONFIGURATION

There are a three different ways to configure your view class.  The
first way is to call the C<config()> method in the view subclass.  This
happens when the module is first loaded.

    package MyApp::View::TT;

    use strict;
    use base 'Catalyst::View::TT';

    MyApp::View::TT->config({
        INCLUDE_PATH => [
            MyApp->path_to( 'root', 'templates', 'lib' ),
            MyApp->path_to( 'root', 'templates', 'src' ),
        ],
        PRE_PROCESS  => 'config/main',
        WRAPPER      => 'site/wrapper',
    });

The second way is to define a C<new()> method in your view subclass.
This performs the configuration when the view object is created,
shortly after being loaded.  Remember to delegate to the base class
C<new()> method (via C<$self-E<gt>next::method()> in the example below) after
performing any configuration.

    sub new {
        my $self = shift;
        $self->config({
            INCLUDE_PATH => [
                MyApp->path_to( 'root', 'templates', 'lib' ),
                MyApp->path_to( 'root', 'templates', 'src' ),
            ],
            PRE_PROCESS  => 'config/main',
            WRAPPER      => 'site/wrapper',
        });
        return $self->next::method(@_);
    }

The final, and perhaps most direct way, is to define a class
item in your main application configuration, again by calling the
ubiquitous C<config()> method.  The items in the class hash are
added to those already defined by the above two methods.  This happens
in the base class new() method (which is one reason why you must
remember to call it via C<MRO::Compat> if you redefine the C<new()>
method in a subclass).

    package MyApp;

    use strict;
    use Catalyst;

    MyApp->config({
        name     => 'MyApp',
        root     => MyApp->path_to('root'),
        'View::TT' => {
            INCLUDE_PATH => [
                MyApp->path_to( 'root', 'templates', 'lib' ),
                MyApp->path_to( 'root', 'templates', 'src' ),
            ],
            PRE_PROCESS  => 'config/main',
            WRAPPER      => 'site/wrapper',
        },
    });

Note that any configuration items defined by one of the earlier
methods will be overwritten by items of the same name provided by the
latter methods.

=head2 DYNAMIC INCLUDE_PATH

Sometimes it is desirable to modify INCLUDE_PATH for your templates at run time.

Additional paths can be added to the start of INCLUDE_PATH via the stash as
follows:

    $c->stash->{additional_template_paths} =
        [$c->config->{root} . '/test_include_path'];

If you need to add paths to the end of INCLUDE_PATH, there is also an
include_path() accessor available:

    push( @{ $c->view('TT')->include_path }, qw/path/ );

Note that if you use include_path() to add extra paths to INCLUDE_PATH, you
MUST check for duplicate paths. Without such checking, the above code will add
"path" to INCLUDE_PATH at every request, causing a memory leak.

A safer approach is to use include_path() to overwrite the array of paths
rather than adding to it. This eliminates both the need to perform duplicate
checking and the chance of a memory leak:

    @{ $c->view('TT')->include_path } = qw/path another_path/;

If you are calling C<render> directly then you can specify dynamic paths by
having a C<additional_template_paths> key with a value of additonal directories
to search. See L<CAPTURING TEMPLATE OUTPUT> for an example showing this.

=head2 RENDERING VIEWS

The view plugin renders the template specified in the C<template>
item in the stash.

    sub message : Global {
        my ( $self, $c ) = @_;
        $c->stash->{template} = 'message.tt2';
        $c->forward( $c->view('TT') );
    }

If a stash item isn't defined, then it instead uses the
stringification of the action dispatched to (as defined by $c->action)
in the above example, this would be C<message>, but because the default
is to append '.tt', it would load C<root/message.tt>.

The items defined in the stash are passed to the Template Toolkit for
use as template variables.

    sub default : Private {
        my ( $self, $c ) = @_;
        $c->stash->{template} = 'message.tt2';
        $c->stash->{message}  = 'Hello World!';
        $c->forward( $c->view('TT') );
    }

A number of other template variables are also added:

    c      A reference to the context object, $c
    base   The URL base, from $c->req->base()
    name   The application name, from $c->config->{ name }

These can be accessed from the template in the usual way:

<message.tt2>:

    The message is: [% message %]
    The base is [% base %]
    The name is [% name %]


The output generated by the template is stored in C<< $c->response->body >>.

=head2 CAPTURING TEMPLATE OUTPUT

If you wish to use the output of a template for some other purpose than
displaying in the response, e.g. for sending an email, this is possible using
L<Catalyst::Plugin::Email> and the L<render> method:

  sub send_email : Local {
    my ($self, $c) = @_;

    $c->email(
      header => [
        To      => 'me@localhost',
        Subject => 'A TT Email',
      ],
      body => $c->view('TT')->render($c, 'email.tt', {
        additional_template_paths => [ $c->config->{root} . '/email_templates'],
        email_tmpl_param1 => 'foo'
        }
      ),
    );
  # Redirect or display a message
  }

=head2 TEMPLATE PROFILING

See L<C<TIMER>> property of the L<config> method.

=head2 METHODS

=head2 new

The constructor for the TT view. Sets up the template provider,
and reads the application config.

=head2 process($c)

Renders the template specified in C<< $c->stash->{template} >> or
C<< $c->action >> (the private name of the matched action).  Calls L<render> to
perform actual rendering. Output is stored in C<< $c->response->body >>.

It is possible to forward to the process method of a TT view from inside
Catalyst like this:

    $c->forward('View::TT');

N.B. This is usually done automatically by L<Catalyst::Action::RenderView>.

=head2 render($c, $template, \%args)

Renders the given template and returns output. Throws a L<Template::Exception>
object upon error.

The template variables are set to C<%$args> if $args is a hashref, or
$C<< $c->stash >> otherwise. In either case the variables are augmented with
C<base> set to C< << $c->req->base >>, C<c> to C<$c> and C<name> to
C<< $c->config->{name} >>. Alternately, the C<CATALYST_VAR> configuration item
can be defined to specify the name of a template variable through which the
context reference (C<$c>) can be accessed. In this case, the C<c>, C<base> and
C<name> variables are omitted.

C<$template> can be anything that Template::process understands how to
process, including the name of a template file or a reference to a test string.
See L<Template::process|Template/process> for a full list of supported formats.

To use the render method outside of your Catalyst app, just pass a undef context.
This can be useful for tests, for instance.

It is possible to forward to the render method of a TT view from inside Catalyst
to render page fragments like this:

    my $fragment = $c->forward("View::TT", "render", $template_name, $c->stash->{fragment_data});

=head3 Backwards compatibility note

The render method used to just return the Template::Exception object, rather
than just throwing it. This is now deprecated and instead the render method
will throw an exception for new applications.

This behaviour can be activated (and is activated in the default skeleton
configuration) by using C<< render_die => 1 >>. If you rely on the legacy
behaviour then a warning will be issued.

To silence this warning, set C<< render_die => 0 >>, but it is recommended
you adjust your code so that it works with C<< render_die => 1 >>.

In a future release, C<< render_die => 1 >> will become the default if
unspecified.

=head2 template_vars

Returns a list of keys/values to be used as the catalyst variables in the
template.

=head2 config

This method allows your view subclass to pass additional settings to
the TT configuration hash, or to set the options as below:

=head2 paths

The list of paths TT will look for templates in.

=head2 C<CATALYST_VAR>

Allows you to change the name of the Catalyst context object. If set, it will also
remove the base and name aliases, so you will have access them through <context>.

For example:

    MyApp->config({
        name     => 'MyApp',
        root     => MyApp->path_to('root'),
        'View::TT' => {
            CATALYST_VAR => 'Catalyst',
        },
    });

F<message.tt2>:

    The base is [% Catalyst.req.base %]
    The name is [% Catalyst.config.name %]

=head2 C<TIMER>

If you have configured Catalyst for debug output, and turned on the TIMER setting,
C<Catalyst::View::TT> will enable profiling of template processing
(using L<Template::Timer>). This will embed HTML comments in the
output from your templates, such as:

    <!-- TIMER START: process mainmenu/mainmenu.ttml -->
    <!-- TIMER START: include mainmenu/cssindex.tt -->
    <!-- TIMER START: process mainmenu/cssindex.tt -->
    <!-- TIMER END: process mainmenu/cssindex.tt (0.017279 seconds) -->
    <!-- TIMER END: include mainmenu/cssindex.tt (0.017401 seconds) -->

    ....

    <!-- TIMER END: process mainmenu/footer.tt (0.003016 seconds) -->


=head2 C<TEMPLATE_EXTENSION>

a sufix to add when looking for templates bases on the C<match> method in L<Catalyst::Request>.

For example:

  package MyApp::Controller::Test;
  sub test : Local { .. }

Would by default look for a template in <root>/test/test. If you set TEMPLATE_EXTENSION to '.tt', it will look for
<root>/test/test.tt.

=head2 C<PROVIDERS>

Allows you to specify the template providers that TT will use.

    MyApp->config({
        name     => 'MyApp',
        root     => MyApp->path_to('root'),
        'View::TT' => {
            PROVIDERS => [
                {
                    name    => 'DBI',
                    args    => {
                        DBI_DSN => 'dbi:DB2:books',
                        DBI_USER=> 'foo'
                    }
                }, {
                    name    => '_file_',
                    args    => {}
                }
            ]
        },
    });

The 'name' key should correspond to the class name of the provider you
want to use.  The _file_ name is a special case that represents the default
TT file-based provider.  By default the name is will be prefixed with
'Template::Provider::'.  You can fully qualify the name by using a unary
plus:

    name => '+MyApp::Provider::Foo'

You can also specify the 'copy_config' key as an arrayref, to copy those keys
from the general config, into the config for the provider:

    DEFAULT_ENCODING    => 'utf-8',
    PROVIDERS => [
        {
            name    => 'Encoding',
            copy_config => [qw(DEFAULT_ENCODING INCLUDE_PATH)]
        }
    ]

This can prove useful when you want to use the additional_template_paths hack
in your own provider, or if you need to use Template::Provider::Encoding

=head2 HELPERS

The L<Catalyst::Helper::View::TT> and
L<Catalyst::Helper::View::TTSite> helper modules are provided to create
your view module.  There are invoked by the F<myapp_create.pl> script:

    $ script/myapp_create.pl view TT TT

    $ script/myapp_create.pl view TT TTSite

The L<Catalyst::Helper::View::TT> module creates a basic TT view
module.  The L<Catalyst::Helper::View::TTSite> module goes a little
further.  It also creates a default set of templates to get you
started.  It also configures the view module to locate the templates
automatically.

=head1 NOTES

If you are using the L<CGI> module inside your templates, you will
experience that the Catalyst server appears to hang while rendering
the web page. This is due to the debug mode of L<CGI> (which is
waiting for input in the terminal window). Turning off the
debug mode using the "-no_debug" option solves the
problem, eg.:

    [% USE CGI('-no_debug') %]

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Helper::View::TT>,
L<Catalyst::Helper::View::TTSite>, L<Template::Manual>

=head1 AUTHORS

Sebastian Riedel, C<sri@cpan.org>

Marcus Ramberg, C<mramberg@cpan.org>

Jesse Sheidlower, C<jester@panix.com>

Andy Wardley, C<abw@cpan.org>

=head1 COPYRIGHT

This program is free software. You can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
