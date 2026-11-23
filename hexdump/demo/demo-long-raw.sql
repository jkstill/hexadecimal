-- hexdump_binary package: LONG RAW
-- Requires hexdump-long-raw.sql and the Oracle JVM.
-- The interface is the same as hexdump.hexdump_long.
@@settings

prompt
prompt == LONG RAW column, VARCHAR2 bind value
prompt

select * from table(
	hexdump_binary.hexdump_long_raw(
		tab_name_in => 'HEXDUMP_DEMO_LONG_RAW',
		tab_column_in => 'PAYLOAD',
		where_clause_in => 'where name = :b',
		where_bind_val => sys.anydata.convertvarchar2('short')
	)
);

prompt
prompt == LONG RAW column, NUMBER bind value, table owner specified
prompt == 257 bytes, so the last line has one byte
prompt

select * from table(
	hexdump_binary.hexdump_long_raw(
		tab_owner_in => user,
		tab_name_in => 'HEXDUMP_DEMO_LONG_RAW',
		tab_column_in => 'PAYLOAD',
		where_clause_in => 'where id = :b',
		where_bind_val => sys.anydata.convertnumber(4)
	)
);

prompt
prompt == several rows in one query, in the order of the where clause
prompt == a separator line precedes each value, and a NULL value has no data lines
prompt

select * from table(
	hexdump_binary.hexdump_long_raw(
		tab_name_in => 'HEXDUMP_DEMO_LONG_RAW',
		tab_column_in => 'PAYLOAD',
		where_clause_in => 'where id in (1,2,4) and id <= :b order by id',
		where_bind_val => sys.anydata.convertnumber(2)
	)
);

prompt
prompt == no bind value
prompt

select * from table(
	hexdump_binary.hexdump_long_raw(
		tab_name_in => 'HEXDUMP_DEMO_LONG_RAW',
		tab_column_in => 'PAYLOAD',
		where_clause_in => 'where id = 1'
	)
);

prompt
prompt == a LONG RAW of 100000 bytes, larger than the 32767 byte PL/SQL limit
prompt == number of lines output: 6250 data lines and 1 separator
prompt

select count(*) line_count from table(
	hexdump_binary.hexdump_long_raw(
		tab_name_in => 'HEXDUMP_DEMO_LONG_RAW',
		tab_column_in => 'PAYLOAD',
		where_clause_in => 'where name = :b',
		where_bind_val => sys.anydata.convertvarchar2('large')
	)
);

prompt
prompt == the same LONG RAW: the first lines, the lines around 32767 bytes, and the last lines
prompt

select * from table(
	hexdump_binary.hexdump_long_raw(
		tab_name_in => 'HEXDUMP_DEMO_LONG_RAW',
		tab_column_in => 'PAYLOAD',
		where_clause_in => 'where name = :b',
		where_bind_val => sys.anydata.convertvarchar2('large')
	)
)
where address = '========'
	or address < '00000030'
	or address between '00007FE0' and '00008010'
	or address >= '00018680';

prompt
prompt == fetching only the first rows of a large dump
prompt

select * from table(
	hexdump_binary.hexdump_long_raw(
		tab_name_in => 'HEXDUMP_DEMO_LONG_RAW',
		tab_column_in => 'PAYLOAD',
		where_clause_in => 'where name = :b',
		where_bind_val => sys.anydata.convertvarchar2('large')
	)
)
where rownum <= 3;
