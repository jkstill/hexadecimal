-- Test data for the hexdump_binary package: RAW and BLOB
create table hexdump_demo_binary (
	id number primary key,
	name varchar2(30),
	my_raw raw(2000),
	my_blob blob
);

-- every byte value from 00 to FF, in a RAW and in a BLOB
declare
	r raw(256);
begin
	for i in 0 .. 255
	loop
		r := utl_raw.concat(r, hextoraw(to_char(i,'FM0X')));
	end loop;
	insert into hexdump_demo_binary values (1, 'all bytes', r, r);
end;
/

-- text, including the multi byte UTF-8 encoding of the euro sign
insert into hexdump_demo_binary values (
	2, 'text',
	utl_i18n.string_to_raw('RAW text, euro sign: ' || unistr('\20AC'), 'AL32UTF8'),
	utl_i18n.string_to_raw('BLOB text, euro sign: ' || unistr('\20AC'), 'AL32UTF8')
);

-- a larger BLOB, 20000 bytes
declare
	b blob;
	r raw(256);
begin
	for i in 0 .. 255
	loop
		r := utl_raw.concat(r, hextoraw(to_char(i,'FM0X')));
	end loop;
	insert into hexdump_demo_binary values (3, 'large', hextoraw('CAFEBABE'), empty_blob())
	returning my_blob into b;
	for i in 1 .. 78
	loop
		dbms_lob.writeappend(b, 256, r);
	end loop;
	dbms_lob.writeappend(b, 32, utl_raw.substr(r, 1, 32));
end;
/

commit;
