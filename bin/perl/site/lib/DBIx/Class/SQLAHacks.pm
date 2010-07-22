package # Hide from PAUSE
  DBIx::Class::SQLAHacks;

# This module is a subclass of SQL::Abstract::Limit and includes a number
# of DBIC-specific workarounds, not yet suitable for inclusion into the
# SQLA core

use base qw/SQL::Abstract::Limit/;
use strict;
use warnings;
use List::Util 'first';
use Sub::Name 'subname';
use namespace::clean;
use Carp::Clan qw/^DBIx::Class|^SQL::Abstract|^Try::Tiny/;

BEGIN {
  # reinstall the carp()/croak() functions imported into SQL::Abstract
  # as Carp and Carp::Clan do not like each other much
  no warnings qw/redefine/;
  no strict qw/refs/;
  for my $f (qw/carp croak/) {

    my $orig = \&{"SQL::Abstract::$f"};
    *{"SQL::Abstract::$f"} = subname "SQL::Abstract::$f" =>
      sub {
        if (Carp::longmess() =~ /DBIx::Class::SQLAHacks::[\w]+ .+? called \s at/x) {
          __PACKAGE__->can($f)->(@_);
        }
        else {
          goto $orig;
        }
      };
  }
}

# the "oh noes offset/top without limit" constant
# limited to 32 bits for sanity (and since it is fed
# to sprintf %u)
sub __max_int { 0xFFFFFFFF };


# Tries to determine limit dialect.
#
sub new {
  my $self = shift->SUPER::new(@_);

  # This prevents the caching of $dbh in S::A::L, I believe
  # If limit_dialect is a ref (like a $dbh), go ahead and replace
  #   it with what it resolves to:
  $self->{limit_dialect} = $self->_find_syntax($self->{limit_dialect})
    if ref $self->{limit_dialect};

  $self;
}

# !!! THIS IS ALSO HORRIFIC !!! /me ashamed
#
# Generates inner/outer select lists for various limit dialects
# which result in one or more subqueries (e.g. RNO, Top, RowNum)
# Any non-root-table columns need to have their table qualifier
# turned into a column alias (otherwise names in subqueries clash
# and/or lose their source table)
#
# Returns inner/outer strings of SQL QUOTED selectors with aliases
# (to be used in whatever select statement), and an alias index hashref
# of QUOTED SEL => QUOTED ALIAS pairs (to maybe be used for string-subst
# higher up).
# If an order_by is supplied, the inner select needs to bring out columns
# used in implicit (non-selected) orders, and the order condition itself
# needs to be realiased to the proper names in the outer query. Thus we
# also return a hashref (order doesn't matter) of QUOTED EXTRA-SEL =>
# QUOTED ALIAS pairs, which is a list of extra selectors that do *not*
# exist in the original select list

