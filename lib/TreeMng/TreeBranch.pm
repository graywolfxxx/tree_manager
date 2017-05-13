package TreeMng::TreeBranch;

=head1 DESCRIPTION

    This class manipulates by rows of the table Tree_Branch and provides some utils methods

=cut

use strict;
use warnings;
use TreeMng::Utils qw(get_last_insert_id);

=head1 METHODS

=head2 flds

    Returns list of all fields except 'id'.

=cut

sub flds {
    return qw(pid name date_updated);
}

=head2 all_flds

    Returns list of all fields.

=cut

sub all_flds {
    my ($self) = @_;
    return 'id', $self->flds();
}

=head2 get_root

    Returns root nodes

=cut

sub get_root {
    my ($self, $p) = @_;
    return $self->get_list($p, undef, 'pid IS NULL');
}

=head2 get_list

    Returns list of nodes.

=cut

sub get_list {
    my ($self, $p, $cols, $condition, $order, $limit) = @_;
    my $dbh = $self->_dbh($p) || return [];
    my $sql = 'SELECT ' . ($cols || '*') . ' FROM Tree_Branch';
    $sql .= " WHERE $condition" if $condition;
    $sql .= ' ORDER BY ' . ($order || 'pid, id');
    $sql .= " LIMIT $limit" if $limit;
    return $dbh->selectall_arrayref($sql, {Columns=>{}}) || [];
}

=head2 get_list

    Returns one node by $id

=cut

sub get_one {
    my ($self, $p, $id) = @_;
    my $dbh = $self->_dbh($p);
    return undef unless $dbh && $id && $id =~ /^\d+$/;
    return $dbh->selectrow_hashref("SELECT * FROM Tree_Branch WHERE id = $id");
}

=head2 get_tree

    Returns tree of nodes

=cut

sub get_tree {
    my ($self, $p) = @_;
    my $objs_from_db = $self->get_list($p);
    my $obj_by_id = {};
    my $cnt       = 0;
    while (@$objs_from_db != $cnt) {
        %$obj_by_id = map {$_->{id} => $_} @$objs_from_db;
        for (@$objs_from_db) {
            $_->{parent} = $obj_by_id->{$_->{pid}} if $_->{pid};
        }
        $cnt = @$objs_from_db;
        @$objs_from_db = grep {!$_->{pid} || $_->{parent}} @$objs_from_db;
    }
    my $root_list = [];
    my $parent;
    for my $o (@$objs_from_db) {
        if ($parent = $o->{parent}) {
            $parent->{children} = [] unless $parent->{children};
            push @{$parent->{children}}, $o;
            while ($parent) {
                $parent->{all_children} = [] unless $parent->{all_children};
                push @{$parent->{all_children}}, $o;
                last unless $parent->{pid};
                $parent = $parent->{parent} = $obj_by_id->{$parent->{pid}};
            }
        } else {
            push @$root_list, $o;
        }
    }
    return {obj_by_id => $obj_by_id, root_list => $root_list};
}

=head2 add

    Adds node to the tree

=cut

sub add {
    my ($self, $p, $data) = @_;
    my $dbh = $self->_dbh($p);
    return undef unless $dbh && ref($data) eq 'HASH';
    my (@fld, @data);
    for ($self->flds()) {
        next unless exists($data->{$_});
        push @fld, '`' . $_ . '`';
        push @data, $data->{$_};
    }
    return undef unless @fld;
    my $fld_str = join(',', @fld);
    my $placeholders = join(',', map {'?'} (0 .. $#data));
    my $res = $dbh->do("INSERT INTO Tree_Branch ($fld_str) VALUES ($placeholders)", undef, @data);
    return undef unless $res;
    return get_last_insert_id($dbh);
}

=head2 set

    Updates node

=cut

sub set {
    my ($self, $p, $id, $data) = @_;
    my $dbh = $self->_dbh($p);
    return undef unless $dbh && $id && $id =~ /^\d+$/ && ref($data) eq 'HASH';
    my (@fld, @data);
    for ($self->flds()) {
        next unless exists($data->{$_});
        push @fld, '`' . $_ . '` = ?';
        push @data, $data->{$_};
    }
    return undef unless @fld;
    my $fld_str = join(',', @fld);
    return $dbh->do("UPDATE Tree_Branch SET $fld_str WHERE id = ?", undef, @data, $id);
}

=head2 del

    Removes the node and all children

=cut

sub del {
    my ($self, $p, $id) = @_;
    my $dbh = $self->_dbh($p);
    return undef unless $dbh && $id && $id =~ /^\d+$/;
    return $dbh->do("DELETE FROM Tree_Branch WHERE id = ?", undef, $id);
}

# DB Helper
sub _dbh {
    my ($self, $p) = @_;
    warn "No db handler" unless $p && $p->{dbh};
    return $p->{dbh};
}

1;
