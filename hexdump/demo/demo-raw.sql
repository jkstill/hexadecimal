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
