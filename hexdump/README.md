
Hexdump for Oracle
==================

Having wanted a hexdump for oracle for some time, I finally put one together.

There are 2 packages

- hexdump, created by hexdump.sql
- hexdump_binary, created by hexdump-binary.sql

There are multiple ways to call hexdump:

- directly for a single value
- a column in a table via cursor()
- when dumping a LONG, then several parameters are set

The hexdump package currently supports these data types:

- VARCHAR2
- CLOB
- LONG
- NUMBER

While there is not yet any support for TIMESTAMP and DATE, those may be added in the future.

The methods to call hexdump_binary:
- directly for a single value
- a column in a table via cursor()

The hexdump_binary package currently supports these data types:

- BLOB
- RAW

There is not yet any support for LONG RAW.

In PL/SQL a LONG RAW can be manipulated as longs it the size is 32767 bytes or less.

This is quite limiting, as a LONG RAW may be up to 2G in size.

[Manipulate LONG RAW in PL/SQL](https://asktom.oracle.com/pls/apex/f?p=100:11:0::::P11_QUESTION_ID:201012348073)

Even though that is a 20 year old thread at this time, the situation has not changed.

Java could be used, I just haven't done it yet.

[LONG RAW Length from Java](https://stackoverflow.com/questions/5497238/get-the-length-of-a-long-raw)

A possibility would be to use Java to read the LONG RAW into an array of raw (hex) data.
Then pass the array back to PL/SQL for processing.

[How to return an array from Java to PL/SQL?](https://stackoverflow.com/questions/7872688/how-to-return-an-array-from-java-to-pl-sql)

Really, a BLOB should be used, rather than a LONG RAW.

But saying that does not help when one must work with what is supplied, and sometimes that is a LONG RAW.

# Using the hexdump package

## calling directly

```text
SQL# l
  1* SELECT * FROM  TABLE(hexdump.hexdump('this is a test'))
SQL# /

ADDRESS  DATA                                             TEXT
-------- ------------------------------------------------ ------------------
00000000 74 68 69 73 20 69 73 20 61 20 74 65 73 74        this is a test

1 row selected.
```

## calling via cursor()

### CLOB

```text

SQL# desc test_views
 Name                          Null?    Type
 ----------------------------- -------- --------------------
 VIEW_NAME                              VARCHAR2(30)
 VIEW_TEXT                              CLOB

SQL# l
  1* SELECT * FROM  TABLE(hexdump.hexdump(cursor(select view_text from test_views)))

ADDRESS  DATA                                             TEXT
-------- ------------------------------------------------ ------------------
00000000 0A 73 65 6C 65 63 74 20 75 2E 6E 61 6D 65 2C 20  |.select u.name, |
00000010 75 2E 75 73 65 72 23 2C 0A 20 20 20 20 20 64 65  |u.user#,.     de|
00000020 63 6F 64 65 28 75 2E 70 61 73 73 77 6F 72 64 2C  |code(u.password,|
...
00000CC0 2C 20 27 4E 4F 27 29 2C 0A 20 20 20 20 20 2D 2D  |, 'NO'),.     --|
00000CD0 20 50 41 53 53 57 4F 52 44 5F 43 48 41 4E 47 45  | PASSWORD_CHANGE|
00000CE0 5F 44 41 54 45 0A                                |_DATE.|

207 rows selected.
```

### LONG

Dumping a LONG is much different.  This is due to difficulties in working with LONGs in PL/SQL.

A cursor with a LONG cannot be passed via `table(select * from some_table)`

Due to that, dynamic SQL is used via DBMS_SQL.

The inputs to the hexdump_binary.hexdump_long have been sanitized and quoted to avoid SQL Injection.

This package is intended more as a troubleshooting tool than an application tool, and so is not expected to be used as part of an application.

Nonetheless, some care was taken to minimize the possibility of SQL Injection.

The data is just a long string of '='.

```text
SQL# desc LONG_TEST
 Name                          Null?    Type
 ----------------------------- -------- --------------------
 ID                                     NUMBER
 NAME                                   VARCHAR2(10)
 TEXT                                   LONG

  1  SELECT * FROM
  2  TABLE(
  3     hexdump.hexdump_long(
  4        tab_name_in => 'LONG_TEST',
  5        tab_column_in => 'TEXT',
  6        where_clause_in => 'where text is not null and name = :b',
  7        where_bind_val => SYS.ANYDATA.convertVarchar2('jkstill')
  8     )
  9* )

ADDRESS  DATA                                             TEXT
-------- ------------------------------------------------ --------------------------------------------------
======== ================================================ ==================
SCHEMA:  JKSTILL
TABLE:   LONG_TEST
COLUMN:  TEXT
SEARCH:  jkstill
======== ================================================ ==================
00000000 3D 3D 3D 3D 3D 3D 3D 3D 3D 3D 3D 3D 3D 3D 3D 3D  |================|
00000010 3D 3D 3D 3D 3D 3D 3D 3D 3D 3D 3D 3D 3D 3D 3D 3D  |================|
00000020 3D 3D 3D 3D 3D 3D 3D 3D 3D 3D 3D 3D 3D 3D 3D 3D  |================|
...

256 rows selected.

```
# Using the hexdump_binary package

## calling directly

Calling hexdump_binary.hexdump directly is done from PL/SQL

The file `blob-test-2.sql` has the followng example code:

```sql
var blob_test blob

set serveroutput on format wrapped size unlimited

declare
   b_blob blob;
   c_str clob;
   r_buf raw(256);
begin

   dbms_lob.createtemporary (
      lob_loc  => b_blob,
      cache    => true,
      dur      => dbms_lob.session
   );

   dbms_lob.createtemporary (
      lob_loc  => c_str,
      cache    => true,
      dur      => dbms_lob.session
   );

   r_buf := utl_raw.cast_to_raw(rpad(chr(65),256,chr(65)));

   dbms_lob.writeappend (
      lob_loc  => b_blob,
      amount   => dbms_lob.getlength(r_buf),
      buffer   => r_buf
   );

   -- a global var that must be initialized for hexdump
   hexdump_binary.set_i_blob_idx(1);

   for srec in (select * from table(hexdump_binary.hexdump(b_blob)))
   loop
      dbms_output.put(srec.address || ' ');
      dbms_output.put(srec.data || ' ');
      dbms_output.put_line(srec.text);
   end loop;

   :blob_test := b_blob;
end;
/

select :blob_test from dual;

```

Results:

```text
SQL# @blob-test-2
00000000 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 |AAAAAAAAAAAAAAAA|
00000010 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 |AAAAAAAAAAAAAAAA|
00000020 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 |AAAAAAAAAAAAAAAA|
00000030 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 |AAAAAAAAAAAAAAAA|
00000040 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 |AAAAAAAAAAAAAAAA|
00000050 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 |AAAAAAAAAAAAAAAA|
00000060 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 |AAAAAAAAAAAAAAAA|
00000070 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 |AAAAAAAAAAAAAAAA|
00000080 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 |AAAAAAAAAAAAAAAA|
00000090 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 |AAAAAAAAAAAAAAAA|
000000A0 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 |AAAAAAAAAAAAAAAA|
000000B0 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 |AAAAAAAAAAAAAAAA|
000000C0 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 |AAAAAAAAAAAAAAAA|
000000D0 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 |AAAAAAAAAAAAAAAA|
000000E0 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 |AAAAAAAAAAAAAAAA|
000000F0 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 |AAAAAAAAAAAAAAAA|

PL/SQL procedure successfully completed.


:BLOB_TEST
----------------------------------------------
4141414141414141414141414141414141414141414...

1 row selected.

```

## calling via cursor()

### BLOB

See `blob-test.sql`

```text
SELECT * FROM  TABLE(hexdump_binary.hexdump(cursor(select my_blob from binary_test where name = 'BLOB' )))
SQL# /

ADDRESS  DATA                                             TEXT
-------- ------------------------------------------------ --------------------------------------------------
======== ================================================ ==================
00000000 27 7F 45 4C 46 02 01 01 00 00 00 00 00 00 00 00  |'.ELF...........|
00000010 00 02 00 3E 00 01 00 00 00 60 0C 40 00 00 00 00  |...>.....`.@....|
00000020 00 40 00 00 00 00 00 00 00 EF BF BD 21 00 00 00  |.@..........!...|
00000030 00 00 00 00 00 00 00 40 00 38 00 09 00 40 00 1C  |.......@.8...@..|
00000040 00 1B 00 06 00 00 00 05 00 00 00 40 00 00 00 00  |...........@....|
...
00002FA0 20 00 00 00 00 00 00 EF BF BD 00 00 00 00 00 00  | ...............|
00002FB0 00 00 00 00 00 00 00 00 00 01 00 00 00 00 00 00  |................|
00002FC0 00 00 00 00 00 00 00 00 00 27                    |.........'|

766 rows selected.

```

### RAW

```text
 1* SELECT * FROM  TABLE(hexdump_binary.hexdump_raw(cursor(select my_raw from binary_test where name = 'RAW' )))
SQL# /

ADDRESS  DATA                                             TEXT
-------- ------------------------------------------------ --------------------------------------------------
======== ================================================ ==================
00000000 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F  |................|
00000010 10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F  |................|
00000020 20 21 22 23 24 25 26 27 28 29 2A 2B 2C 2D 2E 2F  | !"#$%&'()*+,-./|
00000030 30 31 32 33 34 35 36 37 38 39 3A 3B 3C 3D 3E 3F  |0123456789:;<=>?|
00000040 40 41 42 43 44 45 46 47 48 49 4A 4B 4C 4D 4E 4F  |@ABCDEFGHIJKLMNO|
00000050 50 51 52 53 54 55 56 57 58 59 5A 5B 5C 5D 5E 5F  |PQRSTUVWXYZ[\]^_|
00000060 60 61 62 63 64 65 66 67 68 69 6A 6B 6C 6D 6E 6F  |`abcdefghijklmno|
00000070 70 71 72 73 74 75 76 77 78 79 7A 7B 7C 7D 7E 7F  |pqrstuvwxyz{|}~.|
00000080 EF BF BD                                         |...|

10 rows selected.

```

## Files

### hexdump.sql

This creates the package `hexdump`

### hexdump-binary.sql

This creates the package `hexdump_binaryb`

###  blob-load.pl

A Perl script that will delete any rows in `LONG_TEST`, and insert new rows for testing

```shell
$  $ORACLE_HOME/perl/bin/perl ./blob-load.pl  --database orcl --username scott --password tiger
Major/Minor version 19/0

```

### blob-test-long.sql

Demo of using 	hexdump.hexdump_long.

The interface for this is much different than the other functions, due to how LONGS are handled in the database.

example:

```sql
SELECT * FROM  
TABLE(
   hexdump.hexdump_long(
      tab_name_in => 'LONG_TEST', 
      tab_column_in => 'TEXT', 
      where_clause_in => 'where text is not null and id = :b',
      where_bind_val => SYS.ANYDATA.convertNumber(1)
   )
)

```

### blob-test.sql

Tests hexdump_binary.hexdump(cursor)

### blob-test-2.sql

Tests hexdump_binary.hexdump(clob) from PL/SQL.

### blob-test-raw.sql

Tests hexdump_binary.hexdump_raw

### create-long-test-table.sql

This creates the table `LONG_TEST` that is used for testing the packages.

### cursor-call.sql

Use a cursor to dump a column from  table

### dbms_sql.bind-demo.sql

A demo of using dbms_sql.bind_variable

### direct-call.sql

This script just calls the function for dumping a string as hex

```sql
SELECT * FROM  TABLE(hexdump.hexdump('this is a test'));
```
### plsql-init.sql

Sets PL/SQL flags

### test-views.sql

This script will create a table with a single row - part of the text of the DBA_VIEWS view.

This table is used in the `cursor-call.sql` script.

