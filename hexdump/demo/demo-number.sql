-- hexdump package: NUMBER
-- A NUMBER is dumped as its character representation, so convert it with to_char()
@@settings

prompt
prompt == NUMBER literal, called directly
prompt

select * from table(hexdump.hexdump(to_char(1234567.89)));

prompt
prompt == NUMBER with a format mask
prompt

select * from table(hexdump.hexdump(to_char(1234567.89,'999,999,990.0000')));

prompt
prompt == NUMBER column via cursor()
prompt

select * from table(hexdump.hexdump(cursor(select to_char(n_value) from hexdump_demo_text order by id)));
