package Magpie::Resource::Kioku;
# ABSTRACT: INCOMPLETE - Resource implementation for KiokuDB datastores.

use Moose;
extends 'Magpie::Resource';
use Magpie::Constants;
use Try::Tiny;
use KiokuDB;
use Data::Dumper::Concise;

has data_source => (
    is          => 'ro',
    isa         => 'KiokuDB',
    lazy_build  => 1,
);


has wrapper_class => (
    isa => "Str",
    is  => "ro",
    required => 1,
    default => 'MagpieGenericWrapper',
);

has dsn => (
    isa => "Str",
    is  => "ro",
	predicate => "has_dsn",

);

has extra_args => (
    isa => "HashRef|ArrayRef",
    is  => "ro",
	predicate => "has_extra_args",
);

has typemap => (
    isa => "KiokuDB::TypeMap",
    is  => "ro",
	predicate => "has_typemap",
);

has _kioku_scope => (
    is => 'rw',
    isa => 'KiokuDB::LiveObjects::Scope',
);

has username => (
    is => 'ro',
    isa => 'Maybe[Str]',
    predicate => 'has_username',
);

has password => (
    is => 'ro',
    isa => 'Maybe[Str]',
    predicate => 'has_password',
);

sub _connect_args {
    my $self = shift;
	my @args = ( $self->dsn || die "dsn is required" );

	if ( $self->has_username ) {
		push @args, user => $self->username;
	}

	if ( $self->has_password ) {
		push @args, password => $self->password;
	}

	if ( $self->has_typemap ) {
		push @args, typemap => $self->typemap;
	}

	if ( $self->has_extra_args ) {
		my $extra = $self->extra_args;

		if ( ref($extra) eq 'ARRAY' ) {
			push @args, @$extra;
		} else {
			push @args, %$extra;
		}
	}

	\@args;
}

sub _build_data_source {
    my $self = shift;
    my $k = undef;
    try {
        $k = KiokuDB->connect(@{ $self->_connect_args });

    }
    catch {
        my $error = "Could not connect to Kioku data source: $_\n";
        $self->set_error({ status_code => 500, reason => $error });
    };

    return DECLINED if $self->has_error;

    $self->_kioku_scope( $k->new_scope );
    return $k;
}


sub GET {
    my $self = shift;
    my $req = $self->request;

    my $path = $req->path_info;

    if ( $path =~ /\/$/ ) {
        die "don't know what to do with index request yet";
    }

    my @steps = split '/', $path;

    my $id = $req->param('id') || pop @steps;

    my $data = undef;

    try {
        ($data) = $self->data_source->lookup( $id );
    }
    catch {
        my $error = "Could not GET data from Kioku data source: $_\n";
        $self->set_error({ status_code => 500, reason => $error });
    };

    return DECLINED if $self->has_error;

    unless ( $data ) {
        $self->set_error(404);
        return DECLINED;
    }
    warn "got data " . Dumper($data);

    $self->parent_handler->resource( $data );
    return OK;
}

sub POST {
    my $self = shift;
    my $req = $self->request;
    my $id = undef;

    my $to_store = undef;

    my $wrapper_class = $self->wrapper_class;

    # XXX should check for a content body first.
    my %args = ();
    for ($req->param) {
        $args{$_} = $req->param($_);
    }

    try {
        Class::MOP::load_class($wrapper_class);
        $to_store = $wrapper_class->new( %args );
    }
    catch {
        my $error = "Could not create instance of wrapper class '$wrapper_class': $_\n";
        $self->set_error({ status_code => 500, reason => $error });
    };

    return DECLINED if $self->has_error;

    try {
        $id = $self->data_source->store( $to_store );
    }
    catch {
        my $error = "Could not store POST data in Kioku data source: $_\n";
        $self->set_error({ status_code => 500, reason => $error });
    };

    return DECLINED if $self->has_error;

    warn "POST ID is $id\n";
    # XXX: all of this needs to go in an abstract object downstream serializer
    # can figure stuff out
    my $path = $req->path_info;
    $path =~ s|^/||;
    $self->response->status(201);
    $self->response->header( 'Location' => $req->base . $path . "/$id" );
    return OK;
}

package MagpieGenericWrapper;
sub new {
    my $proto = shift;
    my %args = @_;
    return bless \%args, $proto;
}

1;

__END__
=pod

# SEEALSO: Magpie, Magpie::Resource