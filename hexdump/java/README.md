

Using these examples and code:

https://docs.oracle.com/cd/B10501_01/appdev.920/a96595/dci12tbl.htm
https://docs.oracle.com/cd/B10501_01/appdev.920/a96595/dciappa1.htm#620714

The Oracle Data Cartridge must be used to expose PIPELINED to Java or C

https://docs.oracle.com/en/database/oracle/oracle-database/12.2/lnpls/PIPELINED-clause.html#GUID-FA182210-C68D-4E03-85B9-A6C681099705

A Java interface must be created that implements the Start/Fetch/Close operations

This is being done in 'StockPivotImpl.java'

See java-dir.sql

For now, I am not going to work on the LONG RAW any longer

-----------------

# create tables and types
  pipeline-objects.sql

# compile and load java
  java-dir.sql

# populate the table with 110 rows
  pop.sql

# run the pipelined java function
  stocktable-query.sql

----------------


Everything loads and compiles, but...

This is with a 3 column table with 110 rows:

SQL# SELECT * FROM TABLE(StockPivot(CURSOR(SELECT * FROM StockTable where rownum < 2)))l

SELECT * FROM TABLE(StockPivot(CURSOR(SELECT * FROM StockTable where rownum < 2)))
*
ERROR at line 1:
ORA-04031: unable to allocate 4096 bytes of shared memory ("java pool","oracle/jdbc/driver/Redirecto...","JOXLE^9cb53236",":SGAClass")


There was no way it would work in this instance without allocating more Java pool

This query used 900K of Java Pool memory, and needed more.

Seems a bit unreasonable.


JKSTILL@ora192rac02/pdb1.jks.com > get afiedt.buf
  1  select *
  2  from v$sgastat
  3* where pool like '%java%'
JKSTILL@ora192rac02/pdb1.jks.com > /

POOL           NAME                            BYTES     CON_ID
-------------- -------------------------- ---------- ----------
java pool      free memory                   1753920          0
java pool      JOXLE                        36013824          3
java pool      joxs heap                      758016          3

3 rows selected.

JKSTILL@ora192rac02/pdb1.jks.com > @stocktable-query.sql 
SELECT * FROM TABLE(StockPivot(CURSOR(SELECT * FROM StockTable where rownum < 2)))
                                             *
ERROR at line 1:
ORA-04031: unable to allocate 4096 bytes of shared memory ("java pool","prv//////ANJLEINAAAAAAAAA","JOXLE^19885689",":SGAClass")

Increased to 250M and bounced the instance

SELECT * FROM TABLE(StockPivot(CURSOR(SELECT * FROM StockTable )))
JKSTILL@ora192rac02/pdb1.jks.com > /

TICK P      PRICE
---- - ----------
UFBJ O 7.09521103
UFBJ C 9.80295277
UFBJ O 6.44132185
UFBJ C 9.11012459
...
220 rows selected.

This require 48M of Java Pool

KSTILL@ora192rac02/pdb1.jks.com > @java-pool

POOL           NAME                            BYTES     CON_ID
-------------- -------------------------- ---------- ----------
java pool      free memory                 176675200          0
java pool      JOXLE                        47565504          3
java pool      joxs heap                     1483776          3

3 rows selected.


But, it does work