sub _subqueried_limit_attrs {
  my ($self, $rs_attrs) = @_;

  croak 'Limit dialect implementation usable only in the context of DBIC (missing $rs_attrs)'
    unless ref ($rs_attrs) eq 'HASH';

  my ($re_sep, $re_alias) = map { quotemeta $_ } (
    $self->name_sep || '.',
    $rs_attrs->{alias},
  );

  # correlate select and as, build selection index
  my (@sel, $in_sel_index);
  for my $i (0 .. $#{$rs_attrs->{select}}) {

    my $s = $rs_attrs->{select}[$i];
    my $sql_sel = $self->_recurse_fields ($s);
    my $sql_alias = (ref $s) eq 'HASH' ? $s->{-as} : undef;


    push @sel, {
      sql => $sql_sel,
      unquoted_sql => do { local $self->{quote_char}; $self->_recurse_fields ($s) },
      as =>
        $sql_alias
          ||
        $rs_attrs->{as}[$i]
          ||
        croak "Select argument $i ($s) without corresponding 'as'"
      ,
    };

    $in_sel_index->{$sql_sel}++;
    $in_sel_index->{$self->_quote ($sql_alias)}++ if $sql_alias;

    # record unqualified versions too, so we do not have
    # to reselect the same column twice (in qualified and
    # unqualified form)
    if (! ref $s && $sql_sel =~ / $re_sep (.+) $/x) {
      $in_sel_index->{$1}++;
    }
  }


  # re-alias and remove any name separators from aliases,
  # unless we are dealing with the current source alias
  # (which will transcend the subqueries as it is necessary
  # for possible further chaining)
  my (@in_sel, @out_sel, %renamed);
  for my $node (@sel) {
    if (first { $_ =~ / (?<! $re_alias ) $re_sep /x } ($node->{as}, $node->{unquoted_sql}) )  {
      $node->{as} = $self->_unqualify_colname($node->{as});
      my $quoted_as = $self->_quote($node->{as});
      push @in_sel, sprintf '%s AS %s', $node->{sql}, $quoted_as;
      push @out_sel, $quoted_as;
      $renamed{$node->{sql}} = $quoted_as;
    }
    else {
      push @in_sel, $node->{sql};
      push @out_sel, $self->_quote ($node->{as});
    }
  }

  # see if the order gives us anything
  my %extra_order_sel;
  for my $chunk ($self->_order_by_chunks ($rs_attrs->{order_by})) {
    # order with bind
    $chunk = $chunk->[0] if (ref $chunk) eq 'ARRAY';
    $chunk =~ s/\s+ (?: ASC|DESC ) \s* $//ix;

    next if $in_sel_index->{$chunk};

    $extra_order_sel{$chunk} ||= $self->_quote (
      'ORDER__BY__' . scalar keys %extra_order_sel
    );
  }

  return (
    (map { join (', ', @$_ ) } (
      \@in_sel,
      \@out_sel)
    ),
    \%renamed,
    keys %extra_order_sel ? \%extra_order_sel : (),
  );
}

sub _unqualify_colname {
  my ($self, $fqcn) = @_;
  my $re_sep = quotemeta($self->name_sep || '.');
  $fqcn =~ s/ $re_sep /__/xg;
  return $fqcn;
}

# ANSI standard Limit/Offset implementation. DB2 and MSSQL >= 2005 use this
sub _RowNumberOver {
  my ($self, $sql, $rs_attrs, $rows, $offset ) = @_;

  # mangle the input sql as we will be replacing the selector
  $sql =~ s/^ \s* SELECT \s+ .+? \s+ (?= \b FROM \b )//ix
    or croak "Unrecognizable SELECT: $sql";

  # get selectors, and scan the order_by (if any)
  my ($in_sel, $out_sel, $alias_map, $extra_order_sel)
    = $self->_subqueried_limit_attrs ( $rs_attrs );

  # make up an order if none exists
  my $requested_order = (delete $rs_attrs->{order_by}) || $self->_rno_default_order;
  my $rno_ord = $self->_order_by ($requested_order);

  # this is the order supplement magic
  my $mid_sel = $out_sel;
  if ($extra_order_sel) {
    for my $extra_col (sort
      { $extra_order_sel->{$a} cmp $extra_order_sel->{$b} }
      keys %$extra_order_sel
    ) {
      $in_sel .= sprintf (', %s AS %s',
        $extra_col,
        $extra_order_sel->{$extra_col},
      );

      $mid_sel .= ', ' . $extra_order_sel->{$extra_col};
    }
  }

  # and this is order re-alias magic
  for ($extra_order_sel, $alias_map) {
    for my $col (keys %$_) {
      my $re_col = quotemeta ($col);
      $rno_ord =~ s/$re_col/$_->{$col}/;
    }
  }

  # whatever is left of the order_by (only where is processed at this point)
  my $group_having = $self->_parse_rs_attrs($rs_attrs);

  my $qalias = $self->_quote ($rs_attrs->{alias});
  my $idx_name = $self->_quote ('rno__row__index');

  $sql = sprintf (<<EOS, $offset + 1, $offset + $rows, );

SELECT $out_sel FROM (
  SELECT $mid_sel, ROW_NUMBER() OVER( $rno_ord ) AS $idx_name FROM (
    SELECT $in_sel ${sql}${group_having}
  ) $qalias
) $qalias WHERE $idx_name BETWEEN %u AND %u

EOS

  $sql =~ s/\s*\n\s*/ /g;   # easier to read in the debugger
  return $sql;
}

