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

my $sql = q{select my_long_raw from binary_test where name = ?};
my $sth = $dbh->prepare($sql);
$sth->execute(q{LONG RAW});
my ($longRaw) = $sth->fetchrow_array;
$sth->finish;

print "long raw length: " . length($longRaw) .  "\n";

$dbh->disconnect;

hexdump(\$longRaw);

# takes a reference to a variable
# the contents may be large so it is not copied
sub hexdump {
	my ($rawDataRef) = @_;

	my $offset=0;
	my $len=0;
	my $data='';

	while (	$data = substr($$rawDataRef,$offset,16) ) {
		$len = length($data);
		last if $len < 16;
		my @array = unpack('N4', $data);
		$data =~ tr/\0-\37\177-\377/./; # change non-printable values to '.'
		printf "%8.8lx   %8.8lx %8.8lx %8.8lx %8.8lx   %s\n", $offset, @array, $data;
		$offset += 16;
	}

	# process last line
	if($len) {
		my @array = unpack('C*',$data);
		$data =~ y/\0-\37\177-\377/./;
		for (@array) {
			$_ = sprintf('%2.2x',$_);
		}
		push(@array,'  ') while $len++ < 16;
		$data =~ s/[^ -~]/./g;
		printf "%8.8lx   ", $offset;
		printf "%s%s%s%s %s%s%s%s %s%s%s%s %s%s%s%s   %s\n", @array, $data;
	}

}



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

	return;
}

sub dec2bin {
	my $str = unpack("B32", pack("N", shift));
	$str =~ s/^0+(?=\d)//;   # otherwise you'll get leading zeros
	return $str;
}


