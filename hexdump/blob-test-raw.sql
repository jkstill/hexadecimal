
set serveroutput on format wrapped size unlimited
set linesize 250 trimspool on
set pagesize 0
col text format a50
col data format a50
col address format a10

spool bt.log

SELECT * FROM  TABLE(hexdump_binary.hexdump_raw(cursor(select my_raw from binary_test where name = 'RAW' )))
/

spool off

--ed bt.log
set pagesize 100



