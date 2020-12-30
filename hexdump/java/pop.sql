insert into stocktable
with symbols as (
	select dbms_random.string(1,4) name from dual
	connect by level <= 10
)
select s.name
	, dbms_random.value(1,10)
	, dbms_random.value(1,10)
from symbols s
connect by level <= 2
/
