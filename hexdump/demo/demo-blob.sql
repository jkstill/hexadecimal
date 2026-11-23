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
