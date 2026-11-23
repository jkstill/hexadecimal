insert into long_raw_convert
select 'LRTEST', to_lob(my_long_raw)
from binary_test
where name = 'VERY LONG RAW'
/
