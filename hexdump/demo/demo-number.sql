-- hexdump package: NUMBER
-- A NUMBER is dumped as its character representation
@@settings

prompt
prompt == NUMBER literal, called directly
prompt

select * from table(hexdump.hexdump(1234567.89));

prompt
prompt == NUMBER with a format mask, converted with to_char()
prompt

select * from table(hexdump.hexdump(to_char(1234567.89,'999,999,990.0000')));

prompt
prompt == NUMBER column, called directly for each row
prompt

select t.id, h.*
from hexdump_demo_text t, table(hexdump.hexdump(t.n_value)) h
order by t.id, h.address;

prompt
prompt == NUMBER column via cursor()
prompt

select * from table(hexdump.hexdump(cursor(select n_value from hexdump_demo_text order by id)));
