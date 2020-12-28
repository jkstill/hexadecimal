

@@plsql-init

create or replace package hexdump
authid current_user -- may want to use current_user
is

	/*
	$ hexdump -C j.sql
00000000  0a 63 72 65 61 74 65 20  75 73 65 72 20 6a 6b 73  |.create user jks|
00000010  74 69 6c 6c 20 69 64 65  6e 74 69 66 65 64 20 62  |till identifed b|
00000020  79 20 67 72 6f 6b 3b 0a  0a                       |y grok;..|
00000029
	*/

	type t_clob_row is record (
		working_text clob
	);

	type t_clob_cursor is ref cursor return t_clob_row;

	type t_long_row is record (
		working_text long
	);

	type t_long_cursor is ref cursor return t_long_row;

	type t_hexdump_row is record (
		address	varchar2(8),
		data		varchar2(48),
		text		varchar2(50)
	);

	type t_hexdump_tab is table of t_hexdump_row;

	type t_hdr_row is record (
		owner_in	varchar2(30) default null,
		tab_name_in varchar2(30) default null,
		col_name_in varchar2(30) default null,
		value_in    varchar2(30) default null
	);

	type t_hdr_tab is table of t_hdr_row;

	function hexdump (text_in clob) return t_hexdump_tab pipelined;
	function hexdump (hex_cursor t_clob_cursor) return t_hexdump_tab pipelined;

	function hexdump_long (
		tab_name_in varchar2,
		tab_owner_in varchar2 default null,
		tab_column_in varchar2,
		where_clause_in varchar2, -- include the entire clause - correct quoting may be a challenge
		where_bind_val sys.anydata default null
	) return t_hexdump_tab pipelined;

	function dump_hdr (hdr_in t_hdr_row) return t_hexdump_tab pipelined;

	procedure show_sql_enable;
	procedure show_sql_disable;
	function show_sql return boolean;

	$if $$develop $then
	function  to_spaced_hex (text_in varchar2) return varchar2;
	$end

end;
/


show errors package hexdump;



create or replace package body hexdump
is

	b_show_sql boolean := FALSE;

procedure show_sql_enable
is
begin
	b_show_sql := TRUE;
end;

procedure show_sql_disable
is
begin
	b_show_sql := FALSE;
end;

function show_sql return boolean
is
begin
	return b_show_sql;
end;

-- using varchar2 as the length should always be <= 16 clob, <= 32 for blob (hex)
function  to_spaced_hex (text_in varchar2) return varchar2
is
	i_text_len integer := 0;
	--v_ret_string varchar2(48) := '';
	v_ret_string varchar2(256) := '';
begin

	i_text_len := length(text_in);

	--dbms_output.put_line('spaced_hex len: ' || to_char(i_text_len));
	--dbms_output.put_line('text_in: ' || text_in);

	if i_text_len = 0
		or i_text_len is null
	then
		return '';
	end if;

	for i in 0 .. i_text_len
	loop
		exit when i >= i_text_len;
		v_ret_string := v_ret_string || rawtohex(utl_raw.cast_to_raw(substr(text_in,i+1,1))) || ' ';
	end loop;

	v_ret_string := rtrim(v_ret_string);

	return v_ret_string;

end;

function safe_to_print (text_in varchar2) return varchar2
is
	i_text_len integer;
	v_ret_string varchar2(256);
	i_ascii_val integer;
	v_chr varchar2(1);
begin
	i_text_len := length(text_in);

	if i_text_len = 0 then
		return '|' || rpad('.',16,'.') || '|';
	end if;

	for i in 1 .. i_text_len
	loop
		v_chr := substr(text_in,i,1);
		i_ascii_val := ascii(v_chr);
		if i_ascii_val between 32 and 122 then
			v_ret_string := v_ret_string || v_chr;
		else
			v_ret_string := v_ret_string || '.';
		end if;
	end loop;

	return '|' || v_ret_string || '|';
end;

function dump_hdr (hdr_in t_hdr_row) return t_hexdump_tab pipelined
is
	r_hexdump_row t_hexdump_row := t_hexdump_row(null,null,null);
