
drop table long_test purge;

create table long_test( id number, name varchar2(10), text long);

--insert into long_test values(1, 'jkstill',
		--rpad('=',32735,'=')
--);

commit;




