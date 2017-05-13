package TreeMng::Controller::Main;

=head1 DESCRIPTION

    This class provides actions for the router

=cut

use utf8;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;
use Mojo::JSON qw(to_json);
use TreeMng::TreeBranch;

=head1 METHODS

=head2 index_page

    Action for the index page of the site.

=cut

sub index_page {
    my ($self) = @_;

    my $solution_id = $self->stash('solution_id');
    return $self->reply->not_found unless $solution_id && $solution_id =~ /^(?:1|2|3)$/;

    my ($tree, $err) = $solution_id != 2 ? $self->get_tree({add_first_node => 1}) : undef;

    my $template = 'solution' . $solution_id;

    # All data which will be passed to template
    my $tpl_data = {
        # Layout of the page: 'title' and other common attributes
        layout_data => {
            title      => 'Tree Manager',
            header     => 'Solution #' . $solution_id,
            activ_menu => 'solution' . $solution_id,
        },
        solution => {id => $solution_id},
    };
    $tpl_data->{errors} = $err if $err;

    if ($solution_id == 2 || $err || !$tree) {
        return $self->stash(d => $tpl_data)->render(template => $template);
    }

    my $action = $self->req->method eq 'POST' ? lc($self->param('action') || '') : '';

    if ($action eq 'add') {
        # Filter input data (remove data from the other actions)
        $tpl_data->{input_data} = {map {my $v = $self->param($_); defined($v) && length($v) ? ($_ => $v) : ()} qw(pid name)};
        my $new_node;
        ($new_node, $err) = $self->add_node({
            tree => $tree,
            pid  => scalar($self->param('pid')),
            name => scalar($self->param('name')),
        });
        if (!$err && $new_node) {
            return $self->redirect_to($self->url_for);
        } elsif ($err) {
            $tpl_data->{errors} = $err;
        } else {
            push @{$tpl_data->{errors}->{COMMON}}, 'Internal server error: Can\'t add node to DB.';
        }
    } elsif ($action eq 'del') {
        # Filter input data (remove data from the other actions)
        $tpl_data->{input_data} = {map {my $v = $self->param($_); defined($v) && length($v) ? ($_ => $v) : ()} qw(id)};
        my $del_cnt;
        ($del_cnt, $err) = $self->del_node({
            tree => $tree,
            id   => scalar($self->param('id')),
        });
        if (!$err && $del_cnt) {
            return $self->redirect_to($self->url_for);
        } elsif ($err) {
            $tpl_data->{errors} = $err;
        }
    }

    $tpl_data->{tree} = $tree;

    # Prepare the tree's nodes for JavaScript component jsTree (https://www.jstree.com/)
    $tpl_data->{tree_view_json} = [];
    if ($tree && $tree->{root_list}) {
        for (@{$tree->{root_list}}) {
            push @{$tpl_data->{tree_view_json}}, $self->view->prepare_data_for_tree_view($_);
        }
    }
    $tpl_data->{tree_view_json} = to_json($tpl_data->{tree_view_json});

    return $self->stash(d => $tpl_data)->render(template => $template);
}

sub task {
    my ($self) = @_;
    my $tpl_data = {
        layout_data => {
            title      => 'Tree Manager: Task',
            header     => 'Programming Assignment',
            activ_menu => 'task',
        },
    };
    return $self->stash(d => $tpl_data)->render();
}

=head1 API VERSION 1

=head2 api_v1_get_tree

    Returns the whole tree

=cut

sub api_v1_get_tree {
    my ($self) = @_;
    my ($tree, $err) = $self->get_tree();
    return $self->render(json => {status => 'ERROR', error => $err}) if $err;
    # Prepare the tree's nodes for JavaScript component jsTree (https://www.jstree.com/)
    my $tree_view_json = [];
    if ($tree && $tree->{root_list}) {
        for (@{$tree->{root_list}}) {
            push @$tree_view_json, $self->view->prepare_data_for_tree_view($_);
        }
    }
    return $self->render(json => {status => 'OK', tree => $tree_view_json});
}

=head2 api_v1_add_node

    Add new node

=cut

sub api_v1_add_node {
    my ($self) = @_;
    my ($tree, $err) = $self->get_tree();
    my $new_node;
    ($new_node, $err) = $err ? (undef, $err) : $self->add_node({
        tree => $tree,
        pid  => scalar($self->param('pid')),
        name => scalar($self->param('name')),
    });
    if (!$err && $new_node) {
        $new_node = $self->view->prepare_data_for_tree_view($new_node);
        return $self->render(json => {status => 'OK', node => $new_node});
    } elsif (!$err) {
        $err = {COMMON => ['Internal server error: Can\'t add node to DB.']};
    }
    return $self->render(json => {status => 'ERROR', error => $err});
}

