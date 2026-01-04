use warnings;
use strict;
use lib 't';
use share;

my $client = JSON::RPC2::Client->new();

is $client->strict, 1;

my ($failed, $result, $error, $call) = $client->response('{}');
is $failed, 'expect {jsonrpc}="2.0"';

is $client->strict(0), 0;
is $client->strict, 0;

($failed, $result, $error, $call) = $client->response('{}');
isnt $failed, 'expect {jsonrpc}="2.0"';

done_testing();
