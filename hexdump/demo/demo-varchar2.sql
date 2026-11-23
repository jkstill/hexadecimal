-- hexdump package: VARCHAR2
@@settings

prompt
prompt == VARCHAR2 literal, called directly
prompt

select * from table(hexdump.hexdump('ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789'));

prompt
prompt == VARCHAR2 expression, called directly
prompt

select * from table(hexdump.hexdump(user || ' connected at ' || to_char(sysdate,'yyyy-mm-dd hh24:mi:ss')));

prompt
prompt == VARCHAR2 column via cursor()
prompt

select * from table(hexdump.hexdump(cursor(select v_text from hexdump_demo_text where name = 'ascii')));

prompt
prompt == non printable characters are shown as a period in the TEXT column
prompt

select * from table(hexdump.hexdump(cursor(select v_text from hexdump_demo_text where name = 'special')));

prompt
prompt == several rows via cursor(): a separator line precedes each value
prompt

select * from table(hexdump.hexdump(cursor(select v_text from hexdump_demo_text order by id)));

prompt
prompt == multibyte characters: each line holds 16 bytes and the address counts bytes
prompt == every byte of a multibyte character is shown as ^ in the TEXT column
prompt

select * from table(hexdump.hexdump(cursor(select v_text from hexdump_demo_text where name = 'multibyte')));

prompt
prompt == a multibyte character built in SQL: the euro sign is the three bytes E2 82 AC in AL32UTF8
prompt

select * from table(hexdump.hexdump('price: ' || to_char(unistr('\20AC')) || '5'));
