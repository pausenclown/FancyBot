package DateTime::Helpers;
BEGIN {
  $DateTime::Helpers::VERSION = '0.61';
}

use strict;
use warnings;

use Scalar::Util ();

sub can {
    my $object = shift;
    my $method = shift;

    return unless Scalar::Util::blessed($object);
    return $object->can($method);
}

sub isa {
    my $object = shift;
    my $method = shift;

    return unless Scalar::Util::blessed($object);
    return $object->isa($method);
}

1;
