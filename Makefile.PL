use inc::Module::Install;

name     'JSON-RPC2';
all_from 'lib/JSON/RPC2.pm';
author   'Alex Efros <powerman-asdf@ya.ru>';
license  'perl';

requires 'JSON::XS';

build_requires 'Test::More';

auto_install;

WriteAll;