# some databases are happy with OVER (), some need OVER (ORDER BY (SELECT (1)) )
sub _rno_default_order {
  return undef;
}

# Informix specific limit, almost like LIMIT/OFFSET
sub _SkipFirst {
  my ($self, $sql, $rs_attrs, $rows, $offset) = @_;

  $sql =~ s/^ \s* SELECT \s+ //ix
    or croak "Unrecognizable SELECT: $sql";

  return sprintf ('SELECT %s%s%s%s',
    $offset
      ? sprintf ('SKIP %u ', $offset)
      : ''
    ,
    sprintf ('FIRST %u ', $rows),
    $sql,
    $self->_parse_rs_attrs ($rs_attrs),
  );
}

# Firebird specific limit, reverse of _SkipFirst for Informix
sub _FirstSkip {
  my ($self, $sql, $rs_attrs, $rows, $offset) = @_;

  $sql =~ s/^ \s* SELECT \s+ //ix
    or croak "Unrecognizable SELECT: $sql";

  return sprintf ('SELECT %s%s%s%s',
    sprintf ('FIRST %u ', $rows),
    $offset
      ? sprintf ('SKIP %u ', $offset)
      : ''
    ,
    $sql,
    $self->_parse_rs_attrs ($rs_attrs),
  );
}

# WhOracle limits
sub _RowNum {
  my ( $self, $sql, $rs_attrs, $rows, $offset ) = @_;

  # mangle the input sql as we will be replacing the selector
  $sql =~ s/^ \s* SELECT \s+ .+? \s+ (?= \b FROM \b )//ix
    or croak "Unrecognizable SELECT: $sql";

  my ($insel, $outsel) = $self->_subqueried_limit_attrs ($rs_attrs);

  my $qalias = $self->_quote ($rs_attrs->{alias});
  my $idx_name = $self->_quote ('rownum__index');
  my $order_group_having = $self->_parse_rs_attrs($rs_attrs);

  $sql = sprintf (<<EOS, $offset + 1, $offset + $rows, );

SELECT $outsel FROM (
  SELECT $outsel, ROWNUM $idx_name FROM (
    SELECT $insel ${sql}${order_group_having}
  ) $qalias
) $qalias WHERE $idx_name BETWEEN %u AND %u

EOS

  $sql =~ s/\s*\n\s*/ /g;   # easier to read in the debugger
  return $sql;
}

