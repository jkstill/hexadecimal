# ORA-07445 when a server-side JDBC LONG RAW cursor is used across database calls

This directory is a self-contained test case for an Oracle Service Request. It needs only a schema with `CREATE TABLE` and `CREATE PROCEDURE`, the Oracle JVM, and SQL*Plus.

## Problem summary

A Java stored procedure opens a `ResultSet` over a LONG RAW column on the server-side internal JDBC connection (`jdbc:default:connection:`) and keeps it in a static field so that later calls from the same session can continue reading. If the cursor is advanced, or the value is first read, in a later database call than the one before it, the dedicated server process dies with `ORA-07445` (SIGSEGV in a memcpy routine). The client sees `ORA-03113`.

No error is raised to Java or PL/SQL. The session is lost.

The same code against a `RAW(2000)` column works across calls. The same LONG RAW code works when every step happens inside one database call.

## Expected and actual behavior

- **Expected:** either the operation succeeds, as it does for other column types, or the JDBC driver raises a SQL exception stating that a LONG RAW stream cannot be continued in a later call.
- **Actual:** the server process crashes with `ORA-07445`.

## Where it reproduces

| Database | Version | Platform | Result |
| --- | --- | --- | --- |
| Oracle AI Database 26ai Enterprise Edition, on-premises | 23.26.1.0.0 | Linux x86 64-bit | `ORA-07445 [__intel_avx_rep_memcpy()+...]` |
| Oracle Database 19c Enterprise Edition, RAC, on-premises | 19.12.0.0.0 | Linux x86 64-bit | `ORA-07445 [__intel_avx_rep_memcpy()+...]` |
| Autonomous Transaction Processing | 23.26.4.1.0 | Oracle Cloud | `ORA-03113` on the client. The alert log is not available. |

All three databases use the AL32UTF8 character set. The client was SQL*Plus 21c. The crash was first seen from Perl DBD::Oracle, so it does not depend on the client.

## Files

| File | Purpose |
| --- | --- |
| `lrstep-setup.sql` | Creates table `LRSTEP_T` with two 20,000-byte LONG RAW rows, Java class `LrStep` and function `LRSTEP`. |
| `lrstep-run.sql` | Runs up to four database calls in the current session. |
| `lrstep-drop.sql` | Removes the objects created by `lrstep-setup.sql`. |
| `lrbug-setup.sql` | Creates `LRBUG_T` (LONG RAW) and `LRBUG_R` (`RAW(2000)`), three 2,000-byte rows each, and Java class `LrBug`. |
| `lrbug-run.sql` | Reads the rows of the named table in one call, then again one row per call. |
| `lrbug-drop.sql` | Removes the objects created by `lrbug-setup.sql`. |

## Test case 1: which call boundary crashes

Each call to the function `LRSTEP` is one database call. Its argument is a list of steps that are executed, in order, inside that call:

| Step | Java operation |
| --- | --- |
| `o` | `prepareStatement("select payload from lrstep_t order by id")` and `executeQuery()` |
| `n` | `ResultSet.next()` followed by `getBinaryStream(1)` |
| `r100` | read up to 100 bytes from the stream (any number may be given) |
| `R` | read the stream to its end |

Install once:

```
SQL> @lrstep-setup.sql
```

Then run each case in a **new session**. The arguments to `lrstep-run.sql` are the calls, and unused arguments are passed as empty strings.

| Case | Command | Result on all three databases |
| --- | --- | --- |
| A | `@lrstep-run "o n R n R n" "" "" ""` | Passes. Both rows are read inside one call. |
| B | `@lrstep-run "o n r100" "R" "" ""` | Passes. The first read shares a call with `next`, and the rest of the value is read in a later call. |
| C | `@lrstep-run "o" "n R" "" ""` | **Crashes** at `next`. |
| D | `@lrstep-run "o n" "R" "" ""` | **Crashes** at the first read. |
| E | `@lrstep-run "o n R" "n R" "" ""` | **Crashes** at the second `next`. |
| F | `@lrstep-run "o n r100" "R" "n R" ""` | **Crashes** at the second `next`. |

Output of a passing case (B):

```
open row read=100
read=19900
SESSION ALIVE
```

Output of a failing case (D):

```
open row
select lrstep('R') from dual where 'R' is not null
*
ERROR at line 1:
ORA-03113: end-of-file on communication channel
Process ID: 578188
Session ID: 246 Serial number: 53049
```

Remove the objects afterwards:

```
SQL> @lrstep-drop.sql
```

### What the cases show

