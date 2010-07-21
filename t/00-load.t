#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'FancyBot' ) || print "Bail out!
";
}

diag( "Testing FancyBot $FancyBot::VERSION, Perl $], $^X" );