begin
	-- header per LONG column
	r_hexdump_row.address := rpad('=',8,'=');
	r_hexdump_row.data := rpad('=',48,'=');
	r_hexdump_row.text := rpad('=',18,'=');
	pipe row (r_hexdump_row);

	if not (
		hdr_in.owner_in is null
		and hdr_in.tab_name_in is null
		and hdr_in.col_name_in is null
		and hdr_in.value_in is null
	) then

		r_hexdump_row.address := 'SCHEMA:';
		r_hexdump_row.data := substr(nvl(hdr_in.owner_in,user),1,48);
		r_hexdump_row.text := null;
		pipe row (r_hexdump_row);

		r_hexdump_row.address := 'TABLE:';
		r_hexdump_row.data := substr(hdr_in.tab_name_in,1,48);
		r_hexdump_row.text := null;
		pipe row (r_hexdump_row);

		r_hexdump_row.address := 'COLUMN:';
		r_hexdump_row.data := substr(hdr_in.col_name_in,1,48);
		r_hexdump_row.text := null;
		pipe row (r_hexdump_row);

		r_hexdump_row.address := 'SEARCH:';
		r_hexdump_row.data := substr(hdr_in.value_in,1,48);
		r_hexdump_row.text := null;
		pipe row (r_hexdump_row);

		r_hexdump_row.address := rpad('=',8,'=');
		r_hexdump_row.data := rpad('=',48,'=');
		r_hexdump_row.text := rpad('=',18,'=');
		pipe row (r_hexdump_row);

	end if;

	return;

end;


function hexdump (text_in clob) return t_hexdump_tab pipelined is

	-- currently not considering multibyte characters
	c_working_text clob;
	i_text_len integer := 0;
	i_text_idx integer := 0;
	i_text_chunksize integer := 16;
	i_text_chunk varchar2(16);
	r_hexdump_row t_hexdump_row := t_hexdump_row(null,null,null);
	v_hex_address varchar2(8);
begin

	c_working_text := text_in;
	i_text_len := dbms_lob.getlength(c_working_text);

	if (not i_text_len > 0) then
		pipe row (r_hexdump_row);
		return;
	end if;

	i_text_idx := 1;
	
	while true
	loop
		i_text_chunk := dbms_lob.substr(c_working_text,i_text_chunksize, i_text_idx);

		r_hexdump_row.address := lpad(trim(to_char(i_text_idx-1,'XXXXXXXX')),8,0);

		r_hexdump_row.data := to_spaced_hex(i_text_chunk);
		r_hexdump_row.text := safe_to_print(i_text_chunk);

		pipe row (r_hexdump_row);

		i_text_idx := i_text_idx + i_text_chunksize;

		-- exit loop when 
		if i_text_idx >= i_text_len then
			exit;
		end if;

	end loop;

	return;

end;


function hexdump (hex_cursor t_clob_cursor ) return t_hexdump_tab pipelined is
	r_hexdump_row t_hexdump_row := t_hexdump_row(null,null,null);

	c_working_text clob;
	r_hdr_row t_hdr_row := t_hdr_row(null,null,null,null);
begin

	loop
		
		fetch hex_cursor into c_working_text;
		exit when hex_cursor%notfound ;

		-- header for each column dumped
		-- setting all to null causes just the header line to print

		for srec in ( select * from  table(dump_hdr(r_hdr_row)))
		loop
			r_hexdump_row.address := srec.address;
			r_hexdump_row.data := srec.data;
			r_hexdump_row.text := srec.text;
			pipe row (r_hexdump_row);
		end loop;

	
		for srec in ( select * from  table(hexdump(c_working_text)))
		loop
			r_hexdump_row.address := srec.address;
			r_hexdump_row.data := srec.data;
			r_hexdump_row.text := srec.text;
			pipe row (r_hexdump_row);
		end loop;


	end loop;

	return;

end;

/*
  Oracle's support for LONG and LONG raw data types in PL/SQL is very sparse, in fact, nearly non-existent
  ( I would not mind being proved wrong on this point - please provide working code)

  A LONG cannot be passed in a cursor to a pipelined function.

  This is the result of attempting to do so:

  SQL# l
  1  SELECT * FROM  TABLE(hexdump.hexdump_long(cursor(
  2  	select text from dba_views where text is not null and rownum < 2
  3* )))
SQL# /
	select text from dba_views where text is not null and rownum < 2
	       *
ERROR at line 2:
ORA-00997: illegal use of LONG datatype

So for LONG data types, it will be necessary to pass the column name, the table name, and criteria for the where clause

In fact, just pass the WHERE clause in its entirety

I did consider using a VARRAY to pass WHERE clause values, so as to make this more flexible.

Doing so would make it difficult to use from a SQL statement.

This will cause some extra hard parsing, but HEXDUMP is a troubleshooting and examination tool,
and so should not be called all that often

*/

