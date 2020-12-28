

set serveroutput on format wrapped size unlimited
set linesize 200 trimspool on
set pagesize 0
set long 20000

col text format a50

spool bt-long.log

prompt
prompt !!  selecting from dictionary views will not work correctly in a PDB !!
prompt

SELECT * FROM  
TABLE(
	hexdump.hexdump_long(
		tab_owner_in => 'SYS',
		tab_name_in => 'DBA_VIEWS', 
		tab_column_in => 'TEXT', 
		where_clause_in => 'where text is not null and rownum < :b',
		where_bind_val => SYS.ANYDATA.convertNumber(2)
	)
)
/

SELECT * FROM  
TABLE(
	hexdump.hexdump_long(
		tab_name_in => 'LONG_TEST', 
		tab_column_in => 'TEXT', 
		where_clause_in => 'where text is not null and id = :b',
		where_bind_val => SYS.ANYDATA.convertNumber(1)
	)
)
/

SELECT * FROM  
TABLE(
	hexdump.hexdump_long(
		tab_name_in => 'LONG_TEST', 
		tab_column_in => 'TEXT', 
		where_clause_in => 'where text is not null and name = :b',
		where_bind_val => SYS.ANYDATA.convertVarchar2('jkstill')
	)
)
/


spool off

--ed bt-long.log
set pagesize 100



