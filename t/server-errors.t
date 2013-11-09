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

my $server = JSON::RPC2::Server->new();
$server->register('func', sub{ return 42 });

my $Response;

# - execute:
#   * принимает ровно 2 параметра
throws_ok { $server->execute()                  } qr/2 params/;
throws_ok { $server->execute("")                } qr/2 params/;
throws_ok { $server->execute("",sub{},undef)    } qr/2 params/;
#   * второй параметр это ссылка на процедуру
throws_ok { $server->execute("",undef)          } qr/callback/;
throws_ok { $server->execute("",$server)        } qr/callback/;
throws_ok { $server->execute("",[])             } qr/callback/;
throws_ok { $server->execute("",{})             } qr/callback/;

# - принятый от клиента json:
#   * не json

execute(undef);
is $Response->{error}{code}, -32700,
    'not json';
is $Response->{error}{message}, 'Parse error.';

execute('bad json');
is $Response->{error}{code}, -32700;
is $Response->{error}{message}, 'Parse error.';

execute([]);
is $Response->{error}{code}, -32700;
is $Response->{error}{message}, 'Parse error.';

execute({});
is $Response->{error}{code}, -32700;
is $Response->{error}{message}, 'Parse error.';

#   * не хеш (Object)

execute('null');
is $Response->{error}{code}, -32700,
    'not Object';
is $Response->{error}{message}, 'Parse error.';

execute('true');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect Object.';

execute('false');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect Object.';

execute('3.14');
is $Response->{error}{code}, -32700;
is $Response->{error}{message}, 'Parse error.';

execute('"string"');
is $Response->{error}{code}, -32700;
is $Response->{error}{message}, 'Parse error.';

execute('[]');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect Object.';

#   * нет "jsonrpc"

execute('{}');
is $Response->{error}{code}, -32600,
    'no "jsonrpc"';
is $Response->{error}{message}, 'Invalid Request: expect {jsonrpc}="2.0".';

execute('{"key":0}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {jsonrpc}="2.0".';

#   * значение "jsonrpc" не "2.0"

execute('{"jsonrpc":null}');
is $Response->{error}{code}, -32600,
    '"jsonrpc": not "2.0"';
is $Response->{error}{message}, 'Invalid Request: expect {jsonrpc}="2.0".';

execute('{"jsonrpc":true}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {jsonrpc}="2.0".';

execute('{"jsonrpc":false}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {jsonrpc}="2.0".';

execute('{"jsonrpc":[]}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {jsonrpc}="2.0".';

execute('{"jsonrpc":{}}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {jsonrpc}="2.0".';

execute('{"jsonrpc":0}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {jsonrpc}="2.0".';

execute('{"jsonrpc":2}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {jsonrpc}="2.0".';

execute('{"jsonrpc":2.0}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {jsonrpc}="2.0".';

execute('{"jsonrpc":"2"}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {jsonrpc}="2.0".';

execute('{"jsonrpc":"2.00"}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {jsonrpc}="2.0".';

#   * значение "id" это не: null, число, строка

execute('{"jsonrpc":"2.0","id":true}');
is $Response->{error}{code}, -32600,
    '"id" not a number';
is $Response->{error}{message}, 'Invalid Request: expect {id} is scalar.';

execute('{"jsonrpc":"2.0","id":false}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {id} is scalar.';

execute('{"jsonrpc":"2.0","id":[]}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {id} is scalar.';

execute('{"jsonrpc":"2.0","id":{}}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {id} is scalar.';

#   * значение "method" это не число/строка

execute('{"jsonrpc":"2.0","id":null}');
is $Response->{error}{code}, -32600,
    '"method" not a string';
is $Response->{error}{message}, 'Invalid Request: expect {method} is String.';

execute('{"jsonrpc":"2.0","id":0,"method":true}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {method} is String.';

execute('{"jsonrpc":"2.0","id":0,"method":false}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {method} is String.';

execute('{"jsonrpc":"2.0","id":0,"method":[]}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {method} is String.';

execute('{"jsonrpc":"2.0","id":0,"method":{}}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {method} is String.';

#   * значение "method" это строка, не 'func'

execute('{"jsonrpc":"2.0","id":0,"method":0}');
is $Response->{error}{code}, -32601,
    '"method" not a func';
is $Response->{error}{message}, 'Method not found.';

execute('{"jsonrpc":"2.0","id":0,"method":""}');
is $Response->{error}{code}, -32601;
is $Response->{error}{message}, 'Method not found.';

execute('{"jsonrpc":"2.0","id":0,"method":"bad method"}');
is $Response->{error}{code}, -32601;
is $Response->{error}{message}, 'Method not found.';

#   * "method":"func", значение "params" не массив/хеш

execute('{"jsonrpc":"2.0","id":0,"method":"func","params":null}');
is $Response->{error}{code}, -32600,
    '"params" not an Array or Object';
is $Response->{error}{message}, 'Invalid Request: expect {params} is Array or Object.';

execute('{"jsonrpc":"2.0","id":0,"method":"func","params":true}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {params} is Array or Object.';

execute('{"jsonrpc":"2.0","id":0,"method":"func","params":false}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {params} is Array or Object.';

execute('{"jsonrpc":"2.0","id":0,"method":"func","params":""}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {params} is Array or Object.';

execute('{"jsonrpc":"2.0","id":0,"method":"func","params":42}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {params} is Array or Object.';


done_testing();


sub execute {
    my ($json) = @_;
    $Response = undef;
    $server->execute($json, sub { $Response = decode_json($_[0]) });
}


