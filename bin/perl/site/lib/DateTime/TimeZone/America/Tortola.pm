# This file is auto-generated by the Perl DateTime Suite time zone
# code generator (0.07) This code generator comes with the
# DateTime::TimeZone module distribution in the tools/ directory

#
# Generated from /tmp/fWavGZVMnY/northamerica.  Olson data version 2010j
#
# Do not edit this file directly.
#
package DateTime::TimeZone::America::Tortola;

use strict;

use Class::Singleton;
use DateTime::TimeZone;
use DateTime::TimeZone::OlsonDB;

@DateTime::TimeZone::America::Tortola::ISA = ( 'Class::Singleton', 'DateTime::TimeZone' );

my $spans =
[
    [
DateTime::TimeZone::NEG_INFINITY,
60289417108,
DateTime::TimeZone::NEG_INFINITY,
60289401600,
-15508,
0,
'LMT'
    ],
    [
60289417108,
DateTime::TimeZone::INFINITY,
60289402708,
DateTime::TimeZone::INFINITY,
-14400,
0,
'AST'
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

