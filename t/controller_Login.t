use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'FancyBot::WebShell' }
BEGIN { use_ok 'FancyBot::WebShell::Controller::Login' }

ok( request('/login')->is_success, 'Request should succeed' );
done_testing();
