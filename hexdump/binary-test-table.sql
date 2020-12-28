
drop table binary_test purge;

create table binary_test (
	name varchar2(32),
	my_blob blob,
	my_raw raw(256),
	my_long_raw long raw
)
/

