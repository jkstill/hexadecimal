-- Creates all demo objects.
-- The packages must be installed first: hexdump.sql, hexdump-binary.sql and hexdump-long-raw.sql
@@setup-text
@@setup-long
@@setup-binary
@@setup-long-raw

col object_name format a30
select object_type, object_name, status
from user_objects
where object_name like 'HEXDUMP_DEMO%' or object_name = 'HexdumpDemoLoad'
order by object_type, object_name;
