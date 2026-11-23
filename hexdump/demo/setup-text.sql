-- Test data for the hexdump package: VARCHAR2, NUMBER and CLOB
create table hexdump_demo_text (
	id number primary key,
	name varchar2(30),
	v_text varchar2(200),
	n_value number,
	c_text clob
);

insert into hexdump_demo_text values (
	1, 'ascii',
	'The quick brown fox jumps over the lazy dog',
	1234567.89,
	'A short CLOB.' || chr(10) || 'It has two lines and a tab' || chr(9) || 'character.'
);

-- non printable characters
insert into hexdump_demo_text values (
	2, 'special',
	'tab' || chr(9) || 'newline' || chr(10) || 'return' || chr(13) || 'null' || chr(0) || 'end',
	-0.000123,
	'CLOB with CR/LF' || chr(13) || chr(10) || 'and a trailing space '
);

-- multibyte characters: e acute is 2 bytes, the euro sign 3 bytes and the emoji 4 bytes in AL32UTF8
insert into hexdump_demo_text values (
	4, 'multibyte',
	'caf' || unistr('\00E9') || ' costs 5' || unistr('\20AC') || ' ' || unistr('\D83D\DE00') || ' end',
	100,
	'CLOB: ' || unistr('\00E9\20AC') || unistr('\D83D\DE00') || ' then ASCII, then' || unistr('\20AC\20AC\20AC\20AC\20AC\20AC')
);

-- a CLOB longer than 32767 characters
declare
	c clob;
begin
	insert into hexdump_demo_text values (3, 'large', 'see c_text', 42, empty_clob())
	returning c_text into c;
	for i in 1 .. 50
	loop
		dbms_lob.writeappend(c, 1000, rpad('Line ' || to_char(i,'FM000') || ' ', 999, 'abcdefghijklmnopqrstuvwxyz') || chr(10));
	end loop;
end;
/

commit;
