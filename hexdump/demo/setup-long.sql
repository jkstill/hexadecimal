-- Test data for hexdump.hexdump_long: LONG
create table hexdump_demo_long (
	id number primary key,
	name varchar2(30),
	text long
);

insert into hexdump_demo_long values (1, 'short', 'A short LONG value.' || chr(10) || 'Second line.');

insert into hexdump_demo_long values (2, 'large', rpad('0123456789ABCDEF', 4000, '0123456789ABCDEF'));

commit;