=head2 api_v1_del_node

    Remove node from the tree

=cut

sub api_v1_del_node {
    my ($self) = @_;
    my ($tree, $err) = $self->get_tree();
    my $del_cnt;
    ($del_cnt, $err) = $err ? (0, $err) : $self->del_node({
        tree => $tree,
        id   => scalar($self->param('id')),
    });
    if (!$err && !defined($del_cnt)) {
        $err = {COMMON => ['Internal server error: Can\'t delete node from DB.']};
    }
    if ($err) {
        return $self->render(json => {status => 'ERROR', error => $err});
    }
    return $self->render(json => {status => 'OK', deleted_count => $del_cnt || 0});
}

=head1 COMMON METHODS

=head2 get_tree

    Returns the whole tree. Adds the root item in the empty tree if $add_first_node is passed.

=cut

sub get_tree {
    my ($self, $p) = @_;

    my $dbh = $self->dbh or return (undef, {COMMON => ['Internal server error: No DB connection.']});
    my $tree = TreeMng::TreeBranch->get_tree({dbh => $dbh});

    # Insert root item if the tree is empty (just for an example)
    if ($p && $p->{add_first_node} && $tree && !@{$tree->{root_list}}) {
        if (TreeMng::TreeBranch->add({dbh => $dbh}, {name => 'Root item'})) {
            $tree = TreeMng::TreeBranch->get_tree({dbh => $dbh});
        }
    }

    return ($tree, undef);
}

=head2 get_node

    Returns only one node without children.

=cut

sub get_node {
    my ($self, $p) = @_;
    if (!$p || !$p->{id} || $p->{id} !~ /^\d+$/) {
        return (undef, {id => "Node id [" . ($p && $p->{id} // 'UNDEF') . "] must be positive number."});
    }
    my $dbh = $self->dbh or return (undef, {COMMON => ['Internal server error: No DB connection.']});
    my $node = TreeMng::TreeBranch->get_one({dbh => $dbh}, $p->{id});
    return (undef, {id => "Node with id [$p->{id}] does not exist."}) if !$node;
    return ($node, undef);
}

=head2 add_node

    Add new node.

=cut

sub add_node {
    my ($self, $p) = @_;

    my $dbh = $self->dbh or return (undef, {COMMON => ['Internal server error: No DB connection.']});

    if (!$p || !$p->{pid} || $p->{pid} !~ /^\d+$/) {
        return (undef, {pid => 'Parent id [' . ($p && $p->{pid} // 'UNDEF') . '] must be positive number.'});
    }
    if ($p->{tree}) {
        if (!$p->{tree}->{obj_by_id}->{$p->{pid}}) {
            return (undef, {pid => "Parent with id [$p->{pid}] does not exist."});
        }
    } elsif (!TreeMng::TreeBranch->get_one({dbh => $dbh}, $p->{pid})) {
        return (undef, {pid => "Parent with id [$p->{pid}] does not exist."});
    }

    $p->{name} = 'New name ' . time() unless defined($p->{name}) && length($p->{name});

    my $new_node_id = TreeMng::TreeBranch->add({dbh => $dbh}, {pid => $p->{pid}, name => $p->{name}});
    if (!$new_node_id) {
        return (undef, {COMMON => ['Internal server error: Can\'t add node to DB.']});
    }

    return $self->get_node({id => $new_node_id});
}

=head2 del_node

    Remove node.

=cut

sub del_node {
    my ($self, $p) = @_;

    if (!$p || !$p->{id} || $p->{id} !~ /^\d+$/) {
        return (undef, {id => 'Node id [' . ($p && $p->{id} // 'UNDEF') . '] must be positive number.'});
    }

    my $dbh = $self->dbh or return (undef, {COMMON => ['Internal server error: No DB connection.']});

    my $tree = $p->{tree};
    if (!$tree) {
        my $err;
        ($tree, $err) = $self->get_tree();
        return (undef, $err) if $err;
        return (undef, {COMMON => ['Internal server error: Can\'t get tree.']}) if !$tree;
    }

    my $del_cnt = 0;
    if  ($tree->{obj_by_id}->{$p->{id}}) {
        for ($tree->{obj_by_id}->{$p->{id}}, @{$tree->{obj_by_id}->{$p->{id}}->{all_children} || []}) {
            $del_cnt++ if TreeMng::TreeBranch->del({dbh => $dbh}, $_->{id});
        }
    }

    return ($del_cnt, undef);
}

1;
