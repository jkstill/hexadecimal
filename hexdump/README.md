
Hexdump for Oracle
==================

Having wanted a hexdump for oracle for some time, I finally put one together.

It is still somewhat limited, in that it will not yet work with BLOBs.

That can be added though.

Currently there are two ways to call hexdump:

- directly for a single value
- columns in a table via cursor()

## calling directly

```
SQL# l
  1* SELECT * FROM  TABLE(hexdump.hexdump('this is a test'))
SQL# /

ADDRESS  DATA                                             TEXT
-------- ------------------------------------------------ ------------------
00000000 74 68 69 73 20 69 73 20 61 20 74 65 73 74        this is a test

1 row selected.
```

## calling via cursor()

```text
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

## Scripts

### hexdump.sql

This creates the package hexdump

### direct-call.sql

This script just calls the function for dumping a string as hex

```sql
SELECT * FROM  TABLE(hexdump.hexdump('this is a test'));
```

### cursor-call.sql

Use a cursor to dump a column from  table

```sql
col address format a8
col text format a18
col data format a48

SELECT * FROM  TABLE(hexdump.hexdump(cursor(select view_text from test_views)));
```

### test-views.sql

This script will create a table with a single row - part of the text of the DBA_VIEWS view.

This table is used in the `cursor-call.sql` script.

