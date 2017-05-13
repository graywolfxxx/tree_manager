package TreeMng;

use Mojo::Base 'Mojolicious';

use TreeMng::Utils qw(get_mysql_dbh);
use TreeMng::View;

sub startup {
    my ($self) = @_;

    $self->secrets(['Kahphohfa4xuujah']);

    my $view = TreeMng::View->new();

    $self->helper(
        dbh => sub {get_mysql_dbh({
            db_name  => 'forest',
            db_host  => 'localhost',
            db_port  => 3306,
            db_login => 'root',
            db_pass  => '',
        })}
    );
    $self->helper(view => sub {$view});

    my $r = $self->routes;
    $r->any(['GET', 'POST'] => '/')->to('main#index_page', solution_id => 1);
    $r->any(['GET', 'POST'] => '/solution/:solution_id/')->to('main#index_page');
    $r->get('/task/')->to('main#task', template => 'task');

    my $api_v1 = $r->route('/api/v1', format => 'json');
    $api_v1->get('/get_tree/')->to('main#api_v1_get_tree');
    $api_v1->post('/add_node/')->to('main#api_v1_add_node');
    $api_v1->post('/del_node/')->to('main#api_v1_del_node');

}

1;
