package Magpie::Resource;
# ABSTRACT: Abstract base class for all resource types;

use Moose;
extends 'Magpie::Component';
use Magpie::Constants;

__PACKAGE__->register_events( qw( GET POST PUT DELETE HEAD OPTIONS ) );

# XXX: Move to a real Dispactcher
sub load_queue {
    my $self = shift;
    my $ctxt = shift;
    return $self->plack_request->method;
}

has produces => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'text/plain',
);

has consumes => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'text/plain',
);

sub GET {
    shift->set_error('NotImplemented');
    return DONE;
}

sub POST {
    shift->set_error('NotImplemented');
    return DONE;
}

sub PUT {
    shift->set_error('NotImplemented');
    return DONE;
}

sub DELETE {
    shift->set_error('NotImplemented');
    return DONE;
}

sub HEAD {
    shift->set_error('NotImplemented');
    return DONE;
}

sub OPTIONS {
    shift->set_error('NotImplemented');
    return DONE;
}

# SEEALSO: Magpie

1;