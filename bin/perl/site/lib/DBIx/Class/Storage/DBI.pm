package DBIx::Class::Storage::DBI;
# -*- mode: cperl; cperl-indent-level: 2 -*-

use strict;
use warnings;

use base qw/DBIx::Class::Storage::DBIHacks DBIx::Class::Storage/;
use mro 'c3';

use Carp::Clan qw/^DBIx::Class/;
use DBI;
use DBIx::Class::Storage::DBI::Cursor;
use DBIx::Class::Storage::Statistics;
use Scalar::Util qw/refaddr weaken reftype blessed/;
use Data::Dumper::Concise 'Dumper';
use Sub::Name 'subname';
use Try::Tiny;
use File::Path 'make_path';
use namespace::clean;

__PACKAGE__->mk_group_accessors('simple' => qw/
  _connect_info _dbi_connect_info _dbic_connect_attributes _driver_determined
  _dbh _server_info_hash _conn_pid _conn_tid _sql_maker _sql_maker_opts
  transaction_depth _dbh_autocommit  savepoints
/);

# the values for these accessors are picked out (and deleted) from
# the attribute hashref passed to connect_info
my @storage_options = qw/
  on_connect_call on_disconnect_call on_connect_do on_disconnect_do
  disable_sth_caching unsafe auto_savepoint
/;
__PACKAGE__->mk_group_accessors('simple' => @storage_options);


# default cursor class, overridable in connect_info attributes
__PACKAGE__->cursor_class('DBIx::Class::Storage::DBI::Cursor');

__PACKAGE__->mk_group_accessors('inherited' => qw/
  sql_maker_class
  _supports_insert_returning
/);
__PACKAGE__->sql_maker_class('DBIx::Class::SQLAHacks');

# Each of these methods need _determine_driver called before itself
# in order to function reliably. This is a purely DRY optimization
my @rdbms_specific_methods = qw/
  deployment_statements
  sqlt_type
  sql_maker
  build_datetime_parser
  datetime_parser_type

  insert
  insert_bulk
  update
  delete
  select
  select_single
/;

for my $meth (@rdbms_specific_methods) {

  my $orig = __PACKAGE__->can ($meth)
    or next;

  no strict qw/refs/;
  no warnings qw/redefine/;
  *{__PACKAGE__ ."::$meth"} = subname $meth => sub {
    if (not $_[0]->_driver_determined) {
      $_[0]->_determine_driver;
      goto $_[0]->can($meth);
    }
    $orig->(@_);
  };
}


=head1 NAME

DBIx::Class::Storage::DBI - DBI storage handler

=head1 SYNOPSIS

  my $schema = MySchema->connect('dbi:SQLite:my.db');

  $schema->storage->debug(1);

  my @stuff = $schema->storage->dbh_do(
    sub {
      my ($storage, $dbh, @args) = @_;
      $dbh->do("DROP TABLE authors");
    },
    @column_list
  );

  $schema->resultset('Book')->search({
     written_on => $schema->storage->datetime_parser->format_datetime(DateTime->now)
  });

=head1 DESCRIPTION

This class represents the connection to an RDBMS via L<DBI>.  See
L<DBIx::Class::Storage> for general information.  This pod only
documents DBI-specific methods and behaviors.

=head1 METHODS

=cut

sub new {
  my $new = shift->next::method(@_);

  $new->transaction_depth(0);
  $new->_sql_maker_opts({});
  $new->{savepoints} = [];
  $new->{_in_dbh_do} = 0;
  $new->{_dbh_gen} = 0;

  # read below to see what this does
  $new->_arm_global_destructor;

  $new;
}

# This is hack to work around perl shooting stuff in random
# order on exit(). If we do not walk the remaining storage
# objects in an END block, there is a *small but real* chance
# of a fork()ed child to kill the parent's shared DBI handle,
# *before perl reaches the DESTROY in this package*
# Yes, it is ugly and effective.
{
  my %seek_and_destroy;

  sub _arm_global_destructor {
    my $self = shift;
    my $key = Scalar::Util::refaddr ($self);
    $seek_and_destroy{$key} = $self;
    Scalar::Util::weaken ($seek_and_destroy{$key});
  }

  END {
    local $?; # just in case the DBI destructor changes it somehow

    # destroy just the object if not native to this process/thread
    $_->_preserve_foreign_dbh for (grep
      { defined $_ }
      values %seek_and_destroy
    );
  }
}

sub DESTROY {
  my $self = shift;

  # destroy just the object if not native to this process/thread
  $self->_preserve_foreign_dbh;

  # some databases need this to stop spewing warnings
  if (my $dbh = $self->_dbh) {
    try {
      %{ $dbh->{CachedKids} } = ();
      $dbh->disconnect;
    };
  }

  $self->_dbh(undef);
}

sub _preserve_foreign_dbh {
  my $self = shift;

  return unless $self->_dbh;

  $self->_verify_tid;

  return unless $self->_dbh;

  $self->_verify_pid;

}

# handle pid changes correctly - do not destroy parent's connection
sub _verify_pid {
  my $self = shift;

  return if ( defined $self->_conn_pid and $self->_conn_pid == $$ );

  $self->_dbh->{InactiveDestroy} = 1;
  $self->_dbh(undef);
  $self->{_dbh_gen}++;

  return;
}

# very similar to above, but seems to FAIL if I set InactiveDestroy
sub _verify_tid {
  my $self = shift;

  if ( ! defined $self->_conn_tid ) {
    return; # no threads
  }
  elsif ( $self->_conn_tid == threads->tid ) {
    return; # same thread
  }

  #$self->_dbh->{InactiveDestroy} = 1;  # why does t/51threads.t fail...?
  $self->_dbh(undef);
  $self->{_dbh_gen}++;

  return;
}


=head2 connect_info

This method is normally called by L<DBIx::Class::Schema/connection>, which
encapsulates its argument list in an arrayref before passing them here.

The argument list may contain:

=over

=item *

The same 4-element argument set one would normally pass to
L<DBI/connect>, optionally followed by
L<extra attributes|/DBIx::Class specific connection attributes>
recognized by DBIx::Class:

  $connect_info_args = [ $dsn, $user, $password, \%dbi_attributes?, \%extra_attributes? ];

=item *

A single code reference which returns a connected
L<DBI database handle|DBI/connect> optionally followed by
L<extra attributes|/DBIx::Class specific connection attributes> recognized
by DBIx::Class:

  $connect_info_args = [ sub { DBI->connect (...) }, \%extra_attributes? ];

=item *

A single hashref with all the attributes and the dsn/user/password
mixed together:

  $connect_info_args = [{
    dsn => $dsn,
    user => $user,
    password => $pass,
    %dbi_attributes,
    %extra_attributes,
  }];

  $connect_info_args = [{
    dbh_maker => sub { DBI->connect (...) },
    %dbi_attributes,
    %extra_attributes,
  }];

This is particularly useful for L<Catalyst> based applications, allowing the
following config (L<Config::General> style):

  <Model::DB>
    schema_class   App::DB
    <connect_info>
      dsn          dbi:mysql:database=test
      user         testuser
      password     TestPass
      AutoCommit   1
    </connect_info>
  </Model::DB>

The C<dsn>/C<user>/C<password> combination can be substituted by the
C<dbh_maker> key whose value is a coderef that returns a connected
L<DBI database handle|DBI/connect>

=back

Please note that the L<DBI> docs recommend that you always explicitly
set C<AutoCommit> to either I<0> or I<1>.  L<DBIx::Class> further
recommends that it be set to I<1>, and that you perform transactions
via our L<DBIx::Class::Schema/txn_do> method.  L<DBIx::Class> will set it
to I<1> if you do not do explicitly set it to zero.  This is the default
for most DBDs. See L</DBIx::Class and AutoCommit> for details.

=head3 DBIx::Class specific connection attributes

In addition to the standard L<DBI|DBI/ATTRIBUTES_COMMON_TO_ALL_HANDLES>
L<connection|DBI/Database_Handle_Attributes> attributes, DBIx::Class recognizes
the following connection options. These options can be mixed in with your other
L<DBI> connection attributes, or placed in a separate hashref
(C<\%extra_attributes>) as shown above.

Every time C<connect_info> is invoked, any previous settings for
these options will be cleared before setting the new ones, regardless of
whether any options are specified in the new C<connect_info>.


=over

=item on_connect_do

Specifies things to do immediately after connecting or re-connecting to
the database.  Its value may contain:

=over

=item a scalar

This contains one SQL statement to execute.

=item an array reference

This contains SQL statements to execute in order.  Each element contains
a string or a code reference that returns a string.

=item a code reference

This contains some code to execute.  Unlike code references within an
array reference, its return value is ignored.

=back

=item on_disconnect_do

Takes arguments in the same form as L</on_connect_do> and executes them
immediately before disconnecting from the database.

Note, this only runs if you explicitly call L</disconnect> on the
storage object.

=item on_connect_call

A more generalized form of L</on_connect_do> that calls the specified
C<connect_call_METHOD> methods in your storage driver.

  on_connect_do => 'select 1'

is equivalent to:

  on_connect_call => [ [ do_sql => 'select 1' ] ]

Its values may contain:

=over

=item a scalar

Will call the C<connect_call_METHOD> method.

=item a code reference

Will execute C<< $code->($storage) >>

