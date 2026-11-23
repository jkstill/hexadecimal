
set linesize 250 trimspool on
set pagesize 100

SELECT * FROM  TABLE(hexdump.hexdump(cursor(select  sql_fulltext from v$sql binary_test where rownum < 2 )))
/
