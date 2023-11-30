
drop table long_raw_convert purge;

create 
	--global temporary 
	table long_raw_convert( name varchar2(64), lr_to_clob blob)
--on commit preserve rows
/
