use strict;
use warnings;
use DBI;
use Digest::SHA qw(sha256_hex);
$| = 1;
my $db = DBI->connect("dbi:Oracle:$ENV{ORACLE_TEST_DB}",$ENV{ORACLE_TEST_USER},$ENV{ORACLE_TEST_PASSWORD},{RaiseError=>1,PrintError=>0,RowCacheSize=>100});
my $sql = q{select address,data,text from table(hexdump_binary.hexdump_long_raw(
 'HXATP_FIXTURE',null,'PAYLOAD','where id=:b',sys.anydata.convertnumber(?)))};
my $cycle = pack('C*',0..255);
for my $n (-1,0,1,16,17,1999,2000,2001,8191,8192,8193,32767,32768,2097153) {
    my $sorted = $n > 17;
    my $q = $db->prepare($sql . ($sorted ? ' order by address desc' : ''));
    $q->execute($n);
    my $expected = $n>0 ? substr($cycle x (1+int($n/256)),0,$n) : '';
    my $received = "\0" x length($expected);
    my ($rows,$headers,$bytes) = (0,0,0);
    my $lines = int((length($expected)+15)/16);
    while (my ($addr,$hex,$ascii) = $q->fetchrow_array) {
        if ($addr eq '=' x 8) { ++$headers; next }
        my $offset = 16 * ($sorted ? $lines-$rows-1 : $rows);
        die "address mismatch for $n" unless $addr eq sprintf('%08X',$offset);
        my $part = substr($expected,$offset,16);
        die "hex mismatch for $n at $addr" unless $hex eq join(' ',unpack('(A2)*',uc unpack('H*',$part)));
        die "text mismatch for $n at $addr" unless $ascii eq '|'.($part =~ s/[^ -~]/./gr).'|';
        my $data = pack('H*',$hex =~ s/ //gr);
        substr($received,$offset,length($data),$data);
        $bytes += length $data;
        ++$rows;
    }
    die "incomplete $n" unless $bytes==length($expected) && $rows==$lines && $headers==($n>=0 ? 1 : 0) && sha256_hex($received) eq sha256_hex($expected);
    print "id=$n lines=$rows bytes=$bytes mode=",($sorted?'sorted':'direct')," OK\n";
}
