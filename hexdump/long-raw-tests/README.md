# LONG RAW tests

These scripts verify `hexdump_binary.hexdump_long_raw` byte for byte. They need Perl with DBI and DBD::Oracle, and the packages installed from the parent directory (`hexdump-binary.sql` and `hexdump-long-raw.sql`).

## Connection

The Perl scripts read the connection from three environment variables:

```
export ORACLE_TEST_DB=host/service
export ORACLE_TEST_USER=username
export ORACLE_TEST_PASSWORD=password
```

For a wallet connection, set `ORACLE_TEST_DB` to the alias and leave the other two empty.

## Self-contained test

`long-raw-stream-test.pl` creates its own table `HEXDUMP_LR_FIXTURE`, verifies 13 values from 0 to 2097153 bytes through one multi-row cursor, checks early termination, and drops the table when it ends.

```
perl long-raw-stream-test.pl
```

## Tests that share a fixture table

The remaining scripts use table `HXATP_FIXTURE`. Each row holds a repeating 00 to FF pattern, and the `id` of a row is its length in bytes.

| Script | Purpose |
| --- | --- |
| `load-all.pl` | Creates `HXATP_FIXTURE` with 13 rows, from NULL to 2097153 bytes. Use this one for the scripts below. |
| `load.pl` | Creates `HXATP_FIXTURE` with 10 of those rows. Enough for `check.sql` only. |
| `check.sql` | SQL*Plus script. Verifies every line of every row in a server-side PL/SQL loop. |
| `perl-fetch.pl` | Fetches each row from the client. Rows above 17 bytes are sorted on the server before the fetch. |
| `direct-fetch.pl` | Fetches each row unsorted, with one connection per row. Usage: `perl direct-fetch.pl <row cache> <id> [<id> ...]` |
| `multi-row-probe.pl` | Fetches several rows through one cursor. Usage: `perl multi-row-probe.pl <label> <row cache> <bind value> "<where clause>" [count]` |
| `early-termination.pl` | Stops fetching a large dump early, then reuses the session, and reports the session PGA. |

Example run:

```
perl load-all.pl
sqlplus user/password@db @check.sql
perl perl-fetch.pl
perl direct-fetch.pl 100 0 1 16 17 1999 2000 2001 8191 8192 8193 32767 32768 2097153
perl multi-row-probe.pl "all rows" 100 0 "where id >= :b"
perl multi-row-probe.pl "all rows, row cache 1" 1 0 "where id >= :b and id < 40000"
perl early-termination.pl
```

Remove the fixture table afterwards:

```
SQL> drop table hxatp_fixture purge;
```
