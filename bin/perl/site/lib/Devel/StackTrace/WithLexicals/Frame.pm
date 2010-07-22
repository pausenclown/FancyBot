package Devel::StackTrace::WithLexicals::Frame;
use strict;
use warnings;
use Devel::StackTrace;
use base 'Devel::StackTraceFrame';

sub new {
    my $class = shift;
    my %args  = @_;

    my $self = $class->SUPER::new(
        $args{caller},
        $args{args},
        $args{respect_overload},
        $args{max_arg_length},
    );

    $self->{lexicals} = $args{lexicals};

    return $self;
}

sub lexicals { shift->{lexicals} }

sub lexical {
    my $self = shift;
    return $self->lexicals->{$_[0]};
}

1;

