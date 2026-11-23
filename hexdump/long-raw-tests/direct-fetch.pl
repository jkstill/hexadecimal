use strict;
use warnings;
use DBI;
use Digest::SHA qw(sha256_hex);
$| = 1;
# usage: direct.pl rowcache size [size...]   one connection per size, unsorted fetch
my $cache = shift;
my $cycle = pack('C*',0..255);
my $fail = 0;
for my $n (@ARGV) {
    my $ok = eval {
        my $db = DBI->connect("dbi:Oracle:$ENV{ORACLE_TEST_DB}",$ENV{ORACLE_TEST_USER},$ENV{ORACLE_TEST_PASSWORD},{RaiseError=>1,PrintError=>0,RowCacheSize=>$cache});
        my $q = $db->prepare(q{select address,data,text from table(hexdump_binary.hexdump_long_raw(
          'HXATP_FIXTURE',null,'PAYLOAD','where id=:b',sys.anydata.convertnumber(?)))});
        $q->execute($n);
        my $expected = $n>0 ? substr($cycle x (1+int($n/256)),0,$n) : '';
        my ($rows,$headers,$received) = (0,0,'');
        while (my ($addr,$hex,$ascii) = $q->fetchrow_array) {
            if ($addr eq '=' x 8) { ++$headers; next }
            my $offset = 16*$rows;
            my $part = substr($expected,$offset,16);
            die "address mismatch at row $rows: $addr\n" unless $addr eq sprintf('%08X',$offset);
            die "hex mismatch at $addr\n" unless $hex eq join(' ',unpack('(A2)*',uc unpack('H*',$part)));
            die "text mismatch at $addr\n" unless $ascii eq '|'.($part =~ s/[^ -~]/./gr).'|';
            $received .= pack('H*',$hex =~ s/ //gr);
            ++$rows;
        }
        die "incomplete: rows=$rows headers=$headers bytes=".length($received)."\n"
            unless $headers==($n>=0?1:0) && sha256_hex($received) eq sha256_hex($expected);
        # session must still be usable
        my ($one) = $db->selectrow_array('select 1 from dual');
        $db->disconnect;
        print "id=$n cache=$cache lines=$rows bytes=",length($received)," unsorted OK\n";
        1;
    };
    unless ($ok) { $fail++; (my $e = $@) =~ s/\s+$//; print "id=$n cache=$cache FAILED: $e\n" }
}
exit($fail ? 1 : 0);
