# Hexdump demo scripts

These scripts create test data for every data type the hexdump packages can dump, show each capability, and remove the test data again.

## Requirements

Install the packages first, from the parent directory:

```
SQL> @hexdump.sql
SQL> @hexdump-binary.sql
SQL> @hexdump-long-raw.sql
```

`hexdump-long-raw.sql` and `setup-long-raw.sql` require the Oracle JVM. Everything else works without it.

## Running

Run the scripts with SQL*Plus from this directory.

```
SQL> @setup
SQL> @demo-all
SQL> @drop
```

Each demo script can also be run on its own.

## Files

| File | Purpose |
| --- | --- |
| `setup.sql` | Runs the four setup scripts and lists the objects created. |
| `setup-text.sql` | Table `HEXDUMP_DEMO_TEXT` with VARCHAR2, NUMBER and CLOB columns, including a 50000 character CLOB. |
| `setup-long.sql` | Table `HEXDUMP_DEMO_LONG` with a LONG column. |
| `setup-binary.sql` | Table `HEXDUMP_DEMO_BINARY` with RAW and BLOB columns, including a 20000 byte BLOB. |
| `setup-long-raw.sql` | Table `HEXDUMP_DEMO_LONG_RAW` with a LONG RAW column, including a NULL and a 100000 byte value. Also creates Java source `HexdumpDemoLoad` and procedure `HEXDUMP_DEMO_LOAD_LONG_RAW`, which load a LONG RAW of any size. |
| `demo-varchar2.sql` | `hexdump.hexdump`: literals, expressions, and columns via `cursor()`. |
| `demo-number.sql` | `hexdump.hexdump`: NUMBER values converted with `to_char()`. |
| `demo-clob.sql` | `hexdump.hexdump`: CLOB columns via `cursor()`, a large CLOB, and a CLOB variable in PL/SQL. |
| `demo-long.sql` | `hexdump.hexdump_long`: NUMBER and VARCHAR2 bind values, table owner, and display of the generated SQL. |
| `demo-raw.sql` | `hexdump_binary.hexdump_raw`: RAW values and columns via `cursor()`. |
| `demo-blob.sql` | `hexdump_binary.hexdump`: BLOB columns via `cursor()`, a larger BLOB, and a BLOB variable in PL/SQL. |
| `demo-long-raw.sql` | `hexdump_binary.hexdump_long_raw`: NUMBER and VARCHAR2 bind values, several rows in one query, a NULL value, a 100000 byte value, and fetching only the first rows. |
| `demo-all.sql` | Runs every demo script. |
| `settings.sql` | SQL*Plus settings shared by the demo scripts. |
| `drop.sql` | Drops all demo objects. The hexdump packages are not touched. |

## Limits the demo data stays within

The demo data was chosen to stay inside what the packages currently handle. These cases are deliberately not in the demos:

- **Multi byte characters with the `hexdump` package.** VARCHAR2, CLOB and LONG text that contains multi byte characters raises `ORA-06502`. The demos show multi byte data as bytes in RAW and BLOB instead.
- **A BLOB larger than 32767 bytes via `cursor()`.** Only the first 32767 bytes are dumped.
- **Several rows in one `cursor()` for BLOB or RAW.** Only the first row is dumped correctly. The demos select one row per query.
- **`rownum` on a BLOB dump.** Stopping the fetch early makes the package print a call stack through `dbms_output`.
- **A NUMBER passed without `to_char()`.** It raises `PLS-306`.

LONG RAW has none of these limits: `demo-long-raw.sql` dumps several rows, a 100000 byte value, and a partial fetch.
