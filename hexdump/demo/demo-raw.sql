-- hexdump_binary package: RAW
@@settings

prompt
prompt == RAW value via cursor()
prompt

select * from table(hexdump_binary.hexdump_raw(cursor(select hextoraw('DEADBEEF00FF41424344') from dual)));

prompt
prompt == RAW column via cursor(): every byte value from 00 to FF
prompt

select * from table(hexdump_binary.hexdump_raw(cursor(select my_raw from hexdump_demo_binary where name = 'all bytes')));

prompt
prompt == RAW column holding text: the euro sign is the three bytes E2 82 AC
prompt

select * from table(hexdump_binary.hexdump_raw(cursor(select my_raw from hexdump_demo_binary where name = 'text')));

prompt
prompt == a RAW of 17 bytes: the last line holds one byte
prompt

select * from table(hexdump_binary.hexdump_raw(cursor(select my_raw from hexdump_demo_binary where name = 'over 32k')));

prompt
prompt == several rows in one cursor(): each row starts with a separator line
prompt == and its addresses start again at 00000000
prompt == the NULL RAW gives one empty line, and a message through dbms_output
prompt

select * from table(hexdump_binary.hexdump_raw(cursor(
	select my_raw from hexdump_demo_binary where id > 1 order by id
)));
