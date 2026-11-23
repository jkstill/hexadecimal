-- hexdump package: LONG
-- A LONG cannot be passed via cursor(), so the table, column and where clause are parameters.
-- The where clause may use one bind variable named :b, a NUMBER or a VARCHAR2.
@@settings

prompt
prompt == LONG column, VARCHAR2 bind value
prompt

select * from table(
	hexdump.hexdump_long(
		tab_name_in => 'HEXDUMP_DEMO_LONG',
		tab_column_in => 'TEXT',
		where_clause_in => 'where name = :b',
		where_bind_val => sys.anydata.convertvarchar2('short')
	)
);

prompt
prompt == LONG column, NUMBER bind value, table owner specified
prompt

select * from table(
	hexdump.hexdump_long(
		tab_owner_in => user,
		tab_name_in => 'HEXDUMP_DEMO_LONG',
		tab_column_in => 'TEXT',
		where_clause_in => 'where id = :b',
		where_bind_val => sys.anydata.convertnumber(1)
	)
);

prompt
prompt == a LONG of 4000 characters: number of lines output, including the 6 header lines
prompt

select count(*) line_count from table(
	hexdump.hexdump_long(
		tab_name_in => 'HEXDUMP_DEMO_LONG',
		tab_column_in => 'TEXT',
		where_clause_in => 'where name = :b',
		where_bind_val => sys.anydata.convertvarchar2('large')
	)
);

prompt
prompt == the SQL that is generated can be displayed
prompt

exec hexdump.show_sql_enable

select * from table(
	hexdump.hexdump_long(
		tab_name_in => 'HEXDUMP_DEMO_LONG',
		tab_column_in => 'TEXT',
		where_clause_in => 'where name = :b',
		where_bind_val => sys.anydata.convertvarchar2('short')
	)
);

exec hexdump.show_sql_disable
