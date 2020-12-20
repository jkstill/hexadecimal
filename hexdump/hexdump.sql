
create or replace package hexdump
is

	/*
	$ hexdump -C j.sql
00000000  
0a 63 72 65 61 74 65 20  75 73 65 72 20 6a 6b 73  |.create user jks|
00000010  74 69 6c 6c 20 69 64 65  6e 74 69 66 65 64 20 62  |till identifed b|
00000020  79 20 67 72 6f 6b 3b 0a  0a                       |y grok;..|
00000029
	*/

	type t_text_row is record (
		working_text clob
	);

	type t_hexdump_row is record (
		address	varchar2(8),
		data		varchar2(48),
		text		varchar2(18)
	);

	type t_hexdump_tab is table of t_hexdump_row;

	type t_hexdump_cursor is ref cursor return t_hexdump_row;
	type t_text_cursor is ref cursor return t_text_row;

	function hexdump (text_in clob) return t_hexdump_tab pipelined;
	function hexdump (hex_cursor t_text_cursor) return t_hexdump_tab pipelined;

	function  to_spaced_hex (text_in varchar2) return varchar2;

end;
/


show errors package hexdump;



create or replace package body hexdump
is

-- using varchar2 as the length should always be <= 16
function  to_spaced_hex (text_in varchar2) return varchar2
is
	i_text_len integer := 0;
	v_ret_string varchar2(48) := '';
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
		--continue when mod(i,2) = 1;
		v_ret_string := v_ret_string || rawtohex(utl_raw.cast_to_raw(substr(text_in,i+1,1))) || ' ';
	end loop;

	v_ret_string := rtrim(v_ret_string);

	return v_ret_string;

end;

function safe_to_print (text_in varchar2) return varchar2
is
	i_text_len integer;
	v_ret_string varchar2(18);
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

--function hexdump (hex_cursor t_hexdump_cursor ) return t_hexdump_tab pipelined is
function hexdump (hex_cursor t_text_cursor ) return t_hexdump_tab pipelined is
	r_hexdump_row t_hexdump_row := t_hexdump_row(null,null,null);

	c_working_text clob;
begin

	loop
		
		fetch hex_cursor into c_working_text;
		exit when hex_cursor%notfound ;
	
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


begin
	null;
end;
/


show errors package body hexdump;


