package Package::Stash;
BEGIN {
  $Package::Stash::VERSION = '0.05';
}
use strict;
use warnings;
# ABSTRACT: routines for manipulating stashes

use Carp qw(confess);
use Scalar::Util qw(reftype);


sub new {
    my $class = shift;
    my ($namespace) = @_;
    return bless { 'package' => $namespace }, $class;
}


sub name {
    return $_[0]->{package};
}


sub namespace {
    # NOTE:
    # because of issues with the Perl API
    # to the typeglob in some versions, we
    # need to just always grab a new
    # reference to the hash here. Ideally
    # we could just store a ref and it would
    # Just Work, but oh well :\
    no strict 'refs';
    return \%{$_[0]->name . '::'};
}

{
    my %SIGIL_MAP = (
        '$' => 'SCALAR',
        '@' => 'ARRAY',
        '%' => 'HASH',
        '&' => 'CODE',
        ''  => 'IO',
    );

    sub _deconstruct_variable_name {
        my ($self, $variable) = @_;

        (defined $variable && length $variable)
            || confess "You must pass a variable name";

        my $sigil = substr($variable, 0, 1, '');

        if (exists $SIGIL_MAP{$sigil}) {
            return ($variable, $sigil, $SIGIL_MAP{$sigil});
        }
        else {
            return ("${sigil}${variable}", '', $SIGIL_MAP{''});
        }
    }
}


sub _valid_for_type {
    my $self = shift;
    my ($value, $type) = @_;
    if ($type eq 'HASH' || $type eq 'ARRAY'
     || $type eq 'IO'   || $type eq 'CODE') {
        return reftype($value) eq $type;
    }
    else {
        my $ref = reftype($value);
        return !defined($ref) || $ref eq 'SCALAR' || $ref eq 'REF' || $ref eq 'LVALUE';
    }
}

sub add_package_symbol {
    my ($self, $variable, $initial_value, %opts) = @_;

    my ($name, $sigil, $type) = ref $variable eq 'HASH'
        ? @{$variable}{qw[name sigil type]}
        : $self->_deconstruct_variable_name($variable);

    my $pkg = $self->name;

    if (@_ > 2) {
        $self->_valid_for_type($initial_value, $type)
            || confess "$initial_value is not of type $type";

        # cheap fail-fast check for PERLDBf_SUBLINE and '&'
        if ($^P and $^P & 0x10 && $sigil eq '&') {
            my $filename = $opts{filename};
            my $first_line_num = $opts{first_line_num};

            (undef, $filename, $first_line_num) = caller
                if not defined $filename;

            my $last_line_num = $opts{last_line_num} || ($first_line_num ||= 0);

            # http://perldoc.perl.org/perldebguts.html#Debugger-Internals
            $DB::sub{$pkg . '::' . $name} = "$filename:$first_line_num-$last_line_num";
        }
    }

    no strict 'refs';
    no warnings 'redefine', 'misc', 'prototype';
    *{$pkg . '::' . $name} = ref $initial_value ? $initial_value : \$initial_value;
}


sub remove_package_glob {
    my ($self, $name) = @_;
    no strict 'refs';
    delete ${$self->name . '::'}{$name};
}

# ... these functions deal with stuff on the namespace level


sub has_package_symbol {
    my ($self, $variable) = @_;

    my ($name, $sigil, $type) = ref $variable eq 'HASH'
        ? @{$variable}{qw[name sigil type]}
        : $self->_deconstruct_variable_name($variable);

    my $namespace = $self->namespace;

    return unless exists $namespace->{$name};

    my $entry_ref = \$namespace->{$name};
    if (reftype($entry_ref) eq 'GLOB') {
        if ( $type eq 'SCALAR' ) {
            return defined ${ *{$entry_ref}{SCALAR} };
        }
        else {
            return defined *{$entry_ref}{$type};
        }
    }
    else {
        # a symbol table entry can be -1 (stub), string (stub with prototype),
        # or reference (constant)
        return $type eq 'CODE';
    }
}


