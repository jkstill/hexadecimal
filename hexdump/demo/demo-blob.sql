-- hexdump_binary package: BLOB
@@settings

prompt
prompt == BLOB column via cursor(): every byte value from 00 to FF
prompt

select * from table(hexdump_binary.hexdump(cursor(select my_blob from hexdump_demo_binary where name = 'all bytes')));

prompt
prompt == BLOB column holding text
prompt

select * from table(hexdump_binary.hexdump(cursor(select my_blob from hexdump_demo_binary where name = 'text')));

prompt
prompt == a BLOB of 20000 bytes: number of lines output
prompt

select count(*) line_count
from table(hexdump_binary.hexdump(cursor(select my_blob from hexdump_demo_binary where name = 'large')));

prompt
prompt == the same BLOB: the first lines and the lines after address 00004E00
prompt

select * from table(hexdump_binary.hexdump(cursor(select my_blob from hexdump_demo_binary where name = 'large')))
where address < '00000030' or address = '========';

select * from table(hexdump_binary.hexdump(cursor(select my_blob from hexdump_demo_binary where name = 'large')))
where address >= '00004E00' and address < '========';

prompt
prompt == a BLOB of 40961 bytes, larger than one 32767 byte read: number of lines output
prompt == 2561 data lines and one separator line are expected
prompt

select count(*) line_count
from table(hexdump_binary.hexdump(cursor(select my_blob from hexdump_demo_binary where name = 'over 32k')));

prompt
prompt == the same BLOB: the lines either side of byte 32767, and the last lines
prompt

select * from table(hexdump_binary.hexdump(cursor(select my_blob from hexdump_demo_binary where name = 'over 32k')))
where address between '00007FE0' and '00008010';

select * from table(hexdump_binary.hexdump(cursor(select my_blob from hexdump_demo_binary where name = 'over 32k')))
where address >= '00009FE0' and address < '========';

prompt
prompt == several rows in one cursor(): each row starts with a separator line
prompt == and its addresses start again at 00000000
prompt

select * from table(hexdump_binary.hexdump(cursor(
	select my_blob from hexdump_demo_binary where name in ('text','all bytes') order by id desc
)));

prompt
prompt == every row in one cursor(): number of lines per row
prompt == the NULL BLOB gives one empty line, and a message through dbms_output
prompt

select row_num, count(*) - 1 line_count
from (
	select sum(case when address = '========' then 1 else 0 end) over (order by rownum) row_num
	from table(hexdump_binary.hexdump(cursor(select my_blob from hexdump_demo_binary order by id)))
)
group by row_num
order by row_num;

prompt
prompt == fetching only the first lines of a large BLOB with rownum
prompt

select * from table(hexdump_binary.hexdump(cursor(select my_blob from hexdump_demo_binary where name = 'over 32k')))
where rownum <= 5;

prompt
prompt == BLOB variable from PL/SQL
prompt == set_i_blob_idx(1) must be called before each direct call
prompt

declare
	b blob;
	r raw(100) := utl_raw.concat(utl_raw.cast_to_raw('A temporary BLOB built in PL/SQL '), hextoraw('00FF7F80'));
begin
	dbms_lob.createtemporary(b, true, dbms_lob.session);
	dbms_lob.writeappend(b, utl_raw.length(r), r);

	hexdump_binary.set_i_blob_idx(1);

	for srec in (select * from table(hexdump_binary.hexdump(b)))
	loop
		dbms_output.put_line(srec.address || ' ' || rpad(srec.data,48) || ' ' || srec.text);
	end loop;
end;
/
