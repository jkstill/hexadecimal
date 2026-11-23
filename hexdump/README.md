
Hexdump for Oracle
==================

Having wanted a hexdump for oracle for some time, I finally put one together.

There are 2 packages

- hexdump, created by hexdump.sql
- hexdump_binary, created by hexdump-binary.sql

Dumping a LONG RAW also requires `hexdump-long-raw.sql`, which needs the Oracle JVM.

The `demo` directory has scripts that create test data for every supported data type, show each way of calling the packages, and remove the test data again. See `demo/README.md`.

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

Text is dumped as bytes in the database character set, 16 bytes per line, and the address counts bytes. In the text column each byte of a multibyte character is shown as `^`, and a non printable single byte character is shown as `.`.

The methods to call hexdump_binary:
- directly for a single value
- a column in a table via cursor()
- when dumping a LONG RAW, then several parameters are set

The hexdump_binary package currently supports these data types:

- BLOB
- RAW
- LONG RAW (requires the Oracle JVM, see `hexdump-long-raw.sql`)

# Using the hexdump package

For the following examples, run the script `test-views.sql` to create a test table with some CLOB data.

## calling directly

```text
SQL# l
  1* SELECT * FROM  TABLE(hexdump.hexdump('ABCDEFGHIJKLMNOP'))
SQL# /

ADDRESS  DATA                                             TEXT
-------- ------------------------------------------------ ------------------
00000000 41 42 43 44 45 46 47 48 49 4A 4B 4C 4D 4E 4F 50  |ABCDEFGHIJKLMNOP|

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

The inputs to the hexdump.hexdump_long have been sanitized and quoted to avoid SQL Injection.

This package is intended more as a troubleshooting tool than an application tool, and so is not expected to be used as part of an application.

Nonetheless, some care was taken to minimize the possibility of SQL Injection.

Create the test table via `create-long-test-table.sql`

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

The sql script `blob-test-long.sql` has the above example.

### NUMBER

A NUMBER is dumped as its character representation. Use `to_char()` to apply a format mask.

See `demo/demo-number.sql`

```text
SQL# SELECT * FROM  TABLE(hexdump.hexdump(1234567.89));

ADDRESS  DATA                                             TEXT
-------- ------------------------------------------------ --------------------------------------------------
00000000 31 32 33 34 35 36 37 2E 38 39                    |1234567.89|

1 row selected.
```

### Multibyte characters

Each byte of a multibyte character is shown as `^` in the text column. Here the text contains a 2 byte, a 3 byte and a 4 byte character.

See `demo/demo-varchar2.sql` and `demo/demo-clob.sql`

```text
SQL# SELECT * FROM  TABLE(hexdump.hexdump(cursor(select v_text from hexdump_demo_text where name = 'multibyte')));

ADDRESS  DATA                                             TEXT
-------- ------------------------------------------------ --------------------------------------------------
======== ================================================ ==================
00000000 63 61 66 C3 A9 20 63 6F 73 74 73 20 35 E2 82 AC  |caf^^ costs 5^^^|
00000010 20 F0 9F 98 80 20 65 6E 64                       | ^^^^ end|

3 rows selected.
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

### LONG RAW

As with a LONG, a LONG RAW cannot be passed via cursor(), so the table, column and WHERE clause are passed as parameters. The interface is the same as `hexdump.hexdump_long`, and the bind value may be a NUMBER or a VARCHAR2.

This requires `hexdump-long-raw.sql` and the Oracle JVM.

The examples use the table created by `demo/setup-long-raw.sql`. See `demo/demo-long-raw.sql` for more.

```text
SQL# desc HEXDUMP_DEMO_LONG_RAW
 Name                          Null?    Type
 ----------------------------- -------- --------------------
 ID                            NOT NULL NUMBER
 NAME                                   VARCHAR2(30)
 PAYLOAD                                LONG RAW

  1  SELECT * FROM
  2  TABLE(
  3     hexdump_binary.hexdump_long_raw(
  4        tab_name_in => 'HEXDUMP_DEMO_LONG_RAW',
  5        tab_column_in => 'PAYLOAD',
  6        where_clause_in => 'where name = :b',
  7        where_bind_val => SYS.ANYDATA.convertVarchar2('short')
  8     )
  9* )

ADDRESS  DATA                                             TEXT
-------- ------------------------------------------------ --------------------------------------------------
======== ================================================ ==================
00000000 41 20 73 68 6F 72 74 20 4C 4F 4E 47 20 52 41 57  |A short LONG RAW|
00000010 20 76 61 6C 75 65                                | value|

3 rows selected.
```

The size of the LONG RAW is not limited to 32767 bytes. This value is 100000 bytes:

```text
  1  SELECT * FROM
  2  TABLE(
  3     hexdump_binary.hexdump_long_raw(
  4        tab_name_in => 'HEXDUMP_DEMO_LONG_RAW',
  5        tab_column_in => 'PAYLOAD',
  6        where_clause_in => 'where id = :b',
  7        where_bind_val => SYS.ANYDATA.convertNumber(3)
  8     )
  9* )

ADDRESS  DATA                                             TEXT
-------- ------------------------------------------------ --------------------------------------------------
======== ================================================ ==================
00000000 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F  |................|
00000010 10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F  |................|
00000020 20 21 22 23 24 25 26 27 28 29 2A 2B 2C 2D 2E 2F  | !"#$%&'()*+,-./|
...
00018680 80 81 82 83 84 85 86 87 88 89 8A 8B 8C 8D 8E 8F  |................|
00018690 90 91 92 93 94 95 96 97 98 99 9A 9B 9C 9D 9E 9F  |................|

6251 rows selected.
```

## Files

### demo

Scripts to set up test data, demonstrate every supported data type, and drop the test data. See `demo/README.md`.

### bug-testcase

A test case for the ORA-07445 that occurs when a LONG RAW cursor is read across database calls. See `bug-testcase/README.md`.

### long-raw-tests

Perl and SQL scripts that verify `hexdump_binary.hexdump_long_raw` byte for byte. See `long-raw-tests/README.md`.

### hexdump.sql

This creates the package `hexdump`

### hexdump-binary.sql

This creates the package `hexdump_binary`

### hexdump-long-raw.sql

This creates the Java reader used by `hexdump_binary.hexdump_long_raw`. It requires the Oracle JVM.

Install it after `hexdump-binary.sql`. It is not needed for dumping BLOB and RAW.

The interface is the same as `hexdump.hexdump_long`. The bind value may be a NUMBER or a VARCHAR2.

example:

```sql
SELECT * FROM
TABLE(
   hexdump_binary.hexdump_long_raw(
      tab_name_in => 'BINARY_TEST',
      tab_column_in => 'MY_LONG_RAW',
      where_clause_in => 'where name = :b',
      where_bind_val => SYS.ANYDATA.convertVarchar2('VERY LONG RAW')
   )
)

```

A separator line is output before each row that is dumped. The values are read in 2000 byte pieces, so the size of the LONG RAW is not limited by PL/SQL.

Each LONG RAW is read by ROWID with its own statement. Reading several LONG RAW rows from one cursor crashes the server process with ORA-07445, see `bug-testcase/README.md`.

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

