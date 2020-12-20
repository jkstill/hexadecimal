
radix.sql
=========

This is a package I created long ago to convert to various bases

There is no warranty, expressed or implied, though it may still be useful.


```text
SQL# @test

RADIX.TO_HEX(285)
----------------------------------------
11D

1 row selected.


RADIX.TO_DEC('11D',16)
----------------------
                   285

1 row selected.


RADIX.TO_BIN(255)
----------------------------------------
11111111

1 row selected.


RADIX.TO_BIN(256)
----------------------------------------
100000000

1 row selected.

```

## RCS

You may notice the RCS directory.

This is a file based built in version control in Unix/Linux. 

It was retained for historical purposes




