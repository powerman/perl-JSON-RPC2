package JSON::RPC2;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.1.1');    # update POD & Changes & README


1; # Magic true value required at end of module
__END__

=head1 NAME

JSON::RPC2 - Transport-independent implementation of json-rpc 2.0


=head1 VERSION

This document describes JSON::RPC2 version 0.1.1


=head1 SYNOPSIS

See L<JSON::RPC2::Server> and L<JSON::RPC2::Client> for usage examples.


=head1 DESCRIPTION

This module implement json-rpc 2.0 protocol in transport-independent way.
It was very surprising for me to find on CPAN a lot of transport-dependent
implementations of (by nature) transport-independent protocol!

Also it support non-blocking client remote procedure call and both
blocking and non-blocking server method execution. This can be very useful
in case server methods will need to do some RPC or other slow things like
network I/O, which can be done in parallel with executing other server
methods in any event-based environment.


=head1 INTERFACE

See L<JSON::RPC2::Server> and L<JSON::RPC2::Client> for details.


=head1 RATIONALE

There a lot of other RPC modules on CPAN, most of them has features doesn't
provided by this module, but they either too complex and bloated or lack
some features I need.

=over

=item L<RPC::Lite>

Not transport-independent.

=item L<RPC::Simple>

Not transport-independent.
Do eval() of perl code received from remote server.

=item L<RPC::Async>

Not transport-independent.
Not event-loop-independent.

=item L<JSON::RPC>

=item L<RPC::JSON>

=item L<RPC::Object>

=item L<Event::RPC>

=item L<RPC::Serialized>

=item L<XML::RPC>

=item L<RPC::XML>

Not transport-independent.
Blocking on remote function call.

=item L<JSON::RPC::Common>

In theory it's doing everything... but I failed to find out how to use it
(current version is 0.05) - probably it's incomplete yet. Even now it's
too complex and bloated for me, I prefer small and simple solutions.

=back


=head1 DIAGNOSTICS

None.


=head1 CONFIGURATION AND ENVIRONMENT

JSON::RPC2 requires no configuration files or environment variables.


=head1 DEPENDENCIES

 JSON::XS


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

=over

=item Batch/Multicall feature

Not supported neither in Server nor in Client.

It may be cool to have parallel request processing allowed in spec using
event-based style. But this feature doesn't looks really useful so it
implementation delayed until it become clear it's needed to avoid needless
complexity.

=item Named parameters

Not supported neither in Server nor in Client.

While it's ease to add support in Client, it's still not clear how to
define methods with named parameters on Server - because perl has no native
support for named parameters and there too many different and incompatible
ways to add that support.

=back

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-json-rpc2@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Alex Efros  C<< <powerman-asdf@ya.ru> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Alex Efros C<< <powerman-asdf@ya.ru> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
