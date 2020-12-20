
drop table maxnum;

create table maxnum ( x number);

insert into maxnum values( 9.999999999999999999999999999999999999 * power(10,125));

insert into maxnum values( power(2,128));
insert into maxnum values( power(2,129));

insert into maxnum values( 10 * power(10,125));