/*
-- using a cursor in this manner cannot work with the LONG data type
--function hexdump_long (hex_cursor t_long_cursor) return t_hexdump_tab pipelined

--===================================================--
--== hexdump_long
--== must be called one bind variable
--== 
--==   tab_owner_in => 'SYS',
--==   tab_name_in => 'DBA_VIEWS', 
--==   tab_column_in => 'TEXT', 
--==   where_clause_in => 'where text is not null and rownum < :b',
--==   where_bind_val => SYS.ANYDATA.convertNumber(2)
--==   
--==   tab_owner_in will default to null
--===================================================--

example:

SELECT * FROM  
TABLE(
	hexdump.hexdump_long(
		tab_owner_in => 'SYS',
		tab_name_in => 'DBA_VIEWS', 
		tab_column_in => 'TEXT', 
		where_clause_in => 'where text is not null and rownum < :b',
		where_bind_val => SYS.ANYDATA.convertNumber(2)
	)
)

--===================================================--
*/


function hexdump_long (
	tab_name_in varchar2,
	tab_owner_in varchar2 default null,
	tab_column_in varchar2,
	where_clause_in varchar2, -- include the entire clause - correct quoting may be a challenge
	where_bind_val sys.anydata default null
) return t_hexdump_tab pipelined
is
	-- the PIPE ROW data
	r_hexdump_row t_hexdump_row := t_hexdump_row(null,null,null);
	c_working_text clob;
	i_plen  integer := 16384;
	i_rsiz  integer := 16384;
	i_offset	 integer := 0; -- LONG starts at Zero, not One
	v_piece varchar2(16384);
	i_rows  integer;
	csr_id integer;
	v_sql clob;
	v_valid_text varchar2(128);

	-- for bind values
	n_bind_val number;
	v_bind_val varchar2(128);
	d_bind_val date;
	t_bind_val timestamp;
	v_content varchar2(64);

	v_tab_name varchar2(30);
	v_obj_display_name varchar2(42);
	v_print_val varchar2(18);
	tab_hdr_tab t_hdr_tab;
	r_hdr_row t_hdr_row := t_hdr_row(null,null,null,null);

begin

