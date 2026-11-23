-- hexdump package: CLOB
@@settings

prompt
prompt == CLOB column via cursor()
prompt

select * from table(hexdump.hexdump(cursor(select c_text from hexdump_demo_text where name = 'ascii')));

prompt
prompt == CR and LF are visible in the DATA column as 0D 0A
prompt

select * from table(hexdump.hexdump(cursor(select c_text from hexdump_demo_text where name = 'special')));

prompt
prompt == a CLOB of 50000 characters: number of lines output
prompt

select count(*) line_count
from table(hexdump.hexdump(cursor(select c_text from hexdump_demo_text where name = 'large')));

prompt
prompt == the same CLOB: the first lines and the lines after address 0000C300
prompt

select * from table(hexdump.hexdump(cursor(select c_text from hexdump_demo_text where name = 'large')))
where rownum <= 5;

select * from table(hexdump.hexdump(cursor(select c_text from hexdump_demo_text where name = 'large')))
where address >= '0000C300' and address < '========';

prompt
prompt == CLOB from PL/SQL
prompt

declare
	c clob := 'A CLOB variable in PL/SQL';
begin
	for srec in (select * from table(hexdump.hexdump(c)))
	loop
		dbms_output.put_line(srec.address || ' ' || rpad(srec.data,48) || ' ' || srec.text);
	end loop;
end;
/

prompt
prompt == CLOB with multibyte characters
prompt == the last euro sign starts on one line and ends on the next
prompt

select * from table(hexdump.hexdump(cursor(select c_text from hexdump_demo_text where name = 'multibyte')));
