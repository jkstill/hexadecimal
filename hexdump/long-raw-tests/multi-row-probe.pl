use strict; use warnings; use DBI; $|=1;
# usage: probe.pl label cache bind "where clause" [count]
my ($label,$cache,$bind,$where,$count) = @ARGV;
my $r = eval {
    my $db = DBI->connect("dbi:Oracle:$ENV{ORACLE_TEST_DB}",$ENV{ORACLE_TEST_USER},$ENV{ORACLE_TEST_PASSWORD},{RaiseError=>1,PrintError=>0,RowCacheSize=>$cache});
    my $src = qq{table(hexdump_binary.hexdump_long_raw('HXATP_FIXTURE',null,'PAYLOAD',q'[$where]',sys.anydata.convertnumber(?)))};
    my ($rows,$hdr) = (0,0);
    if ($count) {
        ($rows,$hdr) = $db->selectrow_array("select count(*), count(case when address='========' then 1 end) from $src",undef,$bind);
    } else {
        my $q = $db->prepare("select address,data,text from $src"); $q->execute($bind);
        while (my @r = $q->fetchrow_array) { $rows++; $hdr++ if $r[0] eq '=' x 8 }
    }
    $db->selectrow_array('select 1 from dual'); $db->disconnect;
    "rows=$rows headers=$hdr OK";
};
($r //= "FAILED: $@") =~ s/\n.*//s;
printf "%-34s cache=%-4s %s\n", $label, $cache, substr($r,0,110);