1. `executeQuery`, `next` and the first read of a LONG RAW value must all happen in the same database call (cases C and D).
2. After the first read, the remainder of that value can be read in later calls (case B).
3. Advancing the cursor to another row in a later call always crashes, even when the previous value was read completely (cases E and F).

## Test case 2: control with a RAW column

This shows that the crash is specific to LONG RAW. The Java code is the same for both tables. Only the table name changes.

```
SQL> @lrbug-setup.sql
SQL> @lrbug-run LRBUG_R
SQL> @lrbug-run LRBUG_T
SQL> @lrbug-drop.sql
```

With `LRBUG_R` every call succeeds and the script ends with `session alive`:

```
==== LRBUG_R: one call, open and read all rows
       6000
==== LRBUG_R: call 1, executeQuery only
==== LRBUG_R: call 2, first row
row bytes: 2000
==== LRBUG_R: call 3, second row
row bytes: 2000
==== LRBUG_R: call 4, third row
row bytes: 2000
==== LRBUG_R: call 5, end of data
row bytes: -1
session alive
```

With `LRBUG_T` the single-call read succeeds and returns 6000, then the session is lost at call 2:

```
==== LRBUG_T: one call, open and read all rows
       6000
==== LRBUG_T: call 1, executeQuery only
==== LRBUG_T: call 2, first row
ERROR at line 1:
ORA-03113: end-of-file on communication channel
```

This test case calls `setFetchSize(1)` on the statement. Test case 1 does not. Both crash, so the fetch size is not a factor.

## Evidence from the alert logs

All entries are from 22 November 2026. The failing address is always `ADDR:0x0`.

26ai, 23.26.1.0.0:

| Time | Incident | Trace file | Error | Scenario |
| --- | --- | --- | --- | --- |
| 16:35:33 | 47170 | `orcl_ora_576421.trc` | `ORA-07445 [__intel_avx_rep_memcpy()+160] [SIGSEGV] [ADDR:0x0] [PC:0x8870DF0]` | Test case 2, call 2 |
| 16:36:18 | 46706 | `orcl_ora_576502.trc` | Same as above | Test case 2, call 2 |
| 16:44:03 | 46498 | `orcl_ora_576812.trc` | `ORA-07445 [__intel_avx_rep_memcpy()+320] [SIGSEGV] [ADDR:0x0] [PC:0x8870E90]` | Case C |
| 16:44:10 | 47249 | `orcl_ora_576827.trc` | Same as above | Case D |
| 16:44:16 | 47273 | `orcl_ora_576842.trc` | `ORA-07445 [__intel_avx_rep_memcpy()+211] [SIGSEGV] [ADDR:0x0] [PC:0x8870E23]` | Second `next` in a later call |

19c, 19.12.0.0.0:

| Time | Incident | Trace file | Error | Scenario |
| --- | --- | --- | --- | --- |
| 16:36:24 | 521182 | `cdb2_ora_25568.trc` | `ORA-07445 [__intel_avx_rep_memcpy()+144] [SIGSEGV] [ADDR:0x0] [PC:0x6D90350]` | Test case 2, call 2 |
| 16:44:49 | 521191 | `cdb2_ora_27155.trc` | `ORA-07445 [__intel_avx_rep_memcpy()+304] [SIGSEGV] [ADDR:0x0] [PC:0x6D903F0]` | Case C |
| 16:44:50 | 521326 | `cdb2_ora_27162.trc` | Same as above | Case D |
| 16:44:51 | 521342 | `cdb2_ora_27172.trc` | `ORA-07445 [__intel_avx_rep_memcpy()+195] [SIGSEGV] [ADDR:0x0] [PC:0x6D90383]` | Case E |
| 16:44:52 | 521350 | `cdb2_ora_27178.trc` | Same as above | Case F |

The incident trace files, which hold the call stacks, were not collected for this document. To package one for the SR, run this as the Oracle software owner on the database host:

```
adrci> set homepath diag/rdbms/orcl/orcl
adrci> ips pack incident 47170 in /tmp
```

## Workaround in use

Keep every LONG RAW statement to a single row and do `executeQuery`, `next` and the first read in one call. To process several rows, select their ROWIDs with an ordinary cursor, which can be fetched across calls, and run a separate single-row LONG RAW statement for each ROWID. Later reads of the same value may then span calls. This is what `hexdump-long-raw.sql` in the parent directory does.

## Questions for Oracle Support

1. Is continuing a server-side JDBC LONG RAW `ResultSet` in a later database call supported?
2. If it is not supported, can the driver raise an exception instead of crashing the server process?
3. Is it supported, and safe, to continue reading one LONG RAW stream in later calls once the first read has been done in the call that fetched the row? The workaround depends on this.
