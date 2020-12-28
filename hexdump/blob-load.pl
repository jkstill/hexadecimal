#!/usr/bin/env perl

use warnings;
use strict;
use FileHandle;
use DBI;
use Getopt::Long;
use IO::File;
use Data::Dumper;

my %optctl = ();

my($db, $username, $password, $connectionMode, $localSysdba);
my($adjustCols);
$adjustCols=0;
my $sysdba=0;

Getopt::Long::GetOptions(
	\%optctl,
	"database=s" => \$db,
	"username=s" => \$username,
	"password=s" => \$password,
	"sysdba!",
	"local-sysdba!",
	"sysoper!",
	"z","h","help");

#$localSysdba=$optctl{'local-sysdba'};

if (! $localSysdba) {

	$connectionMode = 0;
	if ( $optctl{sysoper} ) { $connectionMode = 4 }
	if ( $optctl{sysdba} ) { $connectionMode = 2 }

	usage(1) unless ($db and $username and $password);
}


#print qq{
#
#USERNAME: $username
#DATABASE: $db
#PASSWORD: $password
    #MODE: $connectionMode
 #RPT LVL: @rptLevels
#};
#exit;


$|=1; # flush output immediately

sub getOraVersion($$$);

my $dbh ;

if ($localSysdba) {
	$dbh = DBI->connect(
		'dbi:Oracle:',undef,undef,
		{
			RaiseError => 1,
			AutoCommit => 0,
			ora_session_mode => 2
		}
	);
} else {
	$dbh = DBI->connect(
		'dbi:Oracle:' . $db,
		$username, $password,
		{
			RaiseError => 1,
			AutoCommit => 0,
			ora_session_mode => $connectionMode
		}
	);
}

die "Connect to  $db failed \n" unless $dbh;
$dbh->{RowCacheSize} = 100;

# get the major and minor version of the instance
my ($majorOraVersion, $minorOraVersion);
getOraVersion (
		\$dbh,
		\$majorOraVersion,
		\$minorOraVersion,
);

print "Major/Minor version $majorOraVersion/$minorOraVersion\n";
my $dbVersion="${majorOraVersion}.${minorOraVersion}" * 1; # convert to number

# load a blob - hard coded to /bin/tempfile

my $file2load='/bin/tempfile';

-r $file2load || die "cannot read $file2load\n";

# small file, just get it all
undef $/; # slurp mode for file read

my $fh=IO::File->new;

$fh->open($file2load,'r') || die "cannot open $file2load\n";
$fh->binmode();

my $blob = <$fh>;
close $fh;

my $raw='';
foreach my $r ( 0..128 ) {
	$raw .= chr($r);
}

my $sql = 'delete from binary_test';
$dbh->do($sql);

$sql = q{insert into binary_test(name,my_blob) values(?, utl_raw.cast_to_raw(?))};
my $sth = $dbh->prepare($sql);
$sth->execute(q{BLOB}, $dbh->quote($blob));

$sql = q{insert into binary_test(name,my_raw) values(?, utl_raw.cast_to_raw(?))};
$sth = $dbh->prepare($sql);
$sth->execute(q{RAW}, $raw);

$sql = q{insert into binary_test(name,my_long_raw) values(?, utl_raw.cast_to_raw(?))};
$sth = $dbh->prepare($sql);
$sth->execute(q{LONG RAW}, $raw);

$dbh->commit;

$dbh->disconnect;

$fh = IO::File->new;
$fh->open('./baseline-raw.data','w') || die "cannot open baseline-raw.data\n";
$fh->binmode();

$fh->write($raw);
$fh->close;

sub usage {
	my $exitVal = shift;
	$exitVal = 0 unless defined $exitVal;
	use File::Basename;
	my $basename = basename($0);
	print qq/

usage: $basename

  -database      target instance
  -username      target instance account name
  -password      target instance account password
  -sysdba        logon as sysdba
  -sysoper       logon as sysoper
  -local-sysdba  logon to local instance as sysdba. ORACLE_SID must be set
                 the following options will be ignored:
                   -database
                   -username
                   -password

  example:

  $basename -database dv07 -username scott -password tiger -sysdba  

  $basename -local-sysdba 

/;
   exit $exitVal;
};

sub getOraVersion($$$) {
	my ($dbh,$major,$minor) = @_;

	my $sql=q{select
	substr(version,1,instr(version,'.')-1) major_version
	, substr (
		substr(version,instr(version,'.')+1), -- following the first '.'
		1, -- start at the first character
		instr(substr(version,instr(version,'.')+1),'.')-1 -- everything before the first '.'
	) minor_version
from v$instance};

	my $sth = $$dbh->prepare($sql,{ora_check_sql => 0});
	$sth->execute;
	($$major,$$minor) = $sth->fetchrow_array;

}

sub dec2bin {
	my $str = unpack("B32", pack("N", shift));
	$str =~ s/^0+(?=\d)//;   # otherwise you'll get leading zeros
	return $str;
}


