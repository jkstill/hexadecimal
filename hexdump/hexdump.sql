
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

	type t_blob_row is record (
		id integer,
		working_data blob
	);


	type t_hexdump_row is record (
		address	varchar2(8),
		data		varchar2(48),
		text		varchar2(256)
	);

	type t_hexdump_tab is table of t_hexdump_row;

	type t_hexdump_cursor is ref cursor return t_hexdump_row;
	type t_clob_cursor is ref cursor return t_text_row;
	type t_blob_cursor is ref cursor return t_blob_row;

	function hexdump (text_in clob) return t_hexdump_tab pipelined;
	function hexdump (hex_cursor t_clob_cursor) return t_hexdump_tab pipelined;

	function hexdump_blob (blob_in blob ) return t_hexdump_tab pipelined;
	function hexdump_blob (hex_cursor t_blob_cursor) return t_hexdump_tab pipelined;

	function  to_spaced_hex (text_in varchar2 , is_raw boolean default false) return varchar2;

end;
/


show errors package hexdump;



create or replace package body hexdump
is

-- using varchar2 as the length should always be <= 16 clob, <= 32 for blob (hex)
function  to_spaced_hex (text_in varchar2 , is_raw boolean default false) return varchar2
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
		--continue when mod(i,2) = 1;
		if is_raw then
			continue when mod(i,2) = 0;
			--v_ret_string := v_ret_string || substr(text_in,i+1,2) || ' ';
			--dbms_output.put_line('v_ret_str: ' || v_ret_string);
		else
			v_ret_string := v_ret_string || rawtohex(utl_raw.cast_to_raw(substr(text_in,i+1,1))) || ' ';
		end if;
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

function hexdump_blob (blob_in blob) return t_hexdump_tab pipelined is

	-- currently not considering multibyte characters
	b_working_blob blob;
	i_blob_len integer := 0;
	i_blob_idx integer := 0;
	i_blob_chunksize integer := 16;
	i_blob_chunk raw(16);
	r_hexdump_row t_hexdump_row := t_hexdump_row(null,null,null);
	v_hex_address varchar2(8);
begin

	b_working_blob := blob_in;
	i_blob_len := dbms_lob.getlength(b_working_blob);

	if (not i_blob_len > 0) then
		pipe row (r_hexdump_row);
		return;
	end if;

	i_blob_idx := 1;
	
	while true
	loop
		i_blob_chunk := dbms_lob.substr(b_working_blob,i_blob_chunksize, i_blob_idx);

		r_hexdump_row.address := lpad(trim(to_char(i_blob_idx-1,'XXXXXXXX')),8,0);

		r_hexdump_row.data := to_spaced_hex(utl_raw.cast_to_varchar2(i_blob_chunk),true);
		r_hexdump_row.text := safe_to_print(utl_raw.cast_to_varchar2(i_blob_chunk));

		pipe row (r_hexdump_row);

		i_blob_idx := i_blob_idx + i_blob_chunksize;

		-- exit loop when 
		if i_blob_idx >= i_blob_len then
			exit;
		end if;

	end loop;

	return;

end;


--function hexdump (hex_cursor t_hexdump_cursor ) return t_hexdump_tab pipelined is
function hexdump (hex_cursor t_clob_cursor ) return t_hexdump_tab pipelined is
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


function hexdump_blob (hex_cursor t_blob_cursor) return t_hexdump_tab pipelined is
	r_hexdump_row t_hexdump_row := t_hexdump_row(null,null,null);

	b_working_blob blob;
	c_working_text clob;
	i_id integer;
	i_convert_warning integer;
	i_src_offset integer := 1;
	i_dest_offset integer := 1;
	i_lang_context integer := dbms_lob.DEFAULT_LANG_CTX ;
begin
	loop
		
		fetch hex_cursor into i_id, b_working_blob;
		exit when hex_cursor%notfound ;
		dbms_output.put_line('id: ' || i_id);

		DBMS_LOB.CREATETEMPORARY (
			lob_loc	=> c_working_text,
			cache		=> true,
			dur		=> DBMS_LOB.SESSION
		);

		DBMS_LOB.CONVERTTOCLOB(
			dest_lob		=> c_working_text,
			src_blob		=> b_working_blob,
			amount		=> DBMS_LOB.LOBMAXSIZE,
			dest_offset => i_dest_offset,
			src_offset	=> i_src_offset,
			blob_csid	=> dbms_lob.DEFAULT_CSID ,
			lang_context=> i_lang_context,
			warning		=> i_convert_warning
		);

		dbms_output.put_line('blob len: ' || dbms_lob.getlength(b_working_blob));
		dbms_output.put_line('clob len: ' || dbms_lob.getlength(c_working_text));

		--/*
		--for srec in ( select * from  table(hexdump_blob(blob_in => b_working_blob)))
		--for srec in ( select * from  table(hexdump_blob(blob_in => utl_raw.cast_to_raw('this is a BLOB test'))) )
		for srec in ( select * from  table(hexdump(c_working_text)))
		loop
			null;
			r_hexdump_row.address := srec.address;
			r_hexdump_row.data := srec.data;
			r_hexdump_row.text := srec.text;
			pipe row (r_hexdump_row);
		end loop;
		--*/

	end loop;

	return;

exception
when others then
	dbms_output.put_line(dbms_utility.format_call_stack);
	raise;

end;


begin
	null;
exception
when others then
	dbms_output.put_line(dbms_utility.format_call_stack);
	raise;
end;
/


show errors package body hexdump;


