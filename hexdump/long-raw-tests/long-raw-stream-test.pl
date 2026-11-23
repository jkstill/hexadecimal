#!/usr/bin/env perl
use strict;
use warnings;
use DBI qw(:sql_types);
use Digest::SHA;

# Use an isolated table. CREATE must succeed before cleanup is enabled.
my $db = DBI->connect("dbi:Oracle:$ENV{ORACLE_TEST_DB}",
    $ENV{ORACLE_TEST_USER}, $ENV{ORACLE_TEST_PASSWORD},
    { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
$db->do('create table hexdump_lr_fixture (id number primary key, payload long raw)');
END { $db->do('drop table hexdump_lr_fixture purge') if our $created && $db }
our $created = 1;
my $insert = $db->prepare('insert into hexdump_lr_fixture values (?, ?)');
my @sizes = (0, 1, 16, 17, 1999, 2000, 2001, 8191, 8192, 8193, 32767, 32768, 2*1024*1024+1);
my $pattern = pack('C*', 0..255);
sub payload {
    my ($size) = @_;
    return substr($pattern x (1+int($size/256)), 0, $size);
}
for my $size (@sizes) {
    $insert->bind_param(1,$size);
    $insert->bind_param(2,$size ? payload($size) : undef, SQL_LONGVARBINARY);
    $insert->execute;
}
my $source = q{table(hexdump_binary.hexdump_long_raw('HEXDUMP_LR_FIXTURE',null,
    'PAYLOAD','where id <= :b order by id',sys.anydata.convertnumber(?)))};
my $query = $db->prepare("select address,data,text from $source");
$query->execute(-1);
die "unexpected row" if $query->fetchrow_arrayref;
$query->execute($sizes[-1]);
for my $size (@sizes) {
    my $header = $query->fetchrow_arrayref;
    die "missing header" unless $header && $header->[0] eq '=' x 8;
    my $digest = Digest::SHA->new(256);
    my $expected = payload($size);
    for (my $pos=0; $pos<$size; $pos+=16) {
        my ($address,$hex,$text) = $query->fetchrow_array;
        my $bytes = substr($expected,$pos,16);
        my $ascii = $bytes =~ s/[^ -~]/./gr;
        die "bad dump for size $size offset $pos"
            unless defined($hex) && $hex eq join(' ',unpack('(A2)*',uc unpack('H*',$bytes)))
                && $address eq sprintf('%08X',$pos) && $text eq "|$ascii|";
        $digest->add(pack('H*',$hex =~ s/ //gr));
    }
    die "digest mismatch" unless $digest->hexdigest eq Digest::SHA::sha256_hex($expected);
    print "verified $size bytes\n";
}
die "trailing rows" if $query->fetchrow_arrayref;
for (1..2) {
    my $rows = $db->selectall_arrayref(q{
        select address from table(hexdump_binary.hexdump_long_raw(
            'HEXDUMP_LR_FIXTURE',null,'PAYLOAD','where id = :b',
            sys.anydata.convertvarchar2('2097153'))) where rownum <= 2});
    die "prefix mismatch" unless @$rows == 2 && $rows->[1][0] eq '00000000';
}
print "verified early termination and reuse\n";
