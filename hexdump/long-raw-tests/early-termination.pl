use strict; use warnings; use DBI; $|=1;
# Early termination and session reuse while a large single-row dump is active.
my $db = DBI->connect("dbi:Oracle:$ENV{ORACLE_TEST_DB}",$ENV{ORACLE_TEST_USER},$ENV{ORACLE_TEST_PASSWORD},{RaiseError=>1,PrintError=>0,RowCacheSize=>100});
my $src = q{table(hexdump_binary.hexdump_long_raw('HXATP_FIXTURE',null,'PAYLOAD','where id = :b',sys.anydata.convertvarchar2('2097153')))};
my $pga = q{select round(value/1048576,1) from v$mystat m join v$statname n using (statistic#) where n.name = 'session pga memory max'};
for (1..2) {
    my $rows = $db->selectall_arrayref("select address from $src where rownum <= 2");
    die "prefix mismatch" unless @$rows == 2 && $rows->[1][0] eq '00000000';
    print "rownum prefix pass $_ OK\n";
}
for (1..2) {
    my $q = $db->prepare("select address from $src"); $q->execute;
    my $n = 0; while ($q->fetchrow_arrayref) { last if ++$n == 5000 }
    $q->finish;
    print "abandoned after $n rows, pass $_ OK\n";
}
my ($n) = $db->selectrow_array("select count(*) from $src");
die "full count $n" unless $n == 131074;
print "full dump after abandoned cursors: $n rows OK\n";
print "session pga max MB: ", $db->selectrow_array($pga), "\n";
$db->disconnect;
