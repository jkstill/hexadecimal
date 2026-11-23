use strict;
use warnings;
use DBI qw(:sql_types);
my $db = DBI->connect("dbi:Oracle:$ENV{ORACLE_TEST_DB}",$ENV{ORACLE_TEST_USER},$ENV{ORACLE_TEST_PASSWORD},{RaiseError => 1,PrintError=>0});
$db->do('create table hxatp_fixture (id number primary key, payload long raw)');
my $insert = $db->prepare('insert into hxatp_fixture values (?,?)');
my $cycle = pack('C*',0..255);
for my $n (0,1,16,17,1999,2000,2001,32767,32768,2097153) {
  $insert->bind_param(1,$n);
  $insert->bind_param(2,$n ? substr($cycle x (1+int($n/256)),0,$n) : undef,SQL_LONGVARBINARY);
  $insert->execute();
}
$db->disconnect();
