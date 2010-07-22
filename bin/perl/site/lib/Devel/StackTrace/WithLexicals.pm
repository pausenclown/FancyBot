package Devel::StackTrace::WithLexicals;
use strict;
use warnings;
use 5.008001;
use base 'Devel::StackTrace';

use Devel::StackTrace::WithLexicals::Frame;

use PadWalker 'peek_my';

our $VERSION = '0.06';

sub _record_caller_data {
    my $self = shift;

    $self->SUPER::_record_caller_data(@_);

    my $caller = -1;
    my $walker = 0;

    while (my (undef, undef, undef, $sub) = caller(++$caller)) {
        # PadWalker ignores eval block and eval string, we must do so too
        next if $sub eq '(eval)';

        $self->{raw}[$caller]{lexicals} = peek_my(++$walker);
        if ($self->{no_refs}) {
            for (values %{ $self->{raw}[$caller]{lexicals} }) {
                $_ = $$_ if ref($_) eq 'REF';
                $_ = $self->_ref_to_string($_);
            }
        }
    }

    # don't want to include the frame for this method!
    shift @{ $self->{raw} };
}

# this is a reimplementation of code already in Devel::StackTrace
# but it's too hairy to make it subclassable because of backcompat
# so I copied and pasted it and made it.. modern
sub _ignore_package_list {
    my $self = shift;

    my @i_pack_re;

    if ($self->{ignore_package}) {
        $self->{ignore_package} = [ $self->{ignore_package} ]
            unless ref($self->{ignore_package}) eq 'ARRAY';

        @i_pack_re = map { ref $_ ? $_ : qr/^\Q$_\E$/ }
                     @{ $self->{ignore_package} };
    }

    push @i_pack_re, qr/^Devel::StackTrace$/;

    my $p = __PACKAGE__;
    push @i_pack_re, qr/^\Q$p\E$/;

    return @i_pack_re;
}

sub _ignore_class_map {
    my $self = shift;

    if ($self->{ignore_class}) {
        $self->{ignore_class} = [ $self->{ignore_class} ]
            unless ref($self->{ignore_class}) eq 'ARRAY';

        return map { $_ => 1 } @{ $self->{ignore_class} };
    }

    return ();
}

sub _normalize_args {
    my $self = shift;
    my $args = shift;

    if ($self->{no_refs}) {
        for (grep { ref } @$args) {
            # I can't remember what this is about but I think
            # it must be to avoid a loop between between
            # Exception::Class and this module.
            if (UNIVERSAL::isa($_, 'Exception::Class::Base')) {
                $_ = do {
                    if ($_->can('show_trace')) {
                        my $t = $_->show_trace;
                        $_->show_trace(0);
                        my $s = "$_";
                        $_->show_trace($t);
                        $s;
                    }
                    else {
                        # hack but should work with older
                        # versions of E::C::B
                        $_->{message};
                    }
                };
            }
            else {
                $_ = $self->_ref_to_string($_);
            }
        }
    }

    return $args;
}

sub _frame_class { "Devel::StackTrace::WithLexicals::Frame" }

sub _make_frames {
    my $self = shift;

    my @i_pack_re = $self->_ignore_package_list;
    my %i_class   = $self->_ignore_class_map;

    for my $r (@{ $self->{raw} }) {
        next if grep { $r->{caller}[0] =~ /$_/ } @i_pack_re;
        next if grep { $r->{caller}[0]->isa($_) } keys %i_class;

        $self->_add_frame($r);
    }

    # if we don't delete this key then D:ST will call _make_frames again
    delete $self->{raw};
}

sub _add_frame {
    my $self       = shift;
    my $frame_data = shift;

    my $c = $frame_data->{caller};
    my $args = $frame_data->{args};

    # eval and is_require are only returned when applicable under 5.00503.
    push @$c, (undef, undef)
        if scalar @$c == 6;

    $frame_data->{args} = $self->_normalize_args($frame_data->{args});

    my $frame = $self->_frame_class->new(
        %$frame_data,
        respect_overload => $self->{respect_overload},
        max_arg_length   => $self->{max_arg_length},
    );

    push @{ $self->{frames} }, $frame;
}


1;

__END__

=head1 NAME

Devel::StackTrace::WithLexicals - Devel::StackTrace + PadWalker

=head1 SYNOPSIS

    use Devel::StackTrace::WithLexicals;

    my $trace = Devel::StackTrace::WithLexicals->new;
    ${ $trace->frame(1)->lexical('$self') }->oh_god_why();

=head1 DESCRIPTION

L<Devel::StackTrace> is pretty good at generating stack traces.

L<PadWalker> is pretty good at the inspection and modification of your callers'
lexical variables.

L<Devel::StackTrace::WithLexicals> is pretty good at generating stack traces
with all your callers' lexical variables.

=head1 METHODS

All the same as L<Devel::StackTrace>, except that frames (in class
L<Devel::StackTrace::WithLexicals::Frame>) also have a C<lexicals> method. This
returns the same hashref as returned by L<PadWalker>.

If the C<no_refs> option to L<Devel::StackTrace> is used, then each reference
is stringified. This can be useful to avoid leaking memory.

Simple, really.

=head1 AUTHOR

Shawn M Moore, C<sartak@gmail.com>

=head1 BUGS

I had to copy and paste some code from L<Devel::StackTrace> to achieve this
(it's hard to subclass). There may be bugs lingering here.

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 Shawn M Moore.

Some portions written by Dave Rolsky, they belong to him.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

