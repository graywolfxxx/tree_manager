package TreeMng::Utils;

=head1 DESCRIPTION

    Project utils.

=cut

use Time::HiRes;
use DBI;

use Exporter 'import';

=head1 EXPORTED METHODS

    All methods exported on request

=cut

our @EXPORT_OK = qw(
    timeout
    get_mysql_dbh
    close_mysql_dbh
    get_last_insert_id
);

=head1 METHODS

=head2 timeout

    Waits $sec seconds called subroutine and interrupt it.
    Returns the result of subroutine call.

=cut

sub timeout {
    my ($sec, $s) = @_;
    return unless defined($sec) && $sec =~ /^\d+(?:\.\d+)?$/ && defined($s) && ref($s) eq 'CODE';
    my $wantarray = wantarray;
    my ($res, @res, $to_error);
    eval {
        local $SIG{__DIE__} = 'IGNORE';
        local $SIG{ALRM} = sub { $to_error = 1; die "alarm_special_die"; };
        Time::HiRes::alarm($sec);
        if ($wantarray) {
            @res = $s->();
        } else {
            $res = $s->();
        }
        alarm(0);
    };
    alarm(0);
    if ($to_error) {
        my ($pkg, $file, $line) = caller();
        warn "Timeout $sec sec at $file line $line\n";
        return;
    } elsif ($@ && $@ !~ /alarm_special_die/) {
        warn $@;
        return;
    }
    return $wantarray ? @res : $res;
}

=head2 get_mysql_dbh

    Connects to MySQL server.

=cut

my $_dbh;
sub get_mysql_dbh {
    my ($p) = @_;
    unless ($_dbh) {
        return undef unless ref($p) eq 'HASH' && $p->{db_name} && $p->{db_host} && $p->{db_port} && $p->{db_login};
        my $db_connect_string = "dbi:mysql:database=$p->{db_name}:host=$p->{db_host}:port=$p->{db_port};mysql_client_found_rows=" . ($p->{client_found_rows} ? 1 : 0);
        for my $count (0 .. ($p->{retries} || 0)) {
            $_dbh = timeout(
                $p->{db_timeout} || 1,
                sub {
                    DBI->connect(
                        $db_connect_string,
                        $p->{db_login},
                        $p->{db_pass},
                        {   PrintError           => 1,
                            RaiseError           => $p->{RaiseError} || 0,
                            ShowErrorStatement   => 1,
                            mysql_auto_reconnect => 1,
                            mysql_enable_utf8    => 1,
                        }
                    ) or do {warn $DBI::err; return};
                }
            );
            if ($_dbh) {
                $_dbh->do("SET NAMES 'UTF8'");
                last;
            }
            warn "Connect retry " . ($count + 1);
        }
    }
    return $_dbh;
}

=head2 close_mysql_dbh

    Disonnects from MySQL server.

=cut

sub close_mysql_dbh {
    return unless $_dbh;
    $_dbh->disconnect();
    undef $_dbh;
}

=head2 get_last_insert_id

    Returnes the last inserted to MySQL id.

=cut

sub get_last_insert_id {
    my $dbh = shift || $_dbh or return undef;
    return $dbh->{'mysql_insertid'};
}

1;
