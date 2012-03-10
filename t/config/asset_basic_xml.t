use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Plack::Middleware::Magpie;

my $context = {
    is              => 'everything',
    actually        => 'matters',
    is_frequently   => [qw(ignored misunderstood)],
};

my $handler = builder {
    enable "Magpie", context => $context, conf => 't/data/asset_basic.xml'
};

test_psgi
    app    => $handler,
    client => sub {
        my $cb = shift;
        {
            my $res = $cb->(GET "http://localhost/basic");
            like $res->content,
        qr/_moebaz__moebar__simplefoo__some value__simplebaz__curlyfoo_RIGHT_larryfoo__larrybar_/;
        }
        {
            my $res = $cb->(GET "http://localhost/badpath");
            like $res->content,
        qr/_moebaz__moebar__simplefoo__some value__simplebaz__curlyfoo_RIGHT_larryfoo__larrybar_/;
        }

    };


done_testing();