# Crappy Top based Limit/Offset support. Legacy for MSSQL < 2005
sub _Top {
  my ( $self, $sql, $rs_attrs, $rows, $offset ) = @_;

  # mangle the input sql as we will be replacing the selector
  $sql =~ s/^ \s* SELECT \s+ .+? \s+ (?= \b FROM \b )//ix
    or croak "Unrecognizable SELECT: $sql";

  # get selectors
  my ($in_sel, $out_sel, $alias_map, $extra_order_sel)
    = $self->_subqueried_limit_attrs ($rs_attrs);

  my $requested_order = delete $rs_attrs->{order_by};

  my $order_by_requested = $self->_order_by ($requested_order);

  # make up an order unless supplied
  my $inner_order = ($order_by_requested
    ? $requested_order
    : [ map
      { join ('', $rs_attrs->{alias}, $self->{name_sep}||'.', $_ ) }
      ( $rs_attrs->{_rsroot_source_handle}->resolve->_pri_cols )
    ]
  );

  my ($order_by_inner, $order_by_reversed);

  # localise as we already have all the bind values we need
  {
    local $self->{order_bind};
    $order_by_inner = $self->_order_by ($inner_order);

    my @out_chunks;
    for my $ch ($self->_order_by_chunks ($inner_order)) {
      $ch = $ch->[0] if ref $ch eq 'ARRAY';

      $ch =~ s/\s+ ( ASC|DESC ) \s* $//ix;
      my $dir = uc ($1||'ASC');

      push @out_chunks, \join (' ', $ch, $dir eq 'ASC' ? 'DESC' : 'ASC' );
    }

    $order_by_reversed = $self->_order_by (\@out_chunks);
  }

  # this is the order supplement magic
  my $mid_sel = $out_sel;
  if ($extra_order_sel) {
    for my $extra_col (sort
      { $extra_order_sel->{$a} cmp $extra_order_sel->{$b} }
      keys %$extra_order_sel
    ) {
      $in_sel .= sprintf (', %s AS %s',
        $extra_col,
        $extra_order_sel->{$extra_col},
      );

      $mid_sel .= ', ' . $extra_order_sel->{$extra_col};
    }

    # since whatever order bindvals there are, they will be realiased
    # and need to show up in front of the entire initial inner subquery
    # Unshift *from_bind* to make this happen (horrible, horrible, but
    # we don't have another mechanism yet)
    unshift @{$self->{from_bind}}, @{$self->{order_bind}};
  }

  # and this is order re-alias magic
  for my $map ($extra_order_sel, $alias_map) {
    for my $col (keys %$map) {
      my $re_col = quotemeta ($col);
      $_ =~ s/$re_col/$map->{$col}/
        for ($order_by_reversed, $order_by_requested);
    }
  }

  # generate the rest of the sql
  my $grpby_having = $self->_parse_rs_attrs ($rs_attrs);

  my $quoted_rs_alias = $self->_quote ($rs_attrs->{alias});

  $sql = sprintf ('SELECT TOP %u %s %s %s %s',
    $rows + ($offset||0),
    $in_sel,
    $sql,
    $grpby_having,
    $order_by_inner,
  );

  $sql = sprintf ('SELECT TOP %u %s FROM ( %s ) %s %s',
    $rows,
    $mid_sel,
    $sql,
    $quoted_rs_alias,
    $order_by_reversed,
  ) if $offset;

  $sql = sprintf ('SELECT TOP %u %s FROM ( %s ) %s %s',
    $rows,
    $out_sel,
    $sql,
    $quoted_rs_alias,
    $order_by_requested,
  ) if ( ($offset && $order_by_requested) || ($mid_sel ne $out_sel) );

  $sql =~ s/\s*\n\s*/ /g;   # easier to read in the debugger
  return $sql;
}

# This for Sybase ASE, to use SET ROWCOUNT when there is no offset, and
# GenericSubQ otherwise.
sub _RowCountOrGenericSubQ {
  my $self = shift;
  my ($sql, $rs_attrs, $rows, $offset) = @_;

  return $self->_GenericSubQ(@_) if $offset;

  return sprintf <<"EOF", $rows, $sql;
SET ROWCOUNT %d
%s
SET ROWCOUNT 0
EOF
}

