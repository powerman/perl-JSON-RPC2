package JSON::RPC2::Client;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.2.1');    # update POD & Changes & README

# update DEPENDENCIES in POD & Makefile.PL & README
use JSON::XS;
use Scalar::Util qw( weaken refaddr );


sub new {
    my ($class) = @_;
    my $self = {
        next_id     => 0,
        free_id     => [],
        call        => {},
        id          => {},
    };
    return bless $self, $class;
}

sub notify {
    my ($self, $method, @params) = @_;
    croak 'method required' if !defined $method;
    return encode_json({
        jsonrpc     => '2.0',
        method      => $method,
        (!@params ? () : (
        params      => \@params,
        )),
    });
}

sub notify_named {
    my ($self, $method, @params) = @_;
    croak 'method required' if !defined $method;
    croak 'odd number of elements in %params' if @params % 2;
    my %params = @params;
    return encode_json({
        jsonrpc     => '2.0',
        method      => $method,
        (!@params ? () : (
        params      => \%params,
        )),
    });
}

sub call {
    my ($self, $method, @params) = @_;
    croak 'method required' if !defined $method;
    my ($id, $call) = $self->_get_id();
    my $request = encode_json({
        jsonrpc     => '2.0',
        method      => $method,
        (!@params ? () : (
        params      => \@params,
        )),
        id          => $id,
    });
    return wantarray ? ($request, $call) : $request;
}

sub call_named {
    my ($self, $method, @params) = @_;
    croak 'method required' if !defined $method;
    croak 'odd number of elements in %params' if @params % 2;
    my %params = @params;
    my ($id, $call) = $self->_get_id();
    my $request = encode_json({
        jsonrpc     => '2.0',
        method      => $method,
        (!@params ? () : (
        params      => \%params,
        )),
        id          => $id,
    });
    return wantarray ? ($request, $call) : $request;
}

sub _get_id {
    my $self = shift;
    my $id = @{$self->{free_id}} ? pop @{$self->{free_id}} : $self->{next_id}++;
    my $call = {};
    $self->{call}{ refaddr($call) } = $call;
    $self->{id}{ $id } = $call;
    weaken($self->{id}{ $id });
    return ($id, $call);
}

sub pending {
    my ($self) = @_;
    return values %{ $self->{call} };
}

sub cancel {
    my ($self, $call) = @_;
    croak 'no such request' if !delete $self->{call}{ refaddr($call) };
    return;
}

sub response {      ## no critic (ProhibitExcessComplexity RequireArgUnpacking)
    my ($self, $json) = @_;
    croak 'require 1 param' if @_ != 2;

    my $response = eval { decode_json($json) };
    ## no critic (ProhibitCascadingIfElse)
    if ($@) {
        return 'Parse error';
    }
    elsif (!$response || ref $response ne 'HASH') {
        return 'expect Object';
    }
    elsif (!defined $response->{jsonrpc} || $response->{jsonrpc} ne '2.0') {
        return 'expect {jsonrpc}="2.0"';
    }
    elsif (!exists $response->{id} || ref $response->{id} || !defined $response->{id}) {
        return 'expect {id} is scalar';
    }
    elsif (!exists $self->{id}{ $response->{id} }) {
        return 'unknown {id}';
    }
    elsif (!(exists $response->{result} xor exists $response->{error})) {
        return 'expect {result} or {error}';
    }
    elsif (exists $response->{error}) {
        my $e = $response->{error};
        if (ref $e ne 'HASH') {
            return 'expect {error} is Object';
        } elsif (!defined $e->{code} || ref $e->{code} || $e->{code} !~ /\A-?\d+\z/xms) {
            return 'expect {error}{code} is Integer';
        } elsif (!defined $e->{message} || ref $e->{message}) {
            return 'expect {error}{message} is String';
        ## no critic (ProhibitMagicNumbers)
        } elsif ((3 == keys %{$e} && !exists $e->{data}) || 3 < keys %{$e}) {
            return 'only optional key must be {error}{data}';
        }
    }
    ## use critic

    my $id = $response->{id};
    push @{ $self->{free_id} }, $id;
    my $call = delete $self->{id}{ $id };
    if ($call) {
        $call = delete $self->{call}{ refaddr($call) };
    }
    if (!$call) {
        return; # call was canceled
    }
    return (undef, $response->{result}, $response->{error}, $call);
}


