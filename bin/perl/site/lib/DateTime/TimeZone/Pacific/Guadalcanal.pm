# This file is auto-generated by the Perl DateTime Suite time zone
# code generator (0.07) This code generator comes with the
# DateTime::TimeZone module distribution in the tools/ directory

#
# Generated from /tmp/fWavGZVMnY/australasia.  Olson data version 2010j
#
# Do not edit this file directly.
#
package DateTime::TimeZone::Pacific::Guadalcanal;

use strict;

use Class::Singleton;
use DateTime::TimeZone;
use DateTime::TimeZone::OlsonDB;

@DateTime::TimeZone::Pacific::Guadalcanal::ISA = ( 'Class::Singleton', 'DateTime::TimeZone' );

my $spans =
[
    [
DateTime::TimeZone::NEG_INFINITY,
60328934412,
DateTime::TimeZone::NEG_INFINITY,
60328972800,
38388,
0,
'LMT'
    ],
    [
60328934412,
DateTime::TimeZone::INFINITY,
60328974012,
DateTime::TimeZone::INFINITY,
39600,
0,
'SBT'
    ],
];

sub olson_version { '2010j' }

sub has_dst_changes { 0 }

sub _max_year { 2020 }

sub _new_instance
{
    return shift->_init( @_, spans => $spans );
}



1;

