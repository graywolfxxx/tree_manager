package TreeMng::View;

=head1 DESCRIPTION

    This class provides method to prepare data for AJAX or templates

=cut


=head2 new

    Constructor

=cut

sub new {
    my ($self) = @_;
    return bless({}, ref($self) || $self);
}

=head2 prepare_data_for_tree_view

    Prepares the tree's nodes for JavaScript component jsTree (https://www.jstree.com/)

=cut

sub prepare_data_for_tree_view {
    my ($self, $tree, $depth) = @_;
    return undef unless ref($tree) eq 'HASH';
    $depth = 0 unless $depth;
    my $new_tree = {id => $tree->{id}, pid => $tree->{pid}, text => $tree->{name}, depth => $depth};
    $new_tree->{text} = '' unless defined($new_tree->{text});
    my $parenthesis = length($new_tree->{text}) ? 1 : 0;
    $new_tree->{text} .= ($parenthesis ? ' (' : '') . "id: $tree->{id}";
    $new_tree->{text} .= ", pid: $tree->{pid}" if $tree->{pid};
    $new_tree->{text} .= ", depth: $depth";
    $new_tree->{text} .= ')' if $parenthesis;
    if ($tree->{children} && @{$tree->{children}}) {
        $new_tree->{state} = {opened => 1};
        $new_tree->{children} = [];
        for (@{$tree->{children}}) {
            push @{$new_tree->{children}}, $self->prepare_data_for_tree_view($_, $depth + 1);
        }
    }
    return $new_tree;
}

1;
