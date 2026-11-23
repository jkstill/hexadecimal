-- usage: @lrbug-run LRBUG_R (RAW control) or @lrbug-run LRBUG_T (LONG RAW)
set serveroutput on feedback off verify off
prompt ==== &1: one call, open and read all rows
select lrbug_all('&1') total_bytes from dual;
prompt ==== &1: call 1, executeQuery only
exec lrbug_open('&1')
prompt ==== &1: call 2, first row
exec dbms_output.put_line('row bytes: '||lrbug_next)
prompt ==== &1: call 3, second row
exec dbms_output.put_line('row bytes: '||lrbug_next)
prompt ==== &1: call 4, third row
exec dbms_output.put_line('row bytes: '||lrbug_next)
prompt ==== &1: call 5, end of data
exec dbms_output.put_line('row bytes: '||lrbug_next)
select 'session alive' status from dual;
