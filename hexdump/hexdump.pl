#!/usr/bin/env perl
#

open (STDIN,$ARGV[0]) || die "cannot open $ARGV[0]: $!\n" 
	if $ARGV[0];

while (($len = read(STDIN, $data,16)) == 16 ) {
	@array = unpack('N4', $data);
	$data =~ tr/\0-\37\177-\377/./;
	printf "%8.8lx   %8.8lx %8.8lx %8.8lx %8.8lx   %s\n", $offset, @array, $data;
	$offset += 16;
}

if($len) {
	@array = unpack('C*',$data);
	$data =~ y/\0-\37\177-\377/./;
	for (@array) {
		$_ = sprintf('%2.2x',$_);
	}
	push(@array,'  ') while $len++ < 16;
	$data =~ s/[^ -~]/./g;
	printf "%8.8lx   ", $offset;
	printf "%s%s%s%s %s%s%s%s %s%s%s%s %s%s%s%s   %s\n", @array, $data;
}
	
