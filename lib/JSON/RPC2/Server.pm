package JSON::RPC2::Server;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.1.0');    # update POD & Changes & README

# update DEPENDENCIES in POD & Makefile.PL & README
use JSON::XS;

use constant ERR_PARSE  => -32700;
use constant ERR_REQ    => -32600;
use constant ERR_METHOD => -32601;
use constant ERR_PARAMS => -32602;


sub new {
    my ($class) = @_;
    my $self = {
        method  => {},
    };
    return bless $self, $class;
}

sub register {
    my ($self, $name, $cb) = @_;
    $self->{method}{ $name } = [ $cb, 1 ];
    return;
}

sub register_nb {
    my ($self, $name, $cb) = @_;
    $self->{method}{ $name } = [ $cb, 0 ];
    return;
}

sub execute {
    my ($self, $json, $cb) = @_;
    my $request = eval { decode_json($json) };
    if ($@) {
        return _error($cb, undef, ERR_PARSE, 'Parse error.');
    }
    if (!$request || ref $request ne 'HASH') {
        return _error($cb, undef, ERR_REQ, 'Invalid Request: expect Object.');
    }
    if (!defined $request->{jsonrpc} || $request->{jsonrpc} ne '2.0') {
        return _error($cb, undef, ERR_REQ, 'Invalid Request: expect {jsonrpc}="2.0".');
    }
    if (!exists $request->{params}) {
        $request->{params} = [];
    }
    # Notification
    if (!exists $request->{id}) {
        if (ref $request->{params} eq 'ARRAY') {
            if ($request->{method} && !ref $request->{method}) {
                my $method = $self->{method}{ $request->{method} };
                $method && $method->( @{ $request->{params} } );
            }
        }
        return;
    }
    # Request
    if (ref $request->{id}) {
        return _error($cb, undef, ERR_REQ, 'Invalid Request: expect {id} is scalar.');
    }
    my $id = $request->{id};
    if (ref $request->{params} eq 'HASH') {
        return _error($cb, $id, ERR_PARAMS, 'Invalid params: named params not supported by this method.');
    }
    elsif (ref $request->{params} ne 'ARRAY') {
        return _error($cb, $id, ERR_REQ, 'Invalid Request: expect {params} is Array or Object.');
    }
    if (!defined $request->{method} || ref $request->{method}) {
        return _error($cb, $id, ERR_REQ, 'Invalid Request: expect {method} is String.');
    }
    my $handler = $self->{method}{ $request->{method} };
    if (!$handler) {
        return _error($cb, $id, ERR_METHOD, 'Method not found.');
    }
    my ($method, $is_blocking) = @{$handler};
    if ($is_blocking) {
        return _done($cb, $id, [ $method->( @{ $request->{params} } ) ]);
    }
    my $cb_done = sub { _done($cb, $id, \@_) };
    $method->( $cb_done, @{ $request->{params} } );
    return;
}

sub _done {
    my ($cb, $id, $returns) = @_;
    my ($result, $code, $msg, $data) = @{$returns};
    if (defined $code) {
        return _error($cb, $id, $code, $msg, $data);
    }
    return _result($cb, $id, $result);
}

sub _error {
    my ($cb, $id, $code, $message, $data) = @_;
    return $cb->( encode_json({
        jsonrpc     => '2.0',
        id          => $id,
        error       => {
            code        => $code,
            message     => $message,
            (defined $data ? ( data => $data ) : ()),
        },
    }) );
}

sub _result {
    my ($cb, $id, $result) = @_;
    return $cb->( encode_json({
        jsonrpc     => '2.0',
        id          => $id,
        result      => $result,
    }) );
}


1; # Magic true value required at end of module
__END__

=head1 NAME

JSON::RPC2::Server - Transport-independent json-rpc 2.0 server


=head1 VERSION

This document describes JSON::RPC2::Server version 0.1.0


=head1 SYNOPSIS

    use JSON::RPC2::Server;

    my $rpcsrv = JSON::RPC2::Server->new();

    $rpcsrv->register('func1', \&func1);
    $rpcsrv->register_nb('func2', \&func2);

    # receive remote request in $json_request somehow, then:
    $rpcsrv->execute( $json_request, \&send_response );

    sub send_response {
        my ($json_response) = @_;
        # send $json_response somehow
    }

    sub func1 {
        my (@remote_params) = @_;
        if (success) {
            return ($result);
        } else {
            return (undef, $err_code, $err_message);
        }
    }

    sub func2 {
        my ($callback, @remote_params) = @_;
        # setup some event to call func2_finished($callback) later
    }
    sub func2_finished {
        my ($callback) = @_;
        if (success) {
            $callback->($result);
        } else {
            $callback->(undef, $err_code, $err_message);
        }
        return;
    }

    #
    # EXAMPLE of simple blocking STDIN-STDOUT server
    #

    my $rpcsrv = JSON::RPC2::Server->new();
    $rpcsrv->register('method1', \&method1);
    $rpcsrv->register('method2', \&method2);
    while (<STDIN>) {
        chomp;
        $rpcsrv->execute($_, sub { printf "%s\n", @_ });
    }
    sub method1 {
        return { my_params => \@_ };
    }
    sub method2 {
        return (undef, 0, "don't call me please");
    }

=head1 DESCRIPTION

Transport-independent implementation of json-rpc 2.0 server.
Server methods can be blocking (simpler) or non-blocking (useful if
method have to do some slow tasks like another RPC or I/O which can
be done in non-blocking way - this way several methods can be executing
in parallel on server).


=head1 INTERFACE 

=over

=item new()

Create and return new server object, which can be used to register and
execute user methods.

=item register( $rpc_method_name, \&method_handler )

Register $rpc_method_name as allowed method name for remote procedure call
and set \&method_handler as BLOCKING handler for that method.

If there already was some handler set (using register() or register_nb())
for that $rpc_method_name - it will be replaced by \&method_handler.

While processing request to $rpc_method_name user handler will be called
with parameters provided by remote side, and should return it result as
list with 4 elements:

 ($result, $code, $message, $data) = method_handler(@remote_params);

 $result        scalar or complex structure if method call success
 $code          error code (integer, > -32600) if method call failed
 $message       error message (string) if message call failed
 $data          optional scalar with additional error-related data

Either $result or $code should be defined, not both; $message required
only if $code defined.

Return nothing.

=item register_nb( $rpc_method_name, \&nb_method_handler )

Register $rpc_method_name as allowed method name for remote procedure call
and set \&method_handler as NON-BLOCKING handler for that method.

If there already was some handler set (using register() or register_nb())
for that $rpc_method_name - it will be replaced by \&method_handler.

While processing request to $rpc_method_name user handler will be called
with callback needed to return result in first parameter and parameters
provided by remote side as next parameters, and should call provided callback
with list with 4 elements when done:

 nb_method_handler($callback, @remote_params);

 # somewhere in that method handlers:
 $callback->($result, $code, $message, $data);
 return;

Meaning of ($result, $code, $message, $data) is same as documented in
register() above.

Return nothing.

=item execute( $json_request, $callback )

Parse $json_request and executed registered user handlers. Reply will be
sent into $callback, when ready:

 $callback->( $json_response );

Return nothing.

=back


=head1 DIAGNOSTICS

None.


=head1 CONFIGURATION AND ENVIRONMENT

JSON::RPC2::Server requires no configuration files or environment variables.


=head1 DEPENDENCIES

 JSON::XS


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-json-rpc2-server@rt.cpan.org>, or through the web interface at
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
