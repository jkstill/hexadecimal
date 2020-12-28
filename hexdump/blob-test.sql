
set serveroutput on format wrapped size unlimited
set linesize 200 trimspool on
set pagesize 0
col text format a50

set long 20000

spool bt.log

SELECT * FROM  TABLE(hexdump_binary.hexdump(cursor(select my_blob from binary_test where name = 'BLOB' )))
/

spool off

ed bt.log
set pagesize 100



