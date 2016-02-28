[![Build Status](https://travis-ci.org/powerman/perl-JSON-RPC2.svg?branch=master)](https://travis-ci.org/powerman/perl-JSON-RPC2)
[![Coverage Status](https://coveralls.io/repos/powerman/perl-JSON-RPC2/badge.svg?branch=master)](https://coveralls.io/r/powerman/perl-JSON-RPC2?branch=master)

# NAME

JSON::RPC2 - Transport-independent implementation of JSON-RPC 2.0

# VERSION

This document describes JSON::RPC2 version v2.1.1

# SYNOPSIS

See [JSON::RPC2::Server](https://metacpan.org/pod/JSON::RPC2::Server) and [JSON::RPC2::Client](https://metacpan.org/pod/JSON::RPC2::Client) for usage examples.

# DESCRIPTION

This module implement JSON-RPC 2.0 protocol in transport-independent way.
It was very surprising for me to find on CPAN a lot of transport-dependent
implementations of (by nature) transport-independent protocol!

Also it support non-blocking client remote procedure call and both
blocking and non-blocking server method execution. This can be very useful
in case server methods will need to do some RPC or other slow things like
network I/O, which can be done in parallel with executing other server
methods in any event-based environment.

# INTERFACE

See [JSON::RPC2::Server](https://metacpan.org/pod/JSON::RPC2::Server) and [JSON::RPC2::Client](https://metacpan.org/pod/JSON::RPC2::Client) for details.

# RATIONALE

There a lot of other RPC modules on CPAN, most of them has features doesn't
provided by this module, but they either too complex and bloated or lack
some features I need.

- [RPC::Lite](https://metacpan.org/pod/RPC::Lite)

    Not transport-independent.

- [RPC::Simple](https://metacpan.org/pod/RPC::Simple)

    Not transport-independent.
    Do eval() of perl code received from remote server.

- [RPC::Async](https://metacpan.org/pod/RPC::Async)

    Not transport-independent.
    Not event-loop-independent.

- [JSON::RPC](https://metacpan.org/pod/JSON::RPC)
- [RPC::JSON](https://metacpan.org/pod/RPC::JSON)
- [RPC::Object](https://metacpan.org/pod/RPC::Object)
- [Event::RPC](https://metacpan.org/pod/Event::RPC)
- [RPC::Serialized](https://metacpan.org/pod/RPC::Serialized)
- [XML::RPC](https://metacpan.org/pod/XML::RPC)
- [RPC::XML](https://metacpan.org/pod/RPC::XML)

    Not transport-independent.
    Blocking on remote function call.

- [JSON::RPC::Common](https://metacpan.org/pod/JSON::RPC::Common)

    In theory it's doing everything... but I failed to find out how to use it
    (current version is 0.05) - probably it's incomplete yet. Even now it's
    too complex and bloated for me, I prefer small and simple solutions.

# SUPPORT

## Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at [https://github.com/powerman/perl-JSON-RPC2/issues](https://github.com/powerman/perl-JSON-RPC2/issues).
You will be notified automatically of any progress on your issue.

## Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

[https://github.com/powerman/perl-JSON-RPC2](https://github.com/powerman/perl-JSON-RPC2)

    git clone https://github.com/powerman/perl-JSON-RPC2.git

## Resources

- MetaCPAN Search

    [https://metacpan.org/search?q=JSON-RPC2](https://metacpan.org/search?q=JSON-RPC2)

- CPAN Ratings

    [http://cpanratings.perl.org/dist/JSON-RPC2](http://cpanratings.perl.org/dist/JSON-RPC2)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/JSON-RPC2](http://annocpan.org/dist/JSON-RPC2)

- CPAN Testers Matrix

    [http://matrix.cpantesters.org/?dist=JSON-RPC2](http://matrix.cpantesters.org/?dist=JSON-RPC2)

- CPANTS: A CPAN Testing Service (Kwalitee)

    [http://cpants.cpanauthors.org/dist/JSON-RPC2](http://cpants.cpanauthors.org/dist/JSON-RPC2)

# AUTHOR

Alex Efros &lt;powerman@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2009- by Alex Efros &lt;powerman@cpan.org>.

This is free software, licensed under:

    The MIT (X11) License