=item an array reference

Each value can be a method name or code reference.

=item an array of arrays

For each array, the first item is taken to be the C<connect_call_> method name
or code reference, and the rest are parameters to it.

=back

Some predefined storage methods you may use:

=over

=item do_sql

Executes a SQL string or a code reference that returns a SQL string. This is
what L</on_connect_do> and L</on_disconnect_do> use.

It can take:

=over

=item a scalar

Will execute the scalar as SQL.

=item an arrayref

Taken to be arguments to L<DBI/do>, the SQL string optionally followed by the
attributes hashref and bind values.

=item a code reference

Will execute C<< $code->($storage) >> and execute the return array refs as
above.

=back

=item datetime_setup

Execute any statements necessary to initialize the database session to return
and accept datetime/timestamp values used with
L<DBIx::Class::InflateColumn::DateTime>.

Only necessary for some databases, see your specific storage driver for
implementation details.

=back

=item on_disconnect_call

Takes arguments in the same form as L</on_connect_call> and executes them
immediately before disconnecting from the database.

Calls the C<disconnect_call_METHOD> methods as opposed to the
C<connect_call_METHOD> methods called by L</on_connect_call>.

Note, this only runs if you explicitly call L</disconnect> on the
storage object.

=item disable_sth_caching

If set to a true value, this option will disable the caching of
statement handles via L<DBI/prepare_cached>.

=item limit_dialect

Sets the limit dialect. This is useful for JDBC-bridge among others
where the remote SQL-dialect cannot be determined by the name of the
driver alone. See also L<SQL::Abstract::Limit>.

=item quote_char

Specifies what characters to use to quote table and column names. If
you use this you will want to specify L</name_sep> as well.

C<quote_char> expects either a single character, in which case is it
is placed on either side of the table/column name, or an arrayref of length
2 in which case the table/column name is placed between the elements.

For example under MySQL you should use C<< quote_char => '`' >>, and for
SQL Server you should use C<< quote_char => [qw/[ ]/] >>.

=item name_sep

This only needs to be used in conjunction with C<quote_char>, and is used to
specify the character that separates elements (schemas, tables, columns) from
each other. In most cases this is simply a C<.>.

The consequences of not supplying this value is that L<SQL::Abstract>
will assume DBIx::Class' uses of aliases to be complete column
names. The output will look like I<"me.name"> when it should actually
be I<"me"."name">.

=item unsafe

This Storage driver normally installs its own C<HandleError>, sets
C<RaiseError> and C<ShowErrorStatement> on, and sets C<PrintError> off on
all database handles, including those supplied by a coderef.  It does this
so that it can have consistent and useful error behavior.

If you set this option to a true value, Storage will not do its usual
modifications to the database handle's attributes, and instead relies on
the settings in your connect_info DBI options (or the values you set in
your connection coderef, in the case that you are connecting via coderef).

Note that your custom settings can cause Storage to malfunction,
especially if you set a C<HandleError> handler that suppresses exceptions
and/or disable C<RaiseError>.

=item auto_savepoint

If this option is true, L<DBIx::Class> will use savepoints when nesting
transactions, making it possible to recover from failure in the inner
transaction without having to abort all outer transactions.

=item cursor_class

Use this argument to supply a cursor class other than the default
L<DBIx::Class::Storage::DBI::Cursor>.

=back

