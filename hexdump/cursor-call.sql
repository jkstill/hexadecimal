
col address format a8
col text format a18
col data format a48

SELECT * FROM  TABLE(hexdump.hexdump(cursor(select  table_name from user_tables order by table_name)))
/

SELECT * FROM  TABLE(hexdump.hexdump(cursor(select view_text from test_views where view_name = 'DBA_USERS')))
/

