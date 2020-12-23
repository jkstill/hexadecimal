
col line format  9999
col text format a150

set linesize 200 trimpool on
set pagesize 1000

select line, text
from dba_source
where owner = 'JKSTILL'
and type = 'PACKAGE BODY'
and name = 'HEXDUMP_BLOB'
order by name,type,line
/
