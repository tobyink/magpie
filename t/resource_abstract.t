use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Plack::Test;
use Plack::Builder;
use Plack::Middleware::Magpie;
use HTTP::Request::Common;

my $handler = builder {
    enable "Magpie";
};

test_psgi
    app    => $handler,
    client => sub {
    my $cb = shift;
    {
        my $resp = $cb->( GET "/" );
        is $resp->code, 200, 'GET / is 200';
    }
    {
        my $resp = $cb->( POST "/", );
        is $resp->code, 200, 'POST / is 200';
    }
    {
        my $resp = $cb->( PUT "/", );
        is $resp->code, 501, 'PUT / is 501 Not Implemented';
    }
    {
        my $resp = $cb->( HTTP::Request->new( 'PROPFIND', '/' ) );
        is $resp->code, 405, 'PROPFIND / is 405 Not Allowed';
    }
    };

done_testing;
