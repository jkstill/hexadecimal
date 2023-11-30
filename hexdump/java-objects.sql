select object_name
	,object_type
	, status
	, to_char(created,'mm/dd/yyyy hh24:mi:ss') created
	, to_char(last_ddl_time,'mm/dd/yyyy hh24:mi:ss') last_ddl_time
from user_objects
where object_name like '%LongRaw%'
order by object_name
/
