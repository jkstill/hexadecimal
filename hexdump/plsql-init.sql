
set feed off

-- setup plscope
alter session set plscope_settings='IDENTIFIERS:ALL';

alter session set plsql_optimize_level=2;

alter session set plsql_warnings = 'ENABLE:SEVERE';
--alter session set plsql_warnings = 'ENABLE:ALL';

-- may not currently be using debug
alter session set plsql_ccflags = 'debug:true, develop:true, mode11g:false';

-- INTERPRETED (default) or NATIVE
alter session set PLSQL_CODE_TYPE =  INTERPRETED ;

set feed on

set serveroutput on size unlimited

begin

	$if $$develop $then
		dbms_output.put_line('$$develop: TRUE');
	$else
		dbms_output.put_line('$$develop: FALSE');
	$end

	$if $$debug $then
		dbms_output.put_line('$$debug: TRUE');
	$else
		dbms_output.put_line('$$debug: FALSE');
	$end

	$if $$mode11g $then
		dbms_output.put_line('$$mode11g: TRUE');
	$else
		dbms_output.put_line('$$mode11g: FALSE');
	$end

end;
/