# This is the most evil limit "dialect" (more of a hack) for *really*
# stupid databases. It works by ordering the set by some unique column,
# and calculating amount of rows that have a less-er value (thus
# emulating a RowNum-like index). Of course this implies the set can
# only be ordered by a single unique columns.
sub _GenericSubQ {
  my ($self, $sql, $rs_attrs, $rows, $offset) = @_;

  my $root_rsrc = $rs_attrs->{_rsroot_source_handle}->resolve;
  my $root_tbl_name = $root_rsrc->name;

  # mangle the input sql as we will be replacing the selector
  $sql =~ s/^ \s* SELECT \s+ .+? \s+ (?= \b FROM \b )//ix
    or croak "Unrecognizable SELECT: $sql";

  my ($order_by, @rest) = do {
    local $self->{quote_char};
    $self->_order_by_chunks ($rs_attrs->{order_by})
  };

  unless (
    $order_by
      &&
    ! @rest
      &&
    ( ! ref $order_by
        ||
      ( ref $order_by eq 'ARRAY' and @$order_by == 1 )
    )
  ) {
    croak (
      'Generic Subquery Limit does not work on resultsets without an order, or resultsets '
    . 'with complex order criteria (multicolumn and/or functions). Provide a single, '
    . 'unique-column order criteria.'
    );
  }

  ($order_by) = @$order_by if ref $order_by;

  $order_by =~ s/\s+ ( ASC|DESC ) \s* $//ix;
  my $direction = lc ($1 || 'asc');

  my ($unq_sort_col) = $order_by =~ /(?:^|\.)([^\.]+)$/;

  my $inf = $root_rsrc->storage->_resolve_column_info (
    $rs_attrs->{from}, [$order_by, $unq_sort_col]
  );

  my $ord_colinfo = $inf->{$order_by} || croak "Unable to determine source of order-criteria '$order_by'";

  if ($ord_colinfo->{-result_source}->name ne $root_tbl_name) {
    croak "Generic Subquery Limit order criteria can be only based on the root-source '"
        . $root_rsrc->source_name . "' (aliased as '$rs_attrs->{alias}')";
  }

  # make sure order column is qualified
  $order_by = "$rs_attrs->{alias}.$order_by"
    unless $order_by =~ /^$rs_attrs->{alias}\./;

  my $is_u;
  my $ucs = { $root_rsrc->unique_constraints };
  for (values %$ucs ) {
    if (@$_ == 1 && "$rs_attrs->{alias}.$_->[0]" eq $order_by) {
      $is_u++;
      last;
    }
  }
  croak "Generic Subquery Limit order criteria column '$order_by' must be unique (no unique constraint found)"
    unless $is_u;

  my ($in_sel, $out_sel, $alias_map, $extra_order_sel)
    = $self->_subqueried_limit_attrs ($rs_attrs);

  my $cmp_op = $direction eq 'desc' ? '>' : '<';
  my $count_tbl_alias = 'rownum__emulation';

  my $order_sql = $self->_order_by (delete $rs_attrs->{order_by});
  my $group_having_sql = $self->_parse_rs_attrs($rs_attrs);

  # add the order supplement (if any) as this is what will be used for the outer WHERE
  $in_sel .= ", $_" for keys %{$extra_order_sel||{}};

  $sql = sprintf (<<EOS,
SELECT $out_sel
  FROM (
    SELECT $in_sel ${sql}${group_having_sql}
  ) %s
WHERE ( SELECT COUNT(*) FROM %s %s WHERE %s $cmp_op %s ) %s
$order_sql
EOS
    ( map { $self->_quote ($_) } (
      $rs_attrs->{alias},
      $root_tbl_name,
      $count_tbl_alias,
      "$count_tbl_alias.$unq_sort_col",
      $order_by,
    )),
    $offset
      ? sprintf ('BETWEEN %u AND %u', $offset, $offset + $rows - 1)
      : sprintf ('< %u', $rows )
    ,
  );

  $sql =~ s/\s*\n\s*/ /g;   # easier to read in the debugger
  return $sql;
}


# While we're at it, this should make LIMIT queries more efficient,
#  without digging into things too deeply
sub _find_syntax {
  my ($self, $syntax) = @_;
  return $self->{_cached_syntax} ||= $self->SUPER::_find_syntax($syntax);
}

# Quotes table names, handles "limit" dialects (e.g. where rownum between x and
# y)
sub select {
  my ($self, $table, $fields, $where, $rs_attrs, @rest) = @_;

  if (not ref($table) or ref($table) eq 'SCALAR') {
    $table = $self->_quote($table);
  }

  @rest = (-1) unless defined $rest[0];
  croak "LIMIT 0 Does Not Compute" if $rest[0] == 0;
    # and anyway, SQL::Abstract::Limit will cause a barf if we don't first

  my ($sql, @bind) = $self->SUPER::select(
    $table, $self->_recurse_fields($fields), $where, $rs_attrs, @rest
  );
  push @{$self->{where_bind}}, @bind;

# this *must* be called, otherwise extra binds will remain in the sql-maker
  my @all_bind = $self->_assemble_binds;

  return wantarray ? ($sql, @all_bind) : $sql;
}

sub _assemble_binds {
  my $self = shift;
  return map { @{ (delete $self->{"${_}_bind"}) || [] } } (qw/from where having order/);
}

# Quotes table names, and handles default inserts
sub insert {
  my $self = shift;
  my $table = shift;
  $table = $self->_quote($table);

  # SQLA will emit INSERT INTO $table ( ) VALUES ( )
  # which is sadly understood only by MySQL. Change default behavior here,
  # until SQLA2 comes with proper dialect support
  if (! $_[0] or (ref $_[0] eq 'HASH' and !keys %{$_[0]} ) ) {
    my $sql = "INSERT INTO ${table} DEFAULT VALUES";

    if (my $ret = ($_[1]||{})->{returning} ) {
      $sql .= $self->_insert_returning ($ret);
    }

    return $sql;
  }

  $self->SUPER::insert($table, @_);
}

