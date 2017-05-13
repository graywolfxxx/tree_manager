use Mojo::Base -strict;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('TreeMng');
$t->get_ok('/')->status_is(200)->content_like(qr/Add node to/);

done_testing();
