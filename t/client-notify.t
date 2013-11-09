use warnings;
use strict;
use t::share;

# ЗАПРОС:
# {
#   "jsonrpc": "2.0",
#   "id": 123,                          # кроме notify()
#   "method": "remote_func",
#   "params": [1,'a',123],              # remote_func(1,'a',123)
#   или
#   "params": {name=>'Alex',…},         # remote_func(name => 'Alex', …)
# }

my $json_request;

my $client = JSON::RPC2::Client->new();


# notify()
throws_ok { $client->notify() } qr/method/;

# notify('method')
$json_request = $client->notify('qwe');
jsonrpc2_ok($json_request, undef, 'qwe', undef);

# notify('method', 123)
$json_request = $client->notify('somefunc', 123);
jsonrpc2_ok($json_request, undef, 'somefunc', [123]);

# notify('method', 'qwe', 'asd', 'zxc')
$json_request = $client->notify('somefunc', 'qwe', 'asd', 'zxc');
jsonrpc2_ok($json_request, undef, 'somefunc', ['qwe', 'asd', 'zxc']);


done_testing();
