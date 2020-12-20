
col address format a8
col text format a18
col data format a48

SELECT * FROM  TABLE(hexdump.hexdump(cursor(select view_text from test_views)))
/