Some real-life examples of arguments to L</connect_info> and
L<DBIx::Class::Schema/connect>

  # Simple SQLite connection
  ->connect_info([ 'dbi:SQLite:./foo.db' ]);

  # Connect via subref
  ->connect_info([ sub { DBI->connect(...) } ]);

  # Connect via subref in hashref
  ->connect_info([{
    dbh_maker => sub { DBI->connect(...) },
    on_connect_do => 'alter session ...',
  }]);

  # A bit more complicated
  ->connect_info(
    [
      'dbi:Pg:dbname=foo',
      'postgres',
      'my_pg_password',
      { AutoCommit => 1 },
      { quote_char => q{"}, name_sep => q{.} },
    ]
  );

  # Equivalent to the previous example
  ->connect_info(
    [
      'dbi:Pg:dbname=foo',
      'postgres',
      'my_pg_password',
      { AutoCommit => 1, quote_char => q{"}, name_sep => q{.} },
    ]
  );

  # Same, but with hashref as argument
  # See parse_connect_info for explanation
  ->connect_info(
    [{
      dsn         => 'dbi:Pg:dbname=foo',
      user        => 'postgres',
      password    => 'my_pg_password',
      AutoCommit  => 1,
      quote_char  => q{"},
      name_sep    => q{.},
    }]
  );

  # Subref + DBIx::Class-specific connection options
  ->connect_info(
    [
      sub { DBI->connect(...) },
      {
          quote_char => q{`},
          name_sep => q{@},
          on_connect_do => ['SET search_path TO myschema,otherschema,public'],
          disable_sth_caching => 1,
      },
    ]
  );



=cut

sub connect_info {
  my ($self, $info) = @_;

  return $self->_connect_info if !$info;

  $self->_connect_info($info); # copy for _connect_info

  $info = $self->_normalize_connect_info($info)
    if ref $info eq 'ARRAY';

  for my $storage_opt (keys %{ $info->{storage_options} }) {
    my $value = $info->{storage_options}{$storage_opt};

    $self->$storage_opt($value);
  }

  # Kill sql_maker/_sql_maker_opts, so we get a fresh one with only
  #  the new set of options
  $self->_sql_maker(undef);
  $self->_sql_maker_opts({});

  for my $sql_maker_opt (keys %{ $info->{sql_maker_options} }) {
    my $value = $info->{sql_maker_options}{$sql_maker_opt};

    $self->_sql_maker_opts->{$sql_maker_opt} = $value;
  }

  my %attrs = (
    %{ $self->_default_dbi_connect_attributes || {} },
    %{ $info->{attributes} || {} },
  );

  my @args = @{ $info->{arguments} };

  $self->_dbi_connect_info([@args,
    %attrs && !(ref $args[0] eq 'CODE') ? \%attrs : ()]);

  # FIXME - dirty:
  # save attributes them in a separate accessor so they are always
  # introspectable, even in case of a CODE $dbhmaker
  $self->_dbic_connect_attributes (\%attrs);

  return $self->_connect_info;
}

sub _normalize_connect_info {
  my ($self, $info_arg) = @_;
  my %info;

  my @args = @$info_arg;  # take a shallow copy for further mutilation

  # combine/pre-parse arguments depending on invocation style

  my %attrs;
  if (ref $args[0] eq 'CODE') {     # coderef with optional \%extra_attributes
    %attrs = %{ $args[1] || {} };
    @args = $args[0];
  }
  elsif (ref $args[0] eq 'HASH') { # single hashref (i.e. Catalyst config)
    %attrs = %{$args[0]};
    @args = ();
    if (my $code = delete $attrs{dbh_maker}) {
      @args = $code;

      my @ignored = grep { delete $attrs{$_} } (qw/dsn user password/);
      if (@ignored) {
        carp sprintf (
            'Attribute(s) %s in connect_info were ignored, as they can not be applied '
          . "to the result of 'dbh_maker'",

          join (', ', map { "'$_'" } (@ignored) ),
        );
      }
    }
    else {
      @args = delete @attrs{qw/dsn user password/};
    }
  }
  else {                # otherwise assume dsn/user/password + \%attrs + \%extra_attrs
    %attrs = (
      % { $args[3] || {} },
      % { $args[4] || {} },
    );
    @args = @args[0,1,2];
  }

  $info{arguments} = \@args;

  my @storage_opts = grep exists $attrs{$_},
    @storage_options, 'cursor_class';

  @{ $info{storage_options} }{@storage_opts} =
    delete @attrs{@storage_opts} if @storage_opts;

  my @sql_maker_opts = grep exists $attrs{$_},
    qw/limit_dialect quote_char name_sep/;

  @{ $info{sql_maker_options} }{@sql_maker_opts} =
    delete @attrs{@sql_maker_opts} if @sql_maker_opts;

  $info{attributes} = \%attrs if %attrs;

  return \%info;
}

sub _default_dbi_connect_attributes {
  return {
    AutoCommit => 1,
    RaiseError => 1,
    PrintError => 0,
  };
}

=head2 on_connect_do

This method is deprecated in favour of setting via L</connect_info>.

=cut

=head2 on_disconnect_do

This method is deprecated in favour of setting via L</connect_info>.

=cut

sub _parse_connect_do {
  my ($self, $type) = @_;

  my $val = $self->$type;
  return () if not defined $val;

  my @res;

  if (not ref($val)) {
    push @res, [ 'do_sql', $val ];
  } elsif (ref($val) eq 'CODE') {
    push @res, $val;
  } elsif (ref($val) eq 'ARRAY') {
    push @res, map { [ 'do_sql', $_ ] } @$val;
  } else {
    $self->throw_exception("Invalid type for $type: ".ref($val));
  }

  return \@res;
}

=head2 dbh_do

Arguments: ($subref | $method_name), @extra_coderef_args?

Execute the given $subref or $method_name using the new exception-based
connection management.

The first two arguments will be the storage object that C<dbh_do> was called
on and a database handle to use.  Any additional arguments will be passed
verbatim to the called subref as arguments 2 and onwards.

Using this (instead of $self->_dbh or $self->dbh) ensures correct
exception handling and reconnection (or failover in future subclasses).

Your subref should have no side-effects outside of the database, as
there is the potential for your subref to be partially double-executed
if the database connection was stale/dysfunctional.

Example:

  my @stuff = $schema->storage->dbh_do(
    sub {
      my ($storage, $dbh, @cols) = @_;
      my $cols = join(q{, }, @cols);
      $dbh->selectrow_array("SELECT $cols FROM foo");
    },
    @column_list
  );

=cut

sub dbh_do {
  my $self = shift;
  my $code = shift;

  my $dbh = $self->_get_dbh;

  return $self->$code($dbh, @_)
    if ( $self->{_in_dbh_do} || $self->{transaction_depth} );

  local $self->{_in_dbh_do} = 1;

  # take a ref instead of a copy, to preserve coderef @_ aliasing semantics
  my $args = \@_;
  return try {
    $self->$code ($dbh, @$args);
  } catch {
    $self->throw_exception($_) if $self->connected;

    # We were not connected - reconnect and retry, but let any
    #  exception fall right through this time
    carp "Retrying $code after catching disconnected exception: $_"
      if $ENV{DBIC_DBIRETRY_DEBUG};

    $self->_populate_dbh;
    $self->$code($self->_dbh, @$args);
  };
}

# This is basically a blend of dbh_do above and DBIx::Class::Storage::txn_do.
# It also informs dbh_do to bypass itself while under the direction of txn_do,
#  via $self->{_in_dbh_do} (this saves some redundant eval and errorcheck, etc)
sub txn_do {
  my $self = shift;
  my $coderef = shift;

  ref $coderef eq 'CODE' or $self->throw_exception
    ('$coderef must be a CODE reference');

  return $coderef->(@_) if $self->{transaction_depth} && ! $self->auto_savepoint;

  local $self->{_in_dbh_do} = 1;

  my @result;
  my $want_array = wantarray;

  my $tried = 0;
  while(1) {
    my $exception;

    # take a ref instead of a copy, to preserve coderef @_ aliasing semantics
    my $args = \@_;

    try {
      $self->_get_dbh;

      $self->txn_begin;
      if($want_array) {
          @result = $coderef->(@$args);
      }
      elsif(defined $want_array) {
          $result[0] = $coderef->(@$args);
      }
      else {
          $coderef->(@$args);
      }
      $self->txn_commit;
    } catch {
      $exception = $_;
    };

    if(! defined $exception) { return $want_array ? @result : $result[0] }

    if($tried++ || $self->connected) {
      my $rollback_exception;
      try { $self->txn_rollback } catch { $rollback_exception = shift };
      if(defined $rollback_exception) {
        my $exception_class = "DBIx::Class::Storage::NESTED_ROLLBACK_EXCEPTION";
        $self->throw_exception($exception)  # propagate nested rollback
          if $rollback_exception =~ /$exception_class/;

        $self->throw_exception(
          "Transaction aborted: ${exception}. "
          . "Rollback failed: ${rollback_exception}"
        );
      }
      $self->throw_exception($exception)
    }

    # We were not connected, and was first try - reconnect and retry
    # via the while loop
    carp "Retrying $coderef after catching disconnected exception: $exception"
      if $ENV{DBIC_DBIRETRY_DEBUG};
    $self->_populate_dbh;
  }
}

=head2 disconnect

Our C<disconnect> method also performs a rollback first if the
database is not in C<AutoCommit> mode.

=cut

sub disconnect {
  my ($self) = @_;

  if( $self->_dbh ) {
    my @actions;

    push @actions, ( $self->on_disconnect_call || () );
    push @actions, $self->_parse_connect_do ('on_disconnect_do');

    $self->_do_connection_actions(disconnect_call_ => $_) for @actions;

    $self->_dbh_rollback unless $self->_dbh_autocommit;

    %{ $self->_dbh->{CachedKids} } = ();
    $self->_dbh->disconnect;
    $self->_dbh(undef);
    $self->{_dbh_gen}++;
  }
}

=head2 with_deferred_fk_checks

=over 4

=item Arguments: C<$coderef>

=item Return Value: The return value of $coderef

=back

Storage specific method to run the code ref with FK checks deferred or
in MySQL's case disabled entirely.

=cut

# Storage subclasses should override this
sub with_deferred_fk_checks {
  my ($self, $sub) = @_;
  $sub->();
}

=head2 connected

=over

=item Arguments: none

=item Return Value: 1|0

=back

Verifies that the current database handle is active and ready to execute
an SQL statement (e.g. the connection did not get stale, server is still
answering, etc.) This method is used internally by L</dbh>.

=cut

sub connected {
  my $self = shift;
  return 0 unless $self->_seems_connected;

  #be on the safe side
  local $self->_dbh->{RaiseError} = 1;

  return $self->_ping;
}

sub _seems_connected {
  my $self = shift;

  $self->_preserve_foreign_dbh;

  my $dbh = $self->_dbh
    or return 0;

  return $dbh->FETCH('Active');
}

sub _ping {
  my $self = shift;

  my $dbh = $self->_dbh or return 0;

  return $dbh->ping;
}

sub ensure_connected {
  my ($self) = @_;

  unless ($self->connected) {
    $self->_populate_dbh;
  }
}

=head2 dbh

Returns a C<$dbh> - a data base handle of class L<DBI>. The returned handle
is guaranteed to be healthy by implicitly calling L</connected>, and if
necessary performing a reconnection before returning. Keep in mind that this
is very B<expensive> on some database engines. Consider using L</dbh_do>
instead.

=cut

sub dbh {
  my ($self) = @_;

  if (not $self->_dbh) {
    $self->_populate_dbh;
  } else {
    $self->ensure_connected;
  }
  return $self->_dbh;
}

# this is the internal "get dbh or connect (don't check)" method
sub _get_dbh {
  my $self = shift;
  $self->_preserve_foreign_dbh;
  $self->_populate_dbh unless $self->_dbh;
  return $self->_dbh;
}

sub _sql_maker_args {
    my ($self) = @_;

    return (
      bindtype=>'columns',
      array_datatypes => 1,
      limit_dialect => $self->_get_dbh,
      %{$self->_sql_maker_opts}
    );
}

sub sql_maker {
  my ($self) = @_;
  unless ($self->_sql_maker) {
    my $sql_maker_class = $self->sql_maker_class;
    $self->ensure_class_loaded ($sql_maker_class);
    $self->_sql_maker($sql_maker_class->new( $self->_sql_maker_args ));
  }
  return $self->_sql_maker;
}

# nothing to do by default
sub _rebless {}
sub _init {}

sub _populate_dbh {
  my ($self) = @_;

  my @info = @{$self->_dbi_connect_info || []};
  $self->_dbh(undef); # in case ->connected failed we might get sent here
  $self->_server_info_hash (undef);
  $self->_dbh($self->_connect(@info));

  $self->_conn_pid($$);
  $self->_conn_tid(threads->tid) if $INC{'threads.pm'};

  $self->_determine_driver;

  # Always set the transaction depth on connect, since
  #  there is no transaction in progress by definition
  $self->{transaction_depth} = $self->_dbh_autocommit ? 0 : 1;

  $self->_run_connection_actions unless $self->{_in_determine_driver};
}

sub _run_connection_actions {
  my $self = shift;
  my @actions;

  push @actions, ( $self->on_connect_call || () );
  push @actions, $self->_parse_connect_do ('on_connect_do');

  $self->_do_connection_actions(connect_call_ => $_) for @actions;
}

sub _server_info {
  my $self = shift;

  unless ($self->_server_info_hash) {

    my %info;

    my $server_version = try { $self->_get_server_version };

    if (defined $server_version) {
      $info{dbms_version} = $server_version;

      my ($numeric_version) = $server_version =~ /^([\d\.]+)/;
      my @verparts = split (/\./, $numeric_version);
      if (
        @verparts
          &&
        $verparts[0] <= 999
      ) {
        # consider only up to 3 version parts, iff not more than 3 digits
        my @use_parts;
        while (@verparts && @use_parts < 3) {
          my $p = shift @verparts;
          last if $p > 999;
          push @use_parts, $p;
        }
        push @use_parts, 0 while @use_parts < 3;

        $info{normalized_dbms_version} = sprintf "%d.%03d%03d", @use_parts;
      }
    }

    $self->_server_info_hash(\%info);
  }

  return $self->_server_info_hash
}

sub _get_server_version {
  shift->_get_dbh->get_info(18);
}

sub _determine_driver {
  my ($self) = @_;

  if ((not $self->_driver_determined) && (not $self->{_in_determine_driver})) {
    my $started_connected = 0;
    local $self->{_in_determine_driver} = 1;

    if (ref($self) eq __PACKAGE__) {
      my $driver;
      if ($self->_dbh) { # we are connected
        $driver = $self->_dbh->{Driver}{Name};
        $started_connected = 1;
      } else {
        # if connect_info is a CODEREF, we have no choice but to connect
        if (ref $self->_dbi_connect_info->[0] &&
            reftype $self->_dbi_connect_info->[0] eq 'CODE') {
          $self->_populate_dbh;
          $driver = $self->_dbh->{Driver}{Name};
        }
        else {
          # try to use dsn to not require being connected, the driver may still
          # force a connection in _rebless to determine version
          # (dsn may not be supplied at all if all we do is make a mock-schema)
          my $dsn = $self->_dbi_connect_info->[0] || $ENV{DBI_DSN} || '';
          ($driver) = $dsn =~ /dbi:([^:]+):/i;
          $driver ||= $ENV{DBI_DRIVER};
        }
      }

      if ($driver) {
        my $storage_class = "DBIx::Class::Storage::DBI::${driver}";
        if ($self->load_optional_class($storage_class)) {
          mro::set_mro($storage_class, 'c3');
          bless $self, $storage_class;
          $self->_rebless();
        }
      }
    }

    $self->_driver_determined(1);

    $self->_init; # run driver-specific initializations

    $self->_run_connection_actions
        if !$started_connected && defined $self->_dbh;
  }
}

sub _do_connection_actions {
  my $self          = shift;
  my $method_prefix = shift;
  my $call          = shift;

  if (not ref($call)) {
    my $method = $method_prefix . $call;
    $self->$method(@_);
  } elsif (ref($call) eq 'CODE') {
    $self->$call(@_);
  } elsif (ref($call) eq 'ARRAY') {
    if (ref($call->[0]) ne 'ARRAY') {
      $self->_do_connection_actions($method_prefix, $_) for @$call;
    } else {
      $self->_do_connection_actions($method_prefix, @$_) for @$call;
    }
  } else {
    $self->throw_exception (sprintf ("Don't know how to process conection actions of type '%s'", ref($call)) );
  }

  return $self;
}

sub connect_call_do_sql {
  my $self = shift;
  $self->_do_query(@_);
}

sub disconnect_call_do_sql {
  my $self = shift;
  $self->_do_query(@_);
}

# override in db-specific backend when necessary
sub connect_call_datetime_setup { 1 }

sub _do_query {
  my ($self, $action) = @_;

  if (ref $action eq 'CODE') {
    $action = $action->($self);
    $self->_do_query($_) foreach @$action;
  }
  else {
    # Most debuggers expect ($sql, @bind), so we need to exclude
    # the attribute hash which is the second argument to $dbh->do
    # furthermore the bind values are usually to be presented
    # as named arrayref pairs, so wrap those here too
    my @do_args = (ref $action eq 'ARRAY') ? (@$action) : ($action);
    my $sql = shift @do_args;
    my $attrs = shift @do_args;
    my @bind = map { [ undef, $_ ] } @do_args;

    $self->_query_start($sql, @bind);
    $self->_get_dbh->do($sql, $attrs, @do_args);
    $self->_query_end($sql, @bind);
  }

  return $self;
}

sub _connect {
  my ($self, @info) = @_;

  $self->throw_exception("You failed to provide any connection info")
    if !@info;

  my ($old_connect_via, $dbh);

  if ($INC{'Apache/DBI.pm'} && $ENV{MOD_PERL}) {
    $old_connect_via = $DBI::connect_via;
    $DBI::connect_via = 'connect';
  }

  # FIXME - this should have been Try::Tiny, but triggers a leak-bug in perl(!)
  # related to coderef refcounting. A failing test has been submitted to T::T
  my $connect_ok = eval {
    if(ref $info[0] eq 'CODE') {
       $dbh = $info[0]->();
    }
    else {
       $dbh = DBI->connect(@info);
    }

    if (!$dbh) {
      die $DBI::errstr;
    }

    unless ($self->unsafe) {
      my $weak_self = $self;
      weaken $weak_self;
      $dbh->{HandleError} = sub {
          if ($weak_self) {
            $weak_self->throw_exception("DBI Exception: $_[0]");
          }
          else {
            # the handler may be invoked by something totally out of
            # the scope of DBIC
            croak ("DBI Exception: $_[0]");
          }
      };
      $dbh->{ShowErrorStatement} = 1;
      $dbh->{RaiseError} = 1;
      $dbh->{PrintError} = 0;
    }

    1;
  };

  my $possible_err = $@;
  $DBI::connect_via = $old_connect_via if $old_connect_via;

  unless ($connect_ok) {
    $self->throw_exception("DBI Connection failed: $possible_err")
  }

  $self->_dbh_autocommit($dbh->{AutoCommit});
  $dbh;
}

sub svp_begin {
  my ($self, $name) = @_;

  $name = $self->_svp_generate_name
    unless defined $name;

  $self->throw_exception ("You can't use savepoints outside a transaction")
    if $self->{transaction_depth} == 0;

  $self->throw_exception ("Your Storage implementation doesn't support savepoints")
    unless $self->can('_svp_begin');

  push @{ $self->{savepoints} }, $name;

  $self->debugobj->svp_begin($name) if $self->debug;

  return $self->_svp_begin($name);
}

sub svp_release {
  my ($self, $name) = @_;

  $self->throw_exception ("You can't use savepoints outside a transaction")
    if $self->{transaction_depth} == 0;

  $self->throw_exception ("Your Storage implementation doesn't support savepoints")
    unless $self->can('_svp_release');

  if (defined $name) {
    $self->throw_exception ("Savepoint '$name' does not exist")
      unless grep { $_ eq $name } @{ $self->{savepoints} };

    # Dig through the stack until we find the one we are releasing.  This keeps
    # the stack up to date.
    my $svp;

    do { $svp = pop @{ $self->{savepoints} } } while $svp ne $name;
  } else {
    $name = pop @{ $self->{savepoints} };
  }

  $self->debugobj->svp_release($name) if $self->debug;

  return $self->_svp_release($name);
}

sub svp_rollback {
  my ($self, $name) = @_;

  $self->throw_exception ("You can't use savepoints outside a transaction")
    if $self->{transaction_depth} == 0;

  $self->throw_exception ("Your Storage implementation doesn't support savepoints")
    unless $self->can('_svp_rollback');

  if (defined $name) {
      # If they passed us a name, verify that it exists in the stack
      unless(grep({ $_ eq $name } @{ $self->{savepoints} })) {
          $self->throw_exception("Savepoint '$name' does not exist!");
      }

      # Dig through the stack until we find the one we are releasing.  This keeps
      # the stack up to date.
      while(my $s = pop(@{ $self->{savepoints} })) {
          last if($s eq $name);
      }
      # Add the savepoint back to the stack, as a rollback doesn't remove the
      # named savepoint, only everything after it.
      push(@{ $self->{savepoints} }, $name);
  } else {
      # We'll assume they want to rollback to the last savepoint
      $name = $self->{savepoints}->[-1];
  }

  $self->debugobj->svp_rollback($name) if $self->debug;

  return $self->_svp_rollback($name);
}

sub _svp_generate_name {
    my ($self) = @_;

    return 'savepoint_'.scalar(@{ $self->{'savepoints'} });
}

sub txn_begin {
  my $self = shift;

  # this means we have not yet connected and do not know the AC status
  # (e.g. coderef $dbh)
  $self->ensure_connected if (! defined $self->_dbh_autocommit);

  if($self->{transaction_depth} == 0) {
    $self->debugobj->txn_begin()
      if $self->debug;
    $self->_dbh_begin_work;
  }
  elsif ($self->auto_savepoint) {
    $self->svp_begin;
  }
  $self->{transaction_depth}++;
}

sub _dbh_begin_work {
  my $self = shift;

  # if the user is utilizing txn_do - good for him, otherwise we need to
  # ensure that the $dbh is healthy on BEGIN.
  # We do this via ->dbh_do instead of ->dbh, so that the ->dbh "ping"
  # will be replaced by a failure of begin_work itself (which will be
  # then retried on reconnect)
  if ($self->{_in_dbh_do}) {
    $self->_dbh->begin_work;
  } else {
    $self->dbh_do(sub { $_[1]->begin_work });
  }
}

sub txn_commit {
  my $self = shift;
  if ($self->{transaction_depth} == 1) {
    $self->debugobj->txn_commit()
      if ($self->debug);
    $self->_dbh_commit;
    $self->{transaction_depth} = 0
      if $self->_dbh_autocommit;
  }
  elsif($self->{transaction_depth} > 1) {
    $self->{transaction_depth}--;
    $self->svp_release
      if $self->auto_savepoint;
  }
}

sub _dbh_commit {
  my $self = shift;
  my $dbh  = $self->_dbh
    or $self->throw_exception('cannot COMMIT on a disconnected handle');
  $dbh->commit;
}

sub txn_rollback {
  my $self = shift;
  my $dbh = $self->_dbh;
  try {
    if ($self->{transaction_depth} == 1) {
      $self->debugobj->txn_rollback()
        if ($self->debug);
      $self->{transaction_depth} = 0
        if $self->_dbh_autocommit;
      $self->_dbh_rollback;
    }
    elsif($self->{transaction_depth} > 1) {
      $self->{transaction_depth}--;
      if ($self->auto_savepoint) {
        $self->svp_rollback;
        $self->svp_release;
      }
    }
    else {
      die DBIx::Class::Storage::NESTED_ROLLBACK_EXCEPTION->new;
    }
  }
  catch {
    my $exception_class = "DBIx::Class::Storage::NESTED_ROLLBACK_EXCEPTION";

    if ($_ !~ /$exception_class/) {
      # ensure that a failed rollback resets the transaction depth
      $self->{transaction_depth} = $self->_dbh_autocommit ? 0 : 1;
    }

    $self->throw_exception($_)
  };
}

sub _dbh_rollback {
  my $self = shift;
  my $dbh  = $self->_dbh
    or $self->throw_exception('cannot ROLLBACK on a disconnected handle');
  $dbh->rollback;
}

# This used to be the top-half of _execute.  It was split out to make it
#  easier to override in NoBindVars without duping the rest.  It takes up
#  all of _execute's args, and emits $sql, @bind.
sub _prep_for_execute {
  my ($self, $op, $extra_bind, $ident, $args) = @_;

  if( blessed $ident && $ident->isa("DBIx::Class::ResultSource") ) {
    $ident = $ident->from();
  }

  my ($sql, @bind) = $self->sql_maker->$op($ident, @$args);

  unshift(@bind,
    map { ref $_ eq 'ARRAY' ? $_ : [ '!!dummy', $_ ] } @$extra_bind)
      if $extra_bind;
  return ($sql, \@bind);
}


sub _fix_bind_params {
    my ($self, @bind) = @_;

    ### Turn @bind from something like this:
    ###   ( [ "artist", 1 ], [ "cdid", 1, 3 ] )
    ### to this:
    ###   ( "'1'", "'1'", "'3'" )
    return
        map {
            if ( defined( $_ && $_->[1] ) ) {
                map { qq{'$_'}; } @{$_}[ 1 .. $#$_ ];
            }
            else { q{'NULL'}; }
        } @bind;
}

sub _query_start {
    my ( $self, $sql, @bind ) = @_;

    if ( $self->debug ) {
        @bind = $self->_fix_bind_params(@bind);

        $self->debugobj->query_start( $sql, @bind );
    }
}

sub _query_end {
    my ( $self, $sql, @bind ) = @_;

    if ( $self->debug ) {
        @bind = $self->_fix_bind_params(@bind);
        $self->debugobj->query_end( $sql, @bind );
    }
}

sub _dbh_execute {
  my ($self, $dbh, $op, $extra_bind, $ident, $bind_attributes, @args) = @_;

  my ($sql, $bind) = $self->_prep_for_execute($op, $extra_bind, $ident, \@args);

  $self->_query_start( $sql, @$bind );

  my $sth = $self->sth($sql,$op);

  my $placeholder_index = 1;

  foreach my $bound (@$bind) {
    my $attributes = {};
    my($column_name, @data) = @$bound;

    if ($bind_attributes) {
      $attributes = $bind_attributes->{$column_name}
      if defined $bind_attributes->{$column_name};
    }

    foreach my $data (@data) {
      my $ref = ref $data;
      $data = $ref && $ref ne 'ARRAY' ? ''.$data : $data; # stringify args (except arrayrefs)

      $sth->bind_param($placeholder_index, $data, $attributes);
      $placeholder_index++;
    }
  }

  # Can this fail without throwing an exception anyways???
  my $rv = $sth->execute();
  $self->throw_exception(
    $sth->errstr || $sth->err || 'Unknown error: execute() returned false, but error flags were not set...'
  ) if !$rv;

  $self->_query_end( $sql, @$bind );

  return (wantarray ? ($rv, $sth, @$bind) : $rv);
}

sub _execute {
    my $self = shift;
    $self->dbh_do('_dbh_execute', @_);  # retry over disconnects
}

sub _prefetch_insert_auto_nextvals {
  my ($self, $source, $to_insert) = @_;

  my $upd = {};

  foreach my $col ( $source->columns ) {
    if ( !defined $to_insert->{$col} ) {
      my $col_info = $source->column_info($col);

      if ( $col_info->{auto_nextval} ) {
        $upd->{$col} = $to_insert->{$col} = $self->_sequence_fetch(
          'nextval',
          $col_info->{sequence} ||=
            $self->_dbh_get_autoinc_seq($self->_get_dbh, $source, $col)
        );
      }
    }
  }

  return $upd;
}

sub insert {
  my $self = shift;
  my ($source, $to_insert, $opts) = @_;

  my $updated_cols = $self->_prefetch_insert_auto_nextvals (@_);

  my $bind_attributes = $self->source_bind_attributes($source);

  my ($rv, $sth) = $self->_execute('insert' => [], $source, $bind_attributes, $to_insert, $opts);

  if ($opts->{returning}) {
    my @ret_cols = @{$opts->{returning}};

    my @ret_vals = try {
      local $SIG{__WARN__} = sub {};
      my @r = $sth->fetchrow_array;
      $sth->finish;
      @r;
    };

    my %ret;
    @ret{@ret_cols} = @ret_vals if (@ret_vals);

    $updated_cols = {
      %$updated_cols,
      %ret,
    };
  }

  return $updated_cols;
}

## Currently it is assumed that all values passed will be "normal", i.e. not
## scalar refs, or at least, all the same type as the first set, the statement is
## only prepped once.
sub insert_bulk {
  my ($self, $source, $cols, $data) = @_;

  my %colvalues;
  @colvalues{@$cols} = (0..$#$cols);

  for my $i (0..$#$cols) {
    my $first_val = $data->[0][$i];
    next unless ref $first_val eq 'SCALAR';

    $colvalues{ $cols->[$i] } = $first_val;
  }

  # check for bad data and stringify stringifiable objects
  my $bad_slice = sub {
    my ($msg, $col_idx, $slice_idx) = @_;
    $self->throw_exception(sprintf "%s for column '%s' in populate slice:\n%s",
      $msg,
      $cols->[$col_idx],
      do {
        local $Data::Dumper::Maxdepth = 1; # don't dump objects, if any
        Dumper {
          map { $cols->[$_] => $data->[$slice_idx][$_] } (0 .. $#$cols)
        },
      }
    );
  };

  for my $datum_idx (0..$#$data) {
    my $datum = $data->[$datum_idx];

    for my $col_idx (0..$#$cols) {
      my $val            = $datum->[$col_idx];
      my $sqla_bind      = $colvalues{ $cols->[$col_idx] };
      my $is_literal_sql = (ref $sqla_bind) eq 'SCALAR';

      if ($is_literal_sql) {
        if (not ref $val) {
          $bad_slice->('bind found where literal SQL expected', $col_idx, $datum_idx);
        }
        elsif ((my $reftype = ref $val) ne 'SCALAR') {
          $bad_slice->("$reftype reference found where literal SQL expected",
            $col_idx, $datum_idx);
        }
        elsif ($$val ne $$sqla_bind){
          $bad_slice->("inconsistent literal SQL value, expecting: '$$sqla_bind'",
            $col_idx, $datum_idx);
        }
      }
      elsif (my $reftype = ref $val) {
        require overload;
        if (overload::Method($val, '""')) {
          $datum->[$col_idx] = "".$val;
        }
        else {
          $bad_slice->("$reftype reference found where bind expected",
            $col_idx, $datum_idx);
        }
      }
    }
  }

  my ($sql, $bind) = $self->_prep_for_execute (
    'insert', undef, $source, [\%colvalues]
  );
  my @bind = @$bind;

  my $empty_bind = 1 if (not @bind) &&
    (grep { ref $_ eq 'SCALAR' } values %colvalues) == @$cols;

  if ((not @bind) && (not $empty_bind)) {
    $self->throw_exception(
      'Cannot insert_bulk without support for placeholders'
    );
  }

  # neither _execute_array, nor _execute_inserts_with_no_binds are
  # atomic (even if _execute _array is a single call). Thus a safety
  # scope guard
  my $guard = $self->txn_scope_guard;

  $self->_query_start( $sql, ['__BULK__'] );
  my $sth = $self->sth($sql);
  my $rv = do {
    if ($empty_bind) {
      # bind_param_array doesn't work if there are no binds
      $self->_dbh_execute_inserts_with_no_binds( $sth, scalar @$data );
    }
    else {
#      @bind = map { ref $_ ? ''.$_ : $_ } @bind; # stringify args
      $self->_execute_array( $source, $sth, \@bind, $cols, $data );
    }
  };

  $self->_query_end( $sql, ['__BULK__'] );

  $guard->commit;

  return (wantarray ? ($rv, $sth, @bind) : $rv);
}

sub _execute_array {
  my ($self, $source, $sth, $bind, $cols, $data, @extra) = @_;

  ## This must be an arrayref, else nothing works!
  my $tuple_status = [];

  ## Get the bind_attributes, if any exist
  my $bind_attributes = $self->source_bind_attributes($source);

  ## Bind the values and execute
  my $placeholder_index = 1;

  foreach my $bound (@$bind) {

    my $attributes = {};
    my ($column_name, $data_index) = @$bound;

    if( $bind_attributes ) {
      $attributes = $bind_attributes->{$column_name}
      if defined $bind_attributes->{$column_name};
    }

    my @data = map { $_->[$data_index] } @$data;

    $sth->bind_param_array(
      $placeholder_index,
      [@data],
      (%$attributes ?  $attributes : ()),
    );
    $placeholder_index++;
  }

  my ($rv, $err);
  try {
    $rv = $self->_dbh_execute_array($sth, $tuple_status, @extra);
  }
  catch {
    $err = shift;
  }
  finally {
    # Statement must finish even if there was an exception.
    try {
      $sth->finish
    }
    catch {
      $err = shift unless defined $err
    };
  };

  $err = $sth->errstr
    if (! defined $err and $sth->err);

  if (defined $err) {
    my $i = 0;
    ++$i while $i <= $#$tuple_status && !ref $tuple_status->[$i];

    $self->throw_exception("Unexpected populate error: $err")
      if ($i > $#$tuple_status);

    $self->throw_exception(sprintf "%s for populate slice:\n%s",
      ($tuple_status->[$i][1] || $err),
      Dumper { map { $cols->[$_] => $data->[$i][$_] } (0 .. $#$cols) },
    );
  }

  return $rv;
}

sub _dbh_execute_array {
    my ($self, $sth, $tuple_status, @extra) = @_;

    return $sth->execute_array({ArrayTupleStatus => $tuple_status});
}

sub _dbh_execute_inserts_with_no_binds {
  my ($self, $sth, $count) = @_;

  my $err;
  try {
    my $dbh = $self->_get_dbh;
    local $dbh->{RaiseError} = 1;
    local $dbh->{PrintError} = 0;

    $sth->execute foreach 1..$count;
  }
  catch {
    $err = shift;
  }
  finally {
    # Make sure statement is finished even if there was an exception.
    try {
      $sth->finish
    }
    catch {
      $err = shift unless defined $err;
    };
  };

  $self->throw_exception($err) if defined $err;

  return $count;
}

sub update {
  my ($self, $source, @args) = @_;

  my $bind_attrs = $self->source_bind_attributes($source);

  return $self->_execute('update' => [], $source, $bind_attrs, @args);
}


sub delete {
  my ($self, $source, @args) = @_;

  my $bind_attrs = $self->source_bind_attributes($source);

  return $self->_execute('delete' => [], $source, $bind_attrs, @args);
}

# We were sent here because the $rs contains a complex search
# which will require a subquery to select the correct rows
# (i.e. joined or limited resultsets, or non-introspectable conditions)
#
# Generating a single PK column subquery is trivial and supported
# by all RDBMS. However if we have a multicolumn PK, things get ugly.
# Look at _multipk_update_delete()
sub _subq_update_delete {
  my $self = shift;
  my ($rs, $op, $values) = @_;

  my $rsrc = $rs->result_source;

  # quick check if we got a sane rs on our hands
  my @pcols = $rsrc->_pri_cols;

  my $sel = $rs->_resolved_attrs->{select};
  $sel = [ $sel ] unless ref $sel eq 'ARRAY';

  if (
      join ("\x00", map { join '.', $rs->{attrs}{alias}, $_ } sort @pcols)
        ne
      join ("\x00", sort @$sel )
  ) {
    $self->throw_exception (
      '_subq_update_delete can not be called on resultsets selecting columns other than the primary keys'
    );
  }

  if (@pcols == 1) {
    return $self->$op (
      $rsrc,
      $op eq 'update' ? $values : (),
      { $pcols[0] => { -in => $rs->as_query } },
    );
  }

  else {
    return $self->_multipk_update_delete (@_);
  }
}

# ANSI SQL does not provide a reliable way to perform a multicol-PK
# resultset update/delete involving subqueries. So by default resort
# to simple (and inefficient) delete_all style per-row opearations,
# while allowing specific storages to override this with a faster
# implementation.
#
sub _multipk_update_delete {
  return shift->_per_row_update_delete (@_);
}

# This is the default loop used to delete/update rows for multi PK
# resultsets, and used by mysql exclusively (because it can't do anything
# else).
#
# We do not use $row->$op style queries, because resultset update/delete
# is not expected to cascade (this is what delete_all/update_all is for).
#
# There should be no race conditions as the entire operation is rolled
# in a transaction.
#
sub _per_row_update_delete {
  my $self = shift;
  my ($rs, $op, $values) = @_;

  my $rsrc = $rs->result_source;
  my @pcols = $rsrc->_pri_cols;

  my $guard = $self->txn_scope_guard;

  # emulate the return value of $sth->execute for non-selects
  my $row_cnt = '0E0';

  my $subrs_cur = $rs->cursor;
  my @all_pk = $subrs_cur->all;
  for my $pks ( @all_pk) {

    my $cond;
    for my $i (0.. $#pcols) {
      $cond->{$pcols[$i]} = $pks->[$i];
    }

    $self->$op (
      $rsrc,
      $op eq 'update' ? $values : (),
      $cond,
    );

    $row_cnt++;
  }

  $guard->commit;

  return $row_cnt;
}

sub _select {
  my $self = shift;
  $self->_execute($self->_select_args(@_));
}

sub _select_args_to_query {
  my $self = shift;

  # my ($op, $bind, $ident, $bind_attrs, $select, $cond, $rs_attrs, $rows, $offset)
  #  = $self->_select_args($ident, $select, $cond, $attrs);
  my ($op, $bind, $ident, $bind_attrs, @args) =
    $self->_select_args(@_);

  # my ($sql, $prepared_bind) = $self->_prep_for_execute($op, $bind, $ident, [ $select, $cond, $rs_attrs, $rows, $offset ]);
  my ($sql, $prepared_bind) = $self->_prep_for_execute($op, $bind, $ident, \@args);
  $prepared_bind ||= [];

  return wantarray
    ? ($sql, $prepared_bind, $bind_attrs)
    : \[ "($sql)", @$prepared_bind ]
  ;
}

sub _select_args {
  my ($self, $ident, $select, $where, $attrs) = @_;

  my $sql_maker = $self->sql_maker;
  my ($alias2source, $rs_alias) = $self->_resolve_ident_sources ($ident);

  $attrs = {
    %$attrs,
    select => $select,
    from => $ident,
    where => $where,
    $rs_alias && $alias2source->{$rs_alias}
      ? ( _rsroot_source_handle => $alias2source->{$rs_alias}->handle )
      : ()
    ,
  };

  # calculate bind_attrs before possible $ident mangling
  my $bind_attrs = {};
  for my $alias (keys %$alias2source) {
    my $bindtypes = $self->source_bind_attributes ($alias2source->{$alias}) || {};
    for my $col (keys %$bindtypes) {

      my $fqcn = join ('.', $alias, $col);
      $bind_attrs->{$fqcn} = $bindtypes->{$col} if $bindtypes->{$col};

      # Unqialified column names are nice, but at the same time can be
      # rather ambiguous. What we do here is basically go along with
      # the loop, adding an unqualified column slot to $bind_attrs,
      # alongside the fully qualified name. As soon as we encounter
      # another column by that name (which would imply another table)
      # we unset the unqualified slot and never add any info to it
      # to avoid erroneous type binding. If this happens the users
      # only choice will be to fully qualify his column name

      if (exists $bind_attrs->{$col}) {
        $bind_attrs->{$col} = {};
      }
      else {
        $bind_attrs->{$col} = $bind_attrs->{$fqcn};
      }
    }
  }

  # adjust limits
  if (defined $attrs->{rows}) {
    $self->throw_exception("rows attribute must be positive if present")
      unless $attrs->{rows} > 0;
  }
  elsif (defined $attrs->{offset}) {
    # MySQL actually recommends this approach.  I cringe.
    $attrs->{rows} = $sql_maker->__max_int;
  }

  my @limit;

  # see if we need to tear the prefetch apart otherwise delegate the limiting to the
  # storage, unless software limit was requested
  if (
    #limited has_many
    ( $attrs->{rows} && keys %{$attrs->{collapse}} )
       ||
    # grouped prefetch (to satisfy group_by == select)
    ( $attrs->{group_by}
        &&
      @{$attrs->{group_by}}
        &&
      $attrs->{_prefetch_select}
        &&
      @{$attrs->{_prefetch_select}}
    )
  ) {
    ($ident, $select, $where, $attrs)
      = $self->_adjust_select_args_for_complex_prefetch ($ident, $select, $where, $attrs);
  }
  elsif (! $attrs->{software_limit} ) {
    push @limit, $attrs->{rows}, $attrs->{offset};
  }

  # try to simplify the joinmap further (prune unreferenced type-single joins)
  $ident = $self->_prune_unused_joins ($ident, $select, $where, $attrs);

###
  # This would be the point to deflate anything found in $where
  # (and leave $attrs->{bind} intact). Problem is - inflators historically
  # expect a row object. And all we have is a resultsource (it is trivial
  # to extract deflator coderefs via $alias2source above).
  #
  # I don't see a way forward other than changing the way deflators are
  # invoked, and that's just bad...
###

  return ('select', $attrs->{bind}, $ident, $bind_attrs, $select, $where, $attrs, @limit);
}

# Returns a counting SELECT for a simple count
# query. Abstracted so that a storage could override
# this to { count => 'firstcol' } or whatever makes
# sense as a performance optimization
sub _count_select {
  #my ($self, $source, $rs_attrs) = @_;
  return { count => '*' };
}


sub source_bind_attributes {
  my ($self, $source) = @_;

  my $bind_attributes;
  foreach my $column ($source->columns) {

    my $data_type = $source->column_info($column)->{data_type} || '';
    $bind_attributes->{$column} = $self->bind_attribute_by_data_type($data_type)
     if $data_type;
  }

  return $bind_attributes;
}

=head2 select

=over 4

=item Arguments: $ident, $select, $condition, $attrs

=back

Handle a SQL select statement.

=cut

sub select {
  my $self = shift;
  my ($ident, $select, $condition, $attrs) = @_;
  return $self->cursor_class->new($self, \@_, $attrs);
}

sub select_single {
  my $self = shift;
  my ($rv, $sth, @bind) = $self->_select(@_);
  my @row = $sth->fetchrow_array;
  my @nextrow = $sth->fetchrow_array if @row;
  if(@row && @nextrow) {
    carp "Query returned more than one row.  SQL that returns multiple rows is DEPRECATED for ->find and ->single";
  }
  # Need to call finish() to work round broken DBDs
  $sth->finish();
  return @row;
}

=head2 sth

=over 4

=item Arguments: $sql

=back

Returns a L<DBI> sth (statement handle) for the supplied SQL.

=cut

sub _dbh_sth {
  my ($self, $dbh, $sql) = @_;

  # 3 is the if_active parameter which avoids active sth re-use
  my $sth = $self->disable_sth_caching
    ? $dbh->prepare($sql)
    : $dbh->prepare_cached($sql, {}, 3);

  # XXX You would think RaiseError would make this impossible,
  #  but apparently that's not true :(
  $self->throw_exception($dbh->errstr) if !$sth;

  $sth;
}

sub sth {
  my ($self, $sql) = @_;
  $self->dbh_do('_dbh_sth', $sql);  # retry over disconnects
}

sub _dbh_columns_info_for {
  my ($self, $dbh, $table) = @_;

  if ($dbh->can('column_info')) {
    my %result;
    my $caught;
    try {
      my ($schema,$tab) = $table =~ /^(.+?)\.(.+)$/ ? ($1,$2) : (undef,$table);
      my $sth = $dbh->column_info( undef,$schema, $tab, '%' );
      $sth->execute();
      while ( my $info = $sth->fetchrow_hashref() ){
        my %column_info;
        $column_info{data_type}   = $info->{TYPE_NAME};
        $column_info{size}      = $info->{COLUMN_SIZE};
        $column_info{is_nullable}   = $info->{NULLABLE} ? 1 : 0;
        $column_info{default_value} = $info->{COLUMN_DEF};
        my $col_name = $info->{COLUMN_NAME};
        $col_name =~ s/^\"(.*)\"$/$1/;

        $result{$col_name} = \%column_info;
      }
    } catch {
      $caught = 1;
    };
    return \%result if !$caught && scalar keys %result;
  }

  my %result;
  my $sth = $dbh->prepare($self->sql_maker->select($table, undef, \'1 = 0'));
  $sth->execute;
  my @columns = @{$sth->{NAME_lc}};
  for my $i ( 0 .. $#columns ){
    my %column_info;
    $column_info{data_type} = $sth->{TYPE}->[$i];
    $column_info{size} = $sth->{PRECISION}->[$i];
    $column_info{is_nullable} = $sth->{NULLABLE}->[$i] ? 1 : 0;

    if ($column_info{data_type} =~ m/^(.*?)\((.*?)\)$/) {
      $column_info{data_type} = $1;
      $column_info{size}    = $2;
    }

    $result{$columns[$i]} = \%column_info;
  }
  $sth->finish;

  foreach my $col (keys %result) {
    my $colinfo = $result{$col};
    my $type_num = $colinfo->{data_type};
    my $type_name;
    if(defined $type_num && $dbh->can('type_info')) {
      my $type_info = $dbh->type_info($type_num);
      $type_name = $type_info->{TYPE_NAME} if $type_info;
      $colinfo->{data_type} = $type_name if $type_name;
    }
  }

  return \%result;
}

sub columns_info_for {
  my ($self, $table) = @_;
  $self->_dbh_columns_info_for ($self->_get_dbh, $table);
}

=head2 last_insert_id

Return the row id of the last insert.

=cut

sub _dbh_last_insert_id {
    my ($self, $dbh, $source, $col) = @_;

    my $id = try { $dbh->last_insert_id (undef, undef, $source->name, $col) };

    return $id if defined $id;

    my $class = ref $self;
    $self->throw_exception ("No storage specific _dbh_last_insert_id() method implemented in $class, and the generic DBI::last_insert_id() failed");
}

sub last_insert_id {
  my $self = shift;
  $self->_dbh_last_insert_id ($self->_dbh, @_);
}

=head2 _native_data_type

=over 4

=item Arguments: $type_name

=back

This API is B<EXPERIMENTAL>, will almost definitely change in the future, and
currently only used by L<::AutoCast|DBIx::Class::Storage::DBI::AutoCast> and
L<::Sybase::ASE|DBIx::Class::Storage::DBI::Sybase::ASE>.

The default implementation returns C<undef>, implement in your Storage driver if
you need this functionality.

Should map types from other databases to the native RDBMS type, for example
C<VARCHAR2> to C<VARCHAR>.

Types with modifiers should map to the underlying data type. For example,
C<INTEGER AUTO_INCREMENT> should become C<INTEGER>.

Composite types should map to the container type, for example
C<ENUM(foo,bar,baz)> becomes C<ENUM>.

=cut

sub _native_data_type {
  #my ($self, $data_type) = @_;
  return undef
}

# Check if placeholders are supported at all
sub _placeholders_supported {
  my $self = shift;
  my $dbh  = $self->_get_dbh;

  # some drivers provide a $dbh attribute (e.g. Sybase and $dbh->{syb_dynamic_supported})
  # but it is inaccurate more often than not
  return try {
    local $dbh->{PrintError} = 0;
    local $dbh->{RaiseError} = 1;
    $dbh->do('select ?', {}, 1);
    1;
  }
  catch {
    0;
  };
}

# Check if placeholders bound to non-string types throw exceptions
#
sub _typeless_placeholders_supported {
  my $self = shift;
  my $dbh  = $self->_get_dbh;

  return try {
    local $dbh->{PrintError} = 0;
    local $dbh->{RaiseError} = 1;
    # this specifically tests a bind that is NOT a string
    $dbh->do('select 1 where 1 = ?', {}, 1);
    1;
  }
  catch {
    0;
  };
}

=head2 sqlt_type

Returns the database driver name.

=cut

sub sqlt_type {
  shift->_get_dbh->{Driver}->{Name};
}

=head2 bind_attribute_by_data_type

Given a datatype from column info, returns a database specific bind
attribute for C<< $dbh->bind_param($val,$attribute) >> or nothing if we will
let the database planner just handle it.

Generally only needed for special case column types, like bytea in postgres.

=cut

sub bind_attribute_by_data_type {
    return;
}

=head2 is_datatype_numeric

Given a datatype from column_info, returns a boolean value indicating if
the current RDBMS considers it a numeric value. This controls how
L<DBIx::Class::Row/set_column> decides whether to mark the column as
dirty - when the datatype is deemed numeric a C<< != >> comparison will
be performed instead of the usual C<eq>.

=cut

sub is_datatype_numeric {
  my ($self, $dt) = @_;

  return 0 unless $dt;

  return $dt =~ /^ (?:
    numeric | int(?:eger)? | (?:tiny|small|medium|big)int | dec(?:imal)? | real | float | double (?: \s+ precision)? | (?:big)?serial
  ) $/ix;
}


=head2 create_ddl_dir

=over 4

=item Arguments: $schema \@databases, $version, $directory, $preversion, \%sqlt_args

=back

Creates a SQL file based on the Schema, for each of the specified
database engines in C<\@databases> in the given directory.
(note: specify L<SQL::Translator> names, not L<DBI> driver names).

Given a previous version number, this will also create a file containing
the ALTER TABLE statements to transform the previous schema into the
current one. Note that these statements may contain C<DROP TABLE> or
C<DROP COLUMN> statements that can potentially destroy data.

The file names are created using the C<ddl_filename> method below, please
override this method in your schema if you would like a different file
name format. For the ALTER file, the same format is used, replacing
$version in the name with "$preversion-$version".

See L<SQL::Translator/METHODS> for a list of values for C<\%sqlt_args>.
The most common value for this would be C<< { add_drop_table => 1 } >>
to have the SQL produced include a C<DROP TABLE> statement for each table
created. For quoting purposes supply C<quote_table_names> and
C<quote_field_names>.

If no arguments are passed, then the following default values are assumed:

=over 4

=item databases  - ['MySQL', 'SQLite', 'PostgreSQL']

=item version    - $schema->schema_version

=item directory  - './'

=item preversion - <none>

=back

By default, C<\%sqlt_args> will have

 { add_drop_table => 1, ignore_constraint_names => 1, ignore_index_names => 1 }

merged with the hash passed in. To disable any of those features, pass in a
hashref like the following

 { ignore_constraint_names => 0, # ... other options }


WARNING: You are strongly advised to check all SQL files created, before applying
them.

=cut

sub create_ddl_dir {
  my ($self, $schema, $databases, $version, $dir, $preversion, $sqltargs) = @_;

  unless ($dir) {
    carp "No directory given, using ./\n";
    $dir = './';
  } else {
      -d $dir
        or
      make_path ("$dir")  # make_path does not like objects (i.e. Path::Class::Dir)
        or
      $self->throw_exception(
        "Failed to create '$dir': " . ($! || $@ || 'error unknow')
      );
  }

  $self->throw_exception ("Directory '$dir' does not exist\n") unless(-d $dir);

  $databases ||= ['MySQL', 'SQLite', 'PostgreSQL'];
  $databases = [ $databases ] if(ref($databases) ne 'ARRAY');

  my $schema_version = $schema->schema_version || '1.x';
  $version ||= $schema_version;

  $sqltargs = {
    add_drop_table => 1,
    ignore_constraint_names => 1,
    ignore_index_names => 1,
    %{$sqltargs || {}}
  };

  unless (DBIx::Class::Optional::Dependencies->req_ok_for ('deploy')) {
    $self->throw_exception("Can't create a ddl file without " . DBIx::Class::Optional::Dependencies->req_missing_for ('deploy') );
  }

  my $sqlt = SQL::Translator->new( $sqltargs );

  $sqlt->parser('SQL::Translator::Parser::DBIx::Class');
  my $sqlt_schema = $sqlt->translate({ data => $schema })
    or $self->throw_exception ($sqlt->error);

  foreach my $db (@$databases) {
    $sqlt->reset();
    $sqlt->{schema} = $sqlt_schema;
    $sqlt->producer($db);

    my $file;
    my $filename = $schema->ddl_filename($db, $version, $dir);
    if (-e $filename && ($version eq $schema_version )) {
      # if we are dumping the current version, overwrite the DDL
      carp "Overwriting existing DDL file - $filename";
      unlink($filename);
    }

    my $output = $sqlt->translate;
    if(!$output) {
      carp("Failed to translate to $db, skipping. (" . $sqlt->error . ")");
      next;
    }
    if(!open($file, ">$filename")) {
      $self->throw_exception("Can't open $filename for writing ($!)");
      next;
    }
    print $file $output;
    close($file);

    next unless ($preversion);

    require SQL::Translator::Diff;

    my $prefilename = $schema->ddl_filename($db, $preversion, $dir);
    if(!-e $prefilename) {
      carp("No previous schema file found ($prefilename)");
      next;
    }

    my $difffile = $schema->ddl_filename($db, $version, $dir, $preversion);
    if(-e $difffile) {
      carp("Overwriting existing diff file - $difffile");
      unlink($difffile);
    }

    my $source_schema;
    {
      my $t = SQL::Translator->new($sqltargs);
      $t->debug( 0 );
      $t->trace( 0 );

      $t->parser( $db )
        or $self->throw_exception ($t->error);

      my $out = $t->translate( $prefilename )
        or $self->throw_exception ($t->error);

      $source_schema = $t->schema;

      $source_schema->name( $prefilename )
        unless ( $source_schema->name );
    }

    # The "new" style of producers have sane normalization and can support
    # diffing a SQL file against a DBIC->SQLT schema. Old style ones don't
    # And we have to diff parsed SQL against parsed SQL.
    my $dest_schema = $sqlt_schema;

    unless ( "SQL::Translator::Producer::$db"->can('preprocess_schema') ) {
      my $t = SQL::Translator->new($sqltargs);
      $t->debug( 0 );
      $t->trace( 0 );

      $t->parser( $db )
        or $self->throw_exception ($t->error);

      my $out = $t->translate( $filename )
        or $self->throw_exception ($t->error);

      $dest_schema = $t->schema;

      $dest_schema->name( $filename )
        unless $dest_schema->name;
    }

    my $diff = SQL::Translator::Diff::schema_diff($source_schema, $db,
                                                  $dest_schema,   $db,
                                                  $sqltargs
                                                 );
    if(!open $file, ">$difffile") {
      $self->throw_exception("Can't write to $difffile ($!)");
      next;
    }
    print $file $diff;
    close($file);
  }
}

=head2 deployment_statements

=over 4

=item Arguments: $schema, $type, $version, $directory, $sqlt_args

=back

Returns the statements used by L</deploy> and L<DBIx::Class::Schema/deploy>.

The L<SQL::Translator> (not L<DBI>) database driver name can be explicitly
provided in C<$type>, otherwise the result of L</sqlt_type> is used as default.

C<$directory> is used to return statements from files in a previously created
L</create_ddl_dir> directory and is optional. The filenames are constructed
from L<DBIx::Class::Schema/ddl_filename>, the schema name and the C<$version>.

If no C<$directory> is specified then the statements are constructed on the
fly using L<SQL::Translator> and C<$version> is ignored.

See L<SQL::Translator/METHODS> for a list of values for C<$sqlt_args>.

=cut

sub deployment_statements {
  my ($self, $schema, $type, $version, $dir, $sqltargs) = @_;
  $type ||= $self->sqlt_type;
  $version ||= $schema->schema_version || '1.x';
  $dir ||= './';
  my $filename = $schema->ddl_filename($type, $version, $dir);
  if(-f $filename)
  {
      my $file;
      open($file, "<$filename")
        or $self->throw_exception("Can't open $filename ($!)");
      my @rows = <$file>;
      close($file);
      return join('', @rows);
  }

  unless (DBIx::Class::Optional::Dependencies->req_ok_for ('deploy') ) {
    $self->throw_exception("Can't deploy without a ddl_dir or " . DBIx::Class::Optional::Dependencies->req_missing_for ('deploy') );
  }

  # sources needs to be a parser arg, but for simplicty allow at top level
  # coming in
  $sqltargs->{parser_args}{sources} = delete $sqltargs->{sources}
      if exists $sqltargs->{sources};

  my $tr = SQL::Translator->new(
    producer => "SQL::Translator::Producer::${type}",
    %$sqltargs,
    parser => 'SQL::Translator::Parser::DBIx::Class',
    data => $schema,
  );

  my @ret;
  my $wa = wantarray;
  if ($wa) {
    @ret = $tr->translate;
  }
  else {
    $ret[0] = $tr->translate;
  }

  $self->throw_exception( 'Unable to produce deployment statements: ' . $tr->error)
    unless (@ret && defined $ret[0]);

  return $wa ? @ret : $ret[0];
}

sub deploy {
  my ($self, $schema, $type, $sqltargs, $dir) = @_;
  my $deploy = sub {
    my $line = shift;
    return if($line =~ /^--/);
    return if(!$line);
    # next if($line =~ /^DROP/m);
    return if($line =~ /^BEGIN TRANSACTION/m);
    return if($line =~ /^COMMIT/m);
    return if $line =~ /^\s+$/; # skip whitespace only
    $self->_query_start($line);
    try {
      # do a dbh_do cycle here, as we need some error checking in
      # place (even though we will ignore errors)
      $self->dbh_do (sub { $_[1]->do($line) });
    } catch {
      carp qq{$_ (running "${line}")};
    };
    $self->_query_end($line);
  };
  my @statements = $schema->deployment_statements($type, undef, $dir, { %{ $sqltargs || {} }, no_comments => 1 } );
  if (@statements > 1) {
    foreach my $statement (@statements) {
      $deploy->( $statement );
    }
  }
  elsif (@statements == 1) {
    foreach my $line ( split(";\n", $statements[0])) {
      $deploy->( $line );
    }
  }
}

=head2 datetime_parser

Returns the datetime parser class

=cut

sub datetime_parser {
  my $self = shift;
  return $self->{datetime_parser} ||= do {
    $self->build_datetime_parser(@_);
  };
}

=head2 datetime_parser_type

Defines (returns) the datetime parser class - currently hardwired to
L<DateTime::Format::MySQL>

=cut

sub datetime_parser_type { "DateTime::Format::MySQL"; }

=head2 build_datetime_parser

See L</datetime_parser>

=cut

sub build_datetime_parser {
  my $self = shift;
  my $type = $self->datetime_parser_type(@_);
  $self->ensure_class_loaded ($type);
  return $type;
}


=head2 is_replicating

A boolean that reports if a particular L<DBIx::Class::Storage::DBI> is set to
replicate from a master database.  Default is undef, which is the result
returned by databases that don't support replication.

=cut

sub is_replicating {
    return;

}

=head2 lag_behind_master

Returns a number that represents a certain amount of lag behind a master db
when a given storage is replicating.  The number is database dependent, but
starts at zero and increases with the amount of lag. Default in undef

=cut

sub lag_behind_master {
    return;
}

=head2 relname_to_table_alias

=over 4

=item Arguments: $relname, $join_count

=back

L<DBIx::Class> uses L<DBIx::Class::Relationship> names as table aliases in
queries.

This hook is to allow specific L<DBIx::Class::Storage> drivers to change the
way these aliases are named.

The default behavior is C<< "$relname_$join_count" if $join_count > 1 >>,
otherwise C<"$relname">.

=cut

sub relname_to_table_alias {
  my ($self, $relname, $join_count) = @_;

  my $alias = ($join_count && $join_count > 1 ?
    join('_', $relname, $join_count) : $relname);

  return $alias;
}

1;

=head1 USAGE NOTES

=head2 DBIx::Class and AutoCommit

DBIx::Class can do some wonderful magic with handling exceptions,
disconnections, and transactions when you use C<< AutoCommit => 1 >>
(the default) combined with C<txn_do> for transaction support.

If you set C<< AutoCommit => 0 >> in your connect info, then you are always
in an assumed transaction between commits, and you're telling us you'd
like to manage that manually.  A lot of the magic protections offered by
this module will go away.  We can't protect you from exceptions due to database
disconnects because we don't know anything about how to restart your
transactions.  You're on your own for handling all sorts of exceptional
cases if you choose the C<< AutoCommit => 0 >> path, just as you would
be with raw DBI.


=head1 AUTHORS

Matt S. Trout <mst@shadowcatsystems.co.uk>

Andy Grundman <andy@hybridized.org>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut
