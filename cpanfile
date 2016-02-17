requires 'perl', '5.010001';

requires 'JSON::XS';
requires 'Scalar::Util';

on configure => sub {
    requires 'Module::Build::Tiny', '0.034';
};

on test => sub {
    requires 'Test::Exception';
    requires 'Test::More';
};

on develop => sub {
    requires 'Test::Perl::Critic';
};