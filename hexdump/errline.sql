

col line format  9999
col text format a150

set linesize 200 trimspool on
set pagesize 1000

select 
	case line
	when &1 then '==>'
	else to_char(line,'0999')
	end linenum
	, text
from dba_source
where owner = 'JKSTILL'
and type = 'PACKAGE BODY'
and name = 'HEXDUMP'
and line between &1 -5 and &1 + 5
order by name,type,line
/