1; # Magic true value required at end of module
__END__

=head1 NAME

JSON::RPC2::Client - Transport-independent json-rpc 2.0 client


=head1 VERSION

This document describes JSON::RPC2::Client version 0.2.1


=head1 SYNOPSIS

 use JSON::RPC2::Client;

 $client = JSON::RPC2::Client->new();

 $json_request = $client->notify('method', @params);
 $json_request = $client->notify_named('method', %params);
 ($json_request, $call) = $client->call('method', @params);
 ($json_request, $call) = $client->call_named('method', %params);

 $client->cancel($call);

 ($failed, $result, $error, $call) = $client->response($json_response);

 @call = $client->pending();

 #
 # EXAMPLE of simple blocking STDIN-STDOUT client
 #
 
 $client = JSON::RPC2::Client->new();
 $json_request = $client->call('method', @params);

 printf "%s\n", $json_request;
 $json_response = <STDIN>;
 chomp $json_response;

 ($failed, $result, $error) = $client->response($json_response);
 if ($failed) {
    die "bad response: $failed";
 } elsif ($error) {
    printf "method(@params) failed with code=%d: %s\n",
        $error->{code}, $error->{message};
 } else {
    print "method(@params) returned $result\n";
 }

=head1 DESCRIPTION

Transport-independent implementation of json-rpc 2.0 client.
Can be used both in sync (simple, for blocking I/O) and async
(for non-blocking I/O in event-based environment) mode.


=head1 INTERFACE 

=over

=item new()

Create and return new client object, which can be used to generate requests
(notify(), call()), parse responses (responses()) and cancel pending requests
(cancel(), pending()).

Each client object keep track of request IDs, so you must use dedicated
client object for each connection to server.


=item notify( $remote_method, @remote_params )
=item notify_named( $remote_method, %remote_params )

Notifications doesn't receive any replies, so they unreliable.

Return ($json_request) - scalar which should be sent to server in any way.


=item call( $remote_method, @remote_params )
=item call_named( $remote_method, %remote_params )

Return ($json_request, $call) - scalar which should be sent to server in
any way and identifier of this remote procedure call.

The $call is just empty HASHREF, which can be used to: 1) keep user data
related to this call in hash fields - that $call will be returned by
response() when response to this call will be received; 2) to cancel()
this call before response will be received. There usually no need for
user to keep $call somewhere unless he wanna be able to cancel() that call.

In scalar context return only $json_request - this enough for simple
blocking clients which doesn't need to detect which of several pending()
calls was just replied or cancel() pending calls.


=item response( $json_response )

Will parse $json_response and return list with 4 elements:

 ($failed, $result, $error, $call)

 $failed        parse error message if $json_response is incorrect
 $result        data returned by successful remote method call
 $error         error returned by failed remote method call
 $call          identifier of this call

If $failed defined then all others are undefined. Usually that mean either
bug in json-rpc client or server.

Only one of $result and $error will be defined. Format of $result
completely depends on data returned by remote method. $error is HASHREF
with fields {code}, {message}, {data} - code should be integer, message
should be string, and data is optional value in arbitrary format.

The $call should be used to identify which of currently pending() calls
just returns - it will be same HASHREF as was initially returned by call()
when starting this remote procedure call, and may contain any user data
which was placed in it after calling call().

There also special case when all 4 values will be undefined - that happens
if $json_response was related to call which was already cancel()ed by user.


=item cancel( $call )

Will cancel that $call. This doesn't affect server - it will continue
processing related request and will send response when ready, but that
response will be ignored by client's response().

Return nothing.


=item pending()

Return list with all currently pending $call's.

=back


=head1 DIAGNOSTICS

None.


=head1 CONFIGURATION AND ENVIRONMENT

JSON::RPC2::Client requires no configuration files or environment variables.


=head1 DEPENDENCIES

 JSON::XS


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-json-rpc2-client@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Alex Efros  C<< <powerman-asdf@ya.ru> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009,2013, Alex Efros C<< <powerman-asdf@ya.ru> >>. All rights reserved.

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