sub get_package_symbol {
    my ($self, $variable, %opts) = @_;

    my ($name, $sigil, $type) = ref $variable eq 'HASH'
        ? @{$variable}{qw[name sigil type]}
        : $self->_deconstruct_variable_name($variable);

    my $namespace = $self->namespace;

    if (!exists $namespace->{$name}) {
        # assigning to the result of this function like
        #   @{$stash->get_package_symbol('@ISA')} = @new_ISA
        # makes the result not visible until the variable is explicitly
        # accessed... in the case of @ISA, this might never happen
        # for instance, assigning like that and then calling $obj->isa
        # will fail. see t/005-isa.t
        if ($opts{vivify} && $type eq 'ARRAY' && $name ne 'ISA') {
            $self->add_package_symbol($variable, []);
        }
        elsif ($opts{vivify} && $type eq 'HASH') {
            $self->add_package_symbol($variable, {});
        }
        else {
            # FIXME
            $self->add_package_symbol($variable)
        }
    }

    my $entry_ref = \$namespace->{$name};

    if (ref($entry_ref) eq 'GLOB') {
        return *{$entry_ref}{$type};
    }
    else {
        if ($type eq 'CODE') {
            no strict 'refs';
            return \&{ $self->name . '::' . $name };
        }
        else {
            return undef;
        }
    }
}


sub get_or_add_package_symbol {
    my $self = shift;
    $self->get_package_symbol(@_, vivify => 1);
}


sub remove_package_symbol {
    my ($self, $variable) = @_;

    my ($name, $sigil, $type) = ref $variable eq 'HASH'
        ? @{$variable}{qw[name sigil type]}
        : $self->_deconstruct_variable_name($variable);

    # FIXME:
    # no doubt this is grossly inefficient and
    # could be done much easier and faster in XS

    my ($scalar_desc, $array_desc, $hash_desc, $code_desc, $io_desc) = (
        { sigil => '$', type => 'SCALAR', name => $name },
        { sigil => '@', type => 'ARRAY',  name => $name },
        { sigil => '%', type => 'HASH',   name => $name },
        { sigil => '&', type => 'CODE',   name => $name },
        { sigil => '',  type => 'IO',     name => $name },
    );

    my ($scalar, $array, $hash, $code, $io);
    if ($type eq 'SCALAR') {
        $array  = $self->get_package_symbol($array_desc)  if $self->has_package_symbol($array_desc);
        $hash   = $self->get_package_symbol($hash_desc)   if $self->has_package_symbol($hash_desc);
        $code   = $self->get_package_symbol($code_desc)   if $self->has_package_symbol($code_desc);
        $io     = $self->get_package_symbol($io_desc)     if $self->has_package_symbol($io_desc);
    }
    elsif ($type eq 'ARRAY') {
        $scalar = $self->get_package_symbol($scalar_desc);
        $hash   = $self->get_package_symbol($hash_desc)   if $self->has_package_symbol($hash_desc);
        $code   = $self->get_package_symbol($code_desc)   if $self->has_package_symbol($code_desc);
        $io     = $self->get_package_symbol($io_desc)     if $self->has_package_symbol($io_desc);
    }
    elsif ($type eq 'HASH') {
        $scalar = $self->get_package_symbol($scalar_desc);
        $array  = $self->get_package_symbol($array_desc)  if $self->has_package_symbol($array_desc);
        $code   = $self->get_package_symbol($code_desc)   if $self->has_package_symbol($code_desc);
        $io     = $self->get_package_symbol($io_desc)     if $self->has_package_symbol($io_desc);
    }
    elsif ($type eq 'CODE') {
        $scalar = $self->get_package_symbol($scalar_desc);
        $array  = $self->get_package_symbol($array_desc)  if $self->has_package_symbol($array_desc);
        $hash   = $self->get_package_symbol($hash_desc)   if $self->has_package_symbol($hash_desc);
        $io     = $self->get_package_symbol($io_desc)     if $self->has_package_symbol($io_desc);
    }
    elsif ($type eq 'IO') {
        $scalar = $self->get_package_symbol($scalar_desc);
        $array  = $self->get_package_symbol($array_desc)  if $self->has_package_symbol($array_desc);
        $hash   = $self->get_package_symbol($hash_desc)   if $self->has_package_symbol($hash_desc);
        $code   = $self->get_package_symbol($code_desc)   if $self->has_package_symbol($code_desc);
    }
    else {
        confess "This should never ever ever happen";
    }

    $self->remove_package_glob($name);

    $self->add_package_symbol($scalar_desc => $scalar);
    $self->add_package_symbol($array_desc  => $array)  if defined $array;
    $self->add_package_symbol($hash_desc   => $hash)   if defined $hash;
    $self->add_package_symbol($code_desc   => $code)   if defined $code;
    $self->add_package_symbol($io_desc     => $io)     if defined $io;
}