# Just quotes table names.
sub update {
  my $self = shift;
  my $table = shift;
  $table = $self->_quote($table);
  $self->SUPER::update($table, @_);
}

# Just quotes table names.
sub delete {
  my $self = shift;
  my $table = shift;
  $table = $self->_quote($table);
  $self->SUPER::delete($table, @_);
}

sub _emulate_limit {
  my $self = shift;
  # my ( $syntax, $sql, $order, $rows, $offset ) = @_;

  if ($_[3] == -1) {
    return $_[1] . $self->_parse_rs_attrs($_[2]);
  } else {
    return $self->SUPER::_emulate_limit(@_);
  }
}

sub _recurse_fields {
  my ($self, $fields) = @_;
  my $ref = ref $fields;
  return $self->_quote($fields) unless $ref;
  return $$fields if $ref eq 'SCALAR';

  if ($ref eq 'ARRAY') {
    return join(', ', map { $self->_recurse_fields($_) } @$fields);
  }
  elsif ($ref eq 'HASH') {
    my %hash = %$fields;  # shallow copy

    my $as = delete $hash{-as};   # if supplied

    my ($func, $args, @toomany) = %hash;

    # there should be only one pair
    if (@toomany) {
      croak "Malformed select argument - too many keys in hash: " . join (',', keys %$fields );
    }

    if (lc ($func) eq 'distinct' && ref $args eq 'ARRAY' && @$args > 1) {
      croak (
        'The select => { distinct => ... } syntax is not supported for multiple columns.'
       .' Instead please use { group_by => [ qw/' . (join ' ', @$args) . '/ ] }'
       .' or { select => [ qw/' . (join ' ', @$args) . '/ ], distinct => 1 }'
      );
    }

    my $select = sprintf ('%s( %s )%s',
      $self->_sqlcase($func),
      $self->_recurse_fields($args),
      $as
        ? sprintf (' %s %s', $self->_sqlcase('as'), $self->_quote ($as) )
        : ''
    );

    return $select;
  }
  # Is the second check absolutely necessary?
  elsif ( $ref eq 'REF' and ref($$fields) eq 'ARRAY' ) {
    return $self->_fold_sqlbind( $fields );
  }
  else {
    croak($ref . qq{ unexpected in _recurse_fields()})
  }
}

my $for_syntax = {
  update => 'FOR UPDATE',
  shared => 'FOR SHARE',
};

# this used to be a part of _order_by but is broken out for clarity.
# What we have been doing forever is hijacking the $order arg of
# SQLA::select to pass in arbitrary pieces of data (first the group_by,
# then pretty much the entire resultset attr-hash, as more and more
# things in the SQLA space need to have mopre info about the $rs they
# create SQL for. The alternative would be to keep expanding the
# signature of _select with more and more positional parameters, which
# is just gross. All hail SQLA2!
sub _parse_rs_attrs {
  my ($self, $arg) = @_;

  my $sql = '';

  if (my $g = $self->_recurse_fields($arg->{group_by}) ) {
    $sql .= $self->_sqlcase(' group by ') . $g;
  }

  if (defined $arg->{having}) {
    my ($frag, @bind) = $self->_recurse_where($arg->{having});
    push(@{$self->{having_bind}}, @bind);
    $sql .= $self->_sqlcase(' having ') . $frag;
  }

  if (defined $arg->{order_by}) {
    $sql .= $self->_order_by ($arg->{order_by});
  }

  if (my $for = $arg->{for}) {
    $sql .= " $for_syntax->{$for}" if $for_syntax->{$for};
  }

  return $sql;
}

sub _order_by {
  my ($self, $arg) = @_;

  # check that we are not called in legacy mode (order_by as 4th argument)
  if (ref $arg eq 'HASH' and not grep { $_ =~ /^-(?:desc|asc)/i } keys %$arg ) {
    return $self->_parse_rs_attrs ($arg);
  }
  else {
    my ($sql, @bind) = $self->SUPER::_order_by ($arg);
    push @{$self->{order_bind}}, @bind;
    return $sql;
  }
}

