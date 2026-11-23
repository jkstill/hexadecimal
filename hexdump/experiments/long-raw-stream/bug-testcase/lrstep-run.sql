-- Runs up to four database calls in the current session, one lrstep() call each.
-- usage: @lrstep-run "o n" "R" "" ""
-- Connect a fresh session for every case. Unused arguments must be passed as "".
set heading off feedback off verify off pagesize 0 linesize 100
select lrstep('&1') from dual;
select lrstep('&2') from dual where '&2' is not null;
select lrstep('&3') from dual where '&3' is not null;
select lrstep('&4') from dual where '&4' is not null;
select 'SESSION ALIVE' from dual;
