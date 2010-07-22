package  # hide from PAUSE
    Catalyst::Model::DBIC::Schema::Types;

use MooseX::Types -declare => [qw/
    ConnectInfo ConnectInfos Replicants SchemaClass LoadedClass CreateOption
    Schema
/];

use Carp::Clan '^Catalyst::Model::DBIC::Schema';
use MooseX::Types::Moose qw/ArrayRef HashRef CodeRef Str ClassName/;
use Scalar::Util 'reftype';
use List::MoreUtils 'all';

use namespace::clean -except => 'meta';

subtype LoadedClass,
    as ClassName;

coerce LoadedClass,
    from Str,
    via { Class::MOP::load_class($_); $_ };

subtype SchemaClass,
    as ClassName,
    where { $_->isa('DBIx::Class::Schema') };

SchemaClass->coercion(LoadedClass->coercion);

class_type Schema, { class => 'DBIx::Class::Schema' };

subtype ConnectInfo,
    as HashRef,
    where { exists $_->{dsn} || exists $_->{dbh_maker} },
    message { 'Does not look like a valid connect_info' };

coerce ConnectInfo,
    from Str,
    via(\&_coerce_connect_info_from_str),
    from ArrayRef,
    via(\&_coerce_connect_info_from_arrayref),
    from CodeRef,
    via { +{ dbh_maker => $_ } },
;

# { connect_info => [ ... ] } coercion would be nice, but no chained coercions
# yet.
# Also no coercion from base type (yet,) but in Moose git already.
#    from HashRef,
#    via { $_->{connect_info} },

subtype ConnectInfos,
    as ArrayRef[ConnectInfo],
    message { "Not a valid array of connect_info's" };

coerce ConnectInfos,
    from Str,
    via { [ _coerce_connect_info_from_str() ] },
    from CodeRef,
    via { [ +{ dbh_maker => $_ } ]  },
    from HashRef,
    via { [ $_ ] },
    from ArrayRef,
    via { [ map {
        !ref $_ ? _coerce_connect_info_from_str()
            : reftype $_ eq 'HASH' ? $_
            : reftype $_ eq 'CODE' ? +{ dbh_maker => $_ }
            : reftype $_ eq 'ARRAY' ? _coerce_connect_info_from_arrayref()
            : croak 'invalid connect_info'
    } @$_ ] };

# Helper stuff

subtype CreateOption,
    as Str,
    where { /^(?:static|dynamic)\z/ },
    message { "Invalid create option, must be one of 'static' or 'dynamic'" };

sub _coerce_connect_info_from_arrayref {
    my %connect_info;

    # make a copy
    $_ = [ @$_ ];

    my $slurp_hashes = sub {
        for my $i (0..1) {
            my $extra = shift @$_;
            last unless $extra;
            croak "invalid connect_info"
                unless ref $extra && reftype $extra eq 'HASH';

            %connect_info = (%connect_info, %$extra);
        }
    };

    if (!ref $_->[0]) { # array style
        $connect_info{dsn}      = shift @$_;
        $connect_info{user}     = shift @$_ if !ref $_->[0];
        $connect_info{password} = shift @$_ if !ref $_->[0];

        $slurp_hashes->();

        croak "invalid connect_info" if @$_;
    } elsif (ref $_->[0] && reftype $_->[0] eq 'CODE') {
        $connect_info{dbh_maker} = shift @$_;

        $slurp_hashes->();

        croak "invalid connect_info" if @$_;
    } elsif (@$_ == 1 && ref $_->[0] && reftype $_->[0] eq 'HASH') {
        return $_->[0];
    } else {
        croak "invalid connect_info";
    }

    unless ($connect_info{dbh_maker}) {
        for my $key (qw/user password/) {
            $connect_info{$key} = ''
                if not defined $connect_info{$key};
        }
    }

    \%connect_info;
}

sub _coerce_connect_info_from_str {
    +{ dsn => $_, user => '', password => '' }
}

1;