sub _order_directions {
  my ($self, $order) = @_;

  # strip bind values - none of the current _order_directions users support them
  return $self->SUPER::_order_directions( [ map
    { ref $_ ? $_->[0] : $_ }
    $self->_order_by_chunks ($order)
  ]);
}

sub _table {
  my ($self, $from) = @_;
  if (ref $from eq 'ARRAY') {
    return $self->_recurse_from(@$from);
  } elsif (ref $from eq 'HASH') {
    return $self->_make_as($from);
  } else {
    return $from; # would love to quote here but _table ends up getting called
                  # twice during an ->select without a limit clause due to
                  # the way S::A::Limit->select works. should maybe consider
                  # bypassing this and doing S::A::select($self, ...) in
                  # our select method above. meantime, quoting shims have
                  # been added to select/insert/update/delete here
  }
}

sub _generate_join_clause {
    my ($self, $join_type) = @_;

    return sprintf ('%s JOIN ',
      $join_type ?  ' ' . uc($join_type) : ''
    );
}

sub _recurse_from {
  my ($self, $from, @join) = @_;
  my @sqlf;
  push(@sqlf, $self->_make_as($from));
  foreach my $j (@join) {
    my ($to, $on) = @$j;


    # check whether a join type exists
    my $to_jt = ref($to) eq 'ARRAY' ? $to->[0] : $to;
    my $join_type;
    if (ref($to_jt) eq 'HASH' and defined($to_jt->{-join_type})) {
      $join_type = $to_jt->{-join_type};
      $join_type =~ s/^\s+ | \s+$//xg;
    }

    $join_type = $self->{_default_jointype} if not defined $join_type;

    push @sqlf, $self->_generate_join_clause( $join_type );

    if (ref $to eq 'ARRAY') {
      push(@sqlf, '(', $self->_recurse_from(@$to), ')');
    } else {
      push(@sqlf, $self->_make_as($to));
    }
    push(@sqlf, ' ON ', $self->_join_condition($on));
  }
  return join('', @sqlf);
}

sub _fold_sqlbind {
  my ($self, $sqlbind) = @_;

  my @sqlbind = @$$sqlbind; # copy
  my $sql = shift @sqlbind;
  push @{$self->{from_bind}}, @sqlbind;

  return $sql;
}

sub _make_as {
  my ($self, $from) = @_;
  return join(' ', map { (ref $_ eq 'SCALAR' ? $$_
                        : ref $_ eq 'REF'    ? $self->_fold_sqlbind($_)
                        : $self->_quote($_))
                       } reverse each %{$self->_skip_options($from)});
}

sub _skip_options {
  my ($self, $hash) = @_;
  my $clean_hash = {};
  $clean_hash->{$_} = $hash->{$_}
    for grep {!/^-/} keys %$hash;
  return $clean_hash;
}

sub _join_condition {
  my ($self, $cond) = @_;
  if (ref $cond eq 'HASH') {
    my %j;
    for (keys %$cond) {
      my $v = $cond->{$_};
      if (ref $v) {
        croak (ref($v) . qq{ reference arguments are not supported in JOINS - try using \"..." instead'})
            if ref($v) ne 'SCALAR';
        $j{$_} = $v;
      }
      else {
        my $x = '= '.$self->_quote($v); $j{$_} = \$x;
      }
    };
    return scalar($self->_recurse_where(\%j));
  } elsif (ref $cond eq 'ARRAY') {
    return join(' OR ', map { $self->_join_condition($_) } @$cond);
  } else {
    croak "Can't handle this yet!";
  }
}

sub limit_dialect {
    my $self = shift;
    if (@_) {
      $self->{limit_dialect} = shift;
      undef $self->{_cached_syntax};
    }
    return $self->{limit_dialect};
}

# Set to an array-ref to specify separate left and right quotes for table names.
# A single scalar is equivalen to [ $char, $char ]
sub quote_char {
    my $self = shift;
    $self->{quote_char} = shift if @_;
    return $self->{quote_char};
}

# Character separating quoted table names.
sub name_sep {
    my $self = shift;
    $self->{name_sep} = shift if @_;
    return $self->{name_sep};
}

1;
