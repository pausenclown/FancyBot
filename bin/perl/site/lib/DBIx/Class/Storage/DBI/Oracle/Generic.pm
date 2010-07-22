package DBIx::Class::Storage::DBI::Oracle::Generic;

use strict;
use warnings;
use Scope::Guard ();
use Context::Preserve 'preserve_context';
use Try::Tiny;
use namespace::clean;

=head1 NAME

DBIx::Class::Storage::DBI::Oracle::Generic - Oracle Support for DBIx::Class

=head1 SYNOPSIS

  # In your result (table) classes
  use base 'DBIx::Class::Core';
  __PACKAGE__->add_columns({ id => { sequence => 'mysequence', auto_nextval => 1 } });
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->sequence('mysequence');

  # Somewhere in your Code
  # add some data to a table with a hierarchical relationship
  $schema->resultset('Person')->create ({
        firstname => 'foo',
        lastname => 'bar',
        children => [
            {
                firstname => 'child1',
                lastname => 'bar',
                children => [
                    {
                        firstname => 'grandchild',
                        lastname => 'bar',
                    }
                ],
            },
            {
                firstname => 'child2',
                lastname => 'bar',
            },
        ],
    });

  # select from the hierarchical relationship
  my $rs = $schema->resultset('Person')->search({},
    {
      'start_with' => { 'firstname' => 'foo', 'lastname' => 'bar' },
      'connect_by' => { 'parentid' => { '-prior' => \'persionid' },
      'order_siblings_by' => { -asc => 'name' },
    };
  );

  # this will select the whole tree starting from person "foo bar", creating
  # following query:
  # SELECT
  #     me.persionid me.firstname, me.lastname, me.parentid
  # FROM
  #     person me
  # START WITH
  #     firstname = 'foo' and lastname = 'bar'
  # CONNECT BY
  #     parentid = prior persionid
  # ORDER SIBLINGS BY
  #     firstname ASC

=head1 DESCRIPTION

This class implements base Oracle support. The subclass
L<DBIx::Class::Storage::DBI::Oracle::WhereJoins> is for C<(+)> joins in Oracle
versions before 9.

=head1 METHODS

=cut

use base qw/DBIx::Class::Storage::DBI/;
use mro 'c3';

__PACKAGE__->sql_maker_class('DBIx::Class::SQLAHacks::Oracle');

sub deployment_statements {
  my $self = shift;;
  my ($schema, $type, $version, $dir, $sqltargs, @rest) = @_;

  $sqltargs ||= {};
  my $quote_char = $self->schema->storage->sql_maker->quote_char;
  $sqltargs->{quote_table_names} = $quote_char ? 1 : 0;
  $sqltargs->{quote_field_names} = $quote_char ? 1 : 0;

  if (
    ! exists $sqltargs->{producer_args}{oracle_version}
      and
    my $dver = $self->_server_info->{dbms_version}
  ) {
    $sqltargs->{producer_args}{oracle_version} = $dver;
  }

  $self->next::method($schema, $type, $version, $dir, $sqltargs, @rest);
}

sub _dbh_last_insert_id {
  my ($self, $dbh, $source, @columns) = @_;
  my @ids = ();
  foreach my $col (@columns) {
    my $seq = ($source->column_info($col)->{sequence} ||= $self->get_autoinc_seq($source,$col));
    my $id = $self->_sequence_fetch( 'currval', $seq );
    push @ids, $id;
  }
  return @ids;
}

sub _dbh_get_autoinc_seq {
  my ($self, $dbh, $source, $col) = @_;

  my $sql_maker = $self->sql_maker;

  my $source_name;
  if ( ref $source->name eq 'SCALAR' ) {
    $source_name = ${$source->name};
  }
  else {
    $source_name = $source->name;
  }
  $source_name = uc($source_name) unless $sql_maker->quote_char;

  # trigger_body is a LONG
  local $dbh->{LongReadLen} = 64 * 1024 if ($dbh->{LongReadLen} < 64 * 1024);

  # disable default bindtype
  local $sql_maker->{bindtype} = 'normal';

  # look up the correct sequence automatically
  my ( $schema, $table ) = $source_name =~ /(\w+)\.(\w+)/;
  my ($sql, @bind) = $sql_maker->select (
    'ALL_TRIGGERS',
    ['trigger_body', 'table_owner'],
    {
      $schema ? (owner => $schema) : (),
      table_name => $table || $source_name,
      triggering_event => { -like => '%INSERT%' },
      status => 'ENABLED',
     },
  );
  my $sth = $dbh->prepare($sql);
  $sth->execute (@bind);

  while (my ($insert_trigger, $schema) = $sth->fetchrow_array) {
    my ($seq_name) = $insert_trigger =~ m!("?[.\w"]+?"?)\.nextval!i;

    next unless $seq_name;

    if ($seq_name !~ /\./) {
      $seq_name = join '.' => map $self->sql_maker->_quote($_), $schema, $seq_name;
    }

    return $seq_name;
  }
  $self->throw_exception("Unable to find a sequence %INSERT% trigger on table '$source_name'.");
}

sub _sequence_fetch {
  my ( $self, $type, $seq ) = @_;
  my ($id) = $self->_get_dbh->selectrow_array("SELECT ${seq}.${type} FROM DUAL");
  return $id;
}

sub _ping {
  my $self = shift;

  my $dbh = $self->_dbh or return 0;

  local $dbh->{RaiseError} = 1;
  local $dbh->{PrintError} = 0;

  return try {
    $dbh->do('select 1 from dual');
    1;
  } catch {
    0;
  };
}

sub _dbh_execute {
  my $self = shift;
  my ($dbh, $op, $extra_bind, $ident, $bind_attributes, @args) = @_;

  my (@res, $tried);
  my $wantarray = wantarray();
  my $next = $self->next::can;
  do {
    try {
      my $exec = sub { $self->$next($dbh, $op, $extra_bind, $ident, $bind_attributes, @args) };

      if (!defined $wantarray) {
        $exec->();
      }
      elsif (! $wantarray) {
        $res[0] = $exec->();
      }
      else {
        @res = $exec->();
      }

      $tried++;
    }
    catch {
      if (! $tried and $_ =~ /ORA-01003/) {
        # ORA-01003: no statement parsed (someone changed the table somehow,
        # invalidating your cursor.)
        my ($sql, $bind) = $self->_prep_for_execute($op, $extra_bind, $ident, \@args);
        delete $dbh->{CachedKids}{$sql};
      }
      else {
        $self->throw_exception($_);
      }
    };
  } while (! $tried++);

  return $wantarray ? @res : $res[0];
}

=head2 get_autoinc_seq

Returns the sequence name for an autoincrement column

=cut

sub get_autoinc_seq {
  my ($self, $source, $col) = @_;

  $self->dbh_do('_dbh_get_autoinc_seq', $source, $col);
}

=head2 datetime_parser_type

This sets the proper DateTime::Format module for use with
L<DBIx::Class::InflateColumn::DateTime>.

=cut

sub datetime_parser_type { return "DateTime::Format::Oracle"; }

=head2 connect_call_datetime_setup

Used as:

    on_connect_call => 'datetime_setup'

In L<connect_info|DBIx::Class::Storage::DBI/connect_info> to set the session nls
date, and timestamp values for use with L<DBIx::Class::InflateColumn::DateTime>
and the necessary environment variables for L<DateTime::Format::Oracle>, which
is used by it.

Maximum allowable precision is used, unless the environment variables have
already been set.

These are the defaults used:

  $ENV{NLS_DATE_FORMAT}         ||= 'YYYY-MM-DD HH24:MI:SS';
  $ENV{NLS_TIMESTAMP_FORMAT}    ||= 'YYYY-MM-DD HH24:MI:SS.FF';
  $ENV{NLS_TIMESTAMP_TZ_FORMAT} ||= 'YYYY-MM-DD HH24:MI:SS.FF TZHTZM';

To get more than second precision with L<DBIx::Class::InflateColumn::DateTime>
for your timestamps, use something like this:

  use Time::HiRes 'time';
  my $ts = DateTime->from_epoch(epoch => time);

=cut

sub connect_call_datetime_setup {
  my $self = shift;

  my $date_format = $ENV{NLS_DATE_FORMAT} ||= 'YYYY-MM-DD HH24:MI:SS';
  my $timestamp_format = $ENV{NLS_TIMESTAMP_FORMAT} ||=
    'YYYY-MM-DD HH24:MI:SS.FF';
  my $timestamp_tz_format = $ENV{NLS_TIMESTAMP_TZ_FORMAT} ||=
    'YYYY-MM-DD HH24:MI:SS.FF TZHTZM';

  $self->_do_query(
    "alter session set nls_date_format = '$date_format'"
  );
  $self->_do_query(
    "alter session set nls_timestamp_format = '$timestamp_format'"
  );
  $self->_do_query(
    "alter session set nls_timestamp_tz_format='$timestamp_tz_format'"
  );
}

=head2 source_bind_attributes

Handle LOB types in Oracle.  Under a certain size (4k?), you can get away
with the driver assuming your input is the deprecated LONG type if you
encode it as a hex string.  That ain't gonna fly at larger values, where
you'll discover you have to do what this does.

This method had to be overridden because we need to set ora_field to the
actual column, and that isn't passed to the call (provided by Storage) to
bind_attribute_by_data_type.

According to L<DBD::Oracle>, the ora_field isn't always necessary, but
adding it doesn't hurt, and will save your bacon if you're modifying a
table with more than one LOB column.

=cut

sub source_bind_attributes
{
  require DBD::Oracle;
  my $self = shift;
  my($source) = @_;

  my %bind_attributes;

  foreach my $column ($source->columns) {
    my $data_type = $source->column_info($column)->{data_type} || '';
    next unless $data_type;

    my %column_bind_attrs = $self->bind_attribute_by_data_type($data_type);

    if ($data_type =~ /^[BC]LOB$/i) {
      if ($DBD::Oracle::VERSION eq '1.23') {
        $self->throw_exception(
"BLOB/CLOB support in DBD::Oracle == 1.23 is broken, use an earlier or later ".
"version.\n\nSee: https://rt.cpan.org/Public/Bug/Display.html?id=46016\n"
        );
      }

      $column_bind_attrs{'ora_type'} = uc($data_type) eq 'CLOB'
        ? DBD::Oracle::ORA_CLOB()
        : DBD::Oracle::ORA_BLOB()
      ;
      $column_bind_attrs{'ora_field'} = $column;
    }

    $bind_attributes{$column} = \%column_bind_attrs;
  }

  return \%bind_attributes;
}

sub _svp_begin {
  my ($self, $name) = @_;
  $self->_get_dbh->do("SAVEPOINT $name");
}

# Oracle automatically releases a savepoint when you start another one with the
# same name.
sub _svp_release { 1 }

sub _svp_rollback {
  my ($self, $name) = @_;
  $self->_get_dbh->do("ROLLBACK TO SAVEPOINT $name")
}

=head2 relname_to_table_alias

L<DBIx::Class> uses L<DBIx::Class::Relationship> names as table aliases in
queries.

Unfortunately, Oracle doesn't support identifiers over 30 chars in length, so
the L<DBIx::Class::Relationship> name is shortened and appended with half of an
MD5 hash.

See L<DBIx::Class::Storage/"relname_to_table_alias">.

=cut

sub relname_to_table_alias {
  my $self = shift;
  my ($relname, $join_count) = @_;

  my $alias = $self->next::method(@_);

  return $self->sql_maker->_shorten_identifier($alias, [$relname]);
}

=head2 with_deferred_fk_checks

Runs a coderef between:

  alter session set constraints = deferred
  ...
  alter session set constraints = immediate

to defer foreign key checks.

Constraints must be declared C<DEFERRABLE> for this to work.

=cut

sub with_deferred_fk_checks {
  my ($self, $sub) = @_;

  my $txn_scope_guard = $self->txn_scope_guard;

  $self->_do_query('alter session set constraints = deferred');

  my $sg = Scope::Guard->new(sub {
    $self->_do_query('alter session set constraints = immediate');
  });

  return
    preserve_context { $sub->() } after => sub { $txn_scope_guard->commit };
}

=head1 ATTRIBUTES

Following additional attributes can be used in resultsets.

=head2 connect_by or connect_by_nocycle

=over 4

=item Value: \%connect_by

=back

A hashref of conditions used to specify the relationship between parent rows
and child rows of the hierarchy.


  connect_by => { parentid => 'prior personid' }

  # adds a connect by statement to the query:
  # SELECT
  #     me.persionid me.firstname, me.lastname, me.parentid
  # FROM
  #     person me
  # CONNECT BY
  #     parentid = prior persionid
  

  connect_by_nocycle => { parentid => 'prior personid' }

  # adds a connect by statement to the query:
  # SELECT
  #     me.persionid me.firstname, me.lastname, me.parentid
  # FROM
  #     person me
  # CONNECT BY NOCYCLE
  #     parentid = prior persionid


=head2 start_with

=over 4

=item Value: \%condition

=back

A hashref of conditions which specify the root row(s) of the hierarchy.

It uses the same syntax as L<DBIx::Class::ResultSet/search>

  start_with => { firstname => 'Foo', lastname => 'Bar' }

  # SELECT
  #     me.persionid me.firstname, me.lastname, me.parentid
  # FROM
  #     person me
  # START WITH
  #     firstname = 'foo' and lastname = 'bar'
  # CONNECT BY
  #     parentid = prior persionid

=head2 order_siblings_by

=over 4

=item Value: ($order_siblings_by | \@order_siblings_by)

=back

Which column(s) to order the siblings by.

It uses the same syntax as L<DBIx::Class::ResultSet/order_by>

  'order_siblings_by' => 'firstname ASC'

  # SELECT
  #     me.persionid me.firstname, me.lastname, me.parentid
  # FROM
  #     person me
  # CONNECT BY
  #     parentid = prior persionid
  # ORDER SIBLINGS BY
  #     firstname ASC

=head1 AUTHOR

See L<DBIx::Class/CONTRIBUTORS>.

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

1;