/*

Sections of this function:

- Sanitize inputs
- Build the SQL statement
- Parse the SQL statement
- Determine type of anydata bind that was passed
- Bind the value to the cursor
- Execute and fetch rows
- Pipe Row the output

*/

	-- sanitize SQL as best we can
	-- Pull requests welcome for improvements here.
	declare

		e_invalid_schema exception;
		pragma exception_init(e_invalid_schema, -44001);

		e_invalid_object exception;
		pragma exception_init(e_invalid_object, -44002);

		e_invalid_where_clause exception;
		pragma exception_init(e_invalid_where_clause,-20001);

	-- validate owner and object_name
	begin

		if tab_owner_in is not null then
			-- raises an error on failure
			v_valid_text := dbms_assert.schema_name (tab_owner_in);
		end if;

		-- raises error on failure;
		v_tab_name := dbms_assert.sql_object_name(tab_name_in);

		-- no ';' allowed in where clause
		if instr(where_clause_in,';') > 0 then
			raise e_invalid_where_clause;
		end if;

	exception
	when e_invalid_schema then
		dbms_output.put_line('hexdump.hexdump_long: ' || 'invalid schema name passed - ' || dbms_assert.enquote_name(tab_owner_in));
		raise;
	when e_invalid_object then
		dbms_output.put_line('hexdump.hexdump_long: ' || 'invalid object name passed - ' || v_tab_name);
		raise;
	when e_invalid_where_clause then
		dbms_output.put_line('The ";" character not allowed in WHERE clause');
		raise;
	when others then
		raise;
	end; -- end of validation


	-- build the SQL statement
	-- consider breaking up the WHERE further in to passed in parameters
	-- that can more easily be checked to minimize the change of sql injection
	v_sql := 'select ' || dbms_assert.enquote_name(tab_column_in) || ' from ' 
		|| case when tab_owner_in is null 
				then '' 
			else dbms_assert.enquote_name(tab_owner_in) || '.' 
		end 
		|| v_tab_name
		|| ' ' || where_clause_in;

	csr_id := dbms_sql.open_cursor;

	dbms_sql.parse(csr_id, v_sql,DBMS_SQL.NATIVE);

	dbms_sql.define_column_long(csr_id, 1);

	-- get the bind value from anydata to whatever is required
	v_content := SYS.ANYDATA.getTypeName(where_bind_val);

	v_print_val := 'NA';
	if v_content = 'SYS.VARCHAR2' then
		v_bind_val := sys.anydata.accessVarchar2(where_bind_val);
		v_print_val := substr(v_bind_val,1,18);
		--dbms_output.put_line('bind varchar2: ' || v_bind_val);
		dbms_sql.bind_variable(csr_id, ':b', v_bind_val);
	elsif v_content =  'SYS.NUMBER' then
		n_bind_val := sys.anydata.accessNumber(where_bind_val);
		v_print_val := substr(to_char(v_bind_val),1,18);
		--dbms_output.put_line('bind number: ' || to_char(n_bind_val));
		--dbms_output.put_line('v_sql: ' || v_sql);
		dbms_sql.bind_variable(csr_id, ':b', n_bind_val);
	else
		dbms_output.put_line('bind content not found!');
		raise_application_error(-20000,'Bind Value Not Found');
	end if;	

	/*
	-- a test to send the query back to caller
	for srec in ( select * from  table(hexdump(v_sql)))
	loop
		r_hexdump_row.address := srec.address;
		r_hexdump_row.data := srec.data;
		r_hexdump_row.text := srec.text;
		pipe row (r_hexdump_row);
	end loop;

	dbms_output.put_line('v_content: ' || v_content);
	dbms_output.put_line('v_sql: ' || v_sql);
	*/
	if show_sql then
		dbms_output.put_line('v_sql: ' || v_sql);
	end if;

	--v_obj_display_name := v_tab_name || '.' || substr(tab_column_in,1,10);
	v_obj_display_name := tab_owner_in || '.' || v_tab_name ;

	i_rows := dbms_sql.execute(csr_id); 
	loop -- [ fetch rows

		i_offset := 0;
		c_working_text := empty_clob();

		i_rows := dbms_sql.fetch_rows(csr_id); 
		exit when i_rows < 1;

		-- header for each LONG column
		r_hdr_row.owner_in := substr(tab_owner_in,1,30);
		r_hdr_row.tab_name_in := substr(tab_name_in,1,30);
		r_hdr_row.col_name_in := substr(tab_column_in,1,30);
		r_hdr_row.value_in := v_print_val;

		--dbms_output.put_line('v_print_val: ' || v_print_val);

		for srec in ( select * from  table(dump_hdr(r_hdr_row)))
		loop
			r_hexdump_row.address := srec.address;
			r_hexdump_row.data := srec.data;
			r_hexdump_row.text := srec.text;
			pipe row (r_hexdump_row);
		end loop;

		--dbms_output.put_line('i_rows:' || r_hexdump_row.data );

		loop -- [ build the CLOB

			DBMS_SQL.COLUMN_VALUE_LONG(
				c					=> csr_id,
				position 		=> 1,
				length			=> i_rsiz,
				offset			=> i_offset,
				value				=> v_piece,
				value_length	=> i_plen
			);

			c_working_text := c_working_text || v_piece;
			i_offset := i_offset + i_plen;

			exit when i_plen < i_rsiz;

		end loop; -- ] build the CLOB

		--dbms_output.put_line('text: ' || c_working_text);

		for srec in ( select * from  table(hexdump(c_working_text)))
		loop -- [ pipe row
			r_hexdump_row.address := srec.address;
			r_hexdump_row.data := srec.data;
			r_hexdump_row.text := srec.text;
			pipe row (r_hexdump_row);
		end loop; -- ] pipe row

	end loop; -- ] loop through rows

	dbms_sql.close_cursor(csr_id); 

	return;
end;

begin
	null;
exception
when others then
	dbms_output.put_line(dbms_utility.format_call_stack);
	dbms_output.put_line ('hexdump_long - line# : '|| dbms_utility.format_error_backtrace || ' - '||sqlerrm);
	raise;
end;
/


show errors package body hexdump;