sub list_all_package_symbols {
    my ($self, $type_filter) = @_;

    my $namespace = $self->namespace;
    return keys %{$namespace} unless defined $type_filter;

    # NOTE:
    # or we can filter based on
    # type (SCALAR|ARRAY|HASH|CODE)
    if ($type_filter eq 'CODE') {
        return grep {
            (ref($namespace->{$_})
                ? (ref($namespace->{$_}) eq 'SCALAR')
                : (ref(\$namespace->{$_}) eq 'GLOB'
                   && defined(*{$namespace->{$_}}{CODE})));
        } keys %{$namespace};
    } else {
        return grep { *{$namespace->{$_}}{$type_filter} } keys %{$namespace};
    }
}


1;

__END__
=pod

=head1 NAME

Package::Stash - routines for manipulating stashes

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  my $stash = Package::Stash->new('Foo');
  $stash->add_package_symbol('%foo', {bar => 1});
  # $Foo::foo{bar} == 1
  $stash->has_package_symbol('$foo') # false
  my $namespace = $stash->namespace;
  *{ $namespace->{foo} }{HASH} # {bar => 1}

=head1 DESCRIPTION

Manipulating stashes (Perl's symbol tables) is occasionally necessary, but
incredibly messy, and easy to get wrong. This module hides all of that behind a
simple API.

NOTE: Most methods in this class require a variable specification that includes
a sigil. If this sigil is absent, it is assumed to represent the IO slot.

=head1 METHODS

=head2 new $package_name

Creates a new C<Package::Stash> object, for the package given as the only
argument.

=head2 name

Returns the name of the package that this object represents.

=head2 namespace

Returns the raw stash itself.

=head2 add_package_symbol $variable $value %opts

Adds a new package symbol, for the symbol given as C<$variable>, and optionally
gives it an initial value of C<$value>. C<$variable> should be the name of
variable including the sigil, so

  Package::Stash->new('Foo')->add_package_symbol('%foo')

will create C<%Foo::foo>.

Valid options (all optional) are C<filename>, C<first_line_num>, and
C<last_line_num>.

C<$opts{filename}>, C<$opts{first_line_num}>, and C<$opts{last_line_num}> can
be used to indicate where the symbol should be regarded as having been defined.
Currently these values are only used if the symbol is a subroutine ('C<&>'
sigil) and only if C<$^P & 0x10> is true, in which case the special C<%DB::sub>
hash is updated to record the values of C<filename>, C<first_line_num>, and
C<last_line_num> for the subroutine. If these are not passed, their values are
inferred (as much as possible) from C<caller> information.

This is especially useful for debuggers and profilers, which use C<%DB::sub> to
determine where the source code for a subroutine can be found.  See
L<http://perldoc.perl.org/perldebguts.html#Debugger-Internals> for more
information about C<%DB::sub>.

=head2 remove_package_glob $name

Removes all package variables with the given name, regardless of sigil.

=head2 has_package_symbol $variable

Returns whether or not the given package variable (including sigil) exists.

=head2 get_package_symbol $variable

Returns the value of the given package variable (including sigil).

=head2 get_or_add_package_symbol $variable

Like C<get_package_symbol>, except that it will return an empty hashref or
arrayref if the variable doesn't exist.

=head2 remove_package_symbol $variable

Removes the package variable described by C<$variable> (which includes the
sigil); other variables with the same name but different sigils will be
untouched.

=head2 list_all_package_symbols $type_filter

Returns a list of package variable names in the package, without sigils. If a
C<type_filter> is passed, it is used to select package variables of a given
type, where valid types are the slots of a typeglob ('SCALAR', 'CODE', 'HASH',
etc).

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-package-stash at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Package-Stash>.

=head1 SEE ALSO

=over 4

=item * L<Class::MOP::Package>

This module is a factoring out of code that used to live here

=back

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Package::Stash

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Package-Stash>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Package-Stash>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Package-Stash>

=item * Search CPAN

L<http://search.cpan.org/dist/Package-Stash>

=back

=head1 AUTHOR

  Jesse Luehrs <doy at tozt dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

