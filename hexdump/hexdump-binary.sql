
@@plsql-init

create or replace package hexdump_binary
authid current_user
is

	/*
	$ hexdump -C j.sql
00000000  0a 63 72 65 61 74 65 20  75 73 65 72 20 6a 6b 73  |.create user jks|
00000010  74 69 6c 6c 20 69 64 65  6e 74 69 66 65 64 20 62  |till identifed b|
00000020  79 20 67 72 6f 6b 3b 0a  0a                       |y grok;..|
00000029
	*/

	type t_blob_row is record (
		working_data blob
	);

	type t_blob_cursor is ref cursor return t_blob_row;

	type t_raw_row is record (
		working_data raw(2000)
	);

	type t_raw_cursor is ref cursor return t_raw_row;

	type t_hexdump_row is record (
		address	varchar2(8),
		data		varchar2(48),
		text		varchar2(2048)
	);

	type t_hexdump_tab is table of t_hexdump_row;

	type t_hexdump_cursor is ref cursor return t_hexdump_row;

	type t_hdr_row is record (
		owner_in	varchar2(30) default null,
		tab_name_in varchar2(30) default null,
		col_name_in varchar2(30) default null,
		value_in    varchar2(30) default null
	);

	type t_hdr_tab is table of t_hdr_row;

	function hexdump (blob_in blob ) return t_hexdump_tab pipelined;
	function hexdump (hex_cursor t_blob_cursor) return t_hexdump_tab pipelined;

	function hexdump_raw (hex_cursor t_raw_cursor) return t_hexdump_tab pipelined;

	function dump_hdr (hdr_in t_hdr_row) return t_hexdump_tab pipelined;

	procedure set_i_blob_idx(idx_in pls_integer);

	$if $$develop $then
	function  to_spaced_hex (text_in blob ) return varchar2;
	function safe_to_print (text_in raw) return varchar2;
	$end

end;
/


show errors package hexdump_binary;


create or replace package body hexdump_binary
is

	/*
		this global is the simplest way to keep an address between 
		calls to hexdump(blob) in 32 k chunks
	*/
	i_blob_idx binary_integer;

	procedure set_i_blob_idx(idx_in pls_integer)
	is
	begin
		i_blob_idx := idx_in;
	end;

-- using varchar2 as the length should always be <= 16 clob, <= 32 for blob (hex)
function  to_spaced_hex (text_in blob ) return varchar2
is
	i_text_len integer := 0;
	v_ret_string varchar2(50) := '';
	i_blob_read_sz number := 1;
	r_buf raw(1); -- must match read size
	i_blob_offset number := 1;
begin

	i_text_len := dbms_lob.getlength(text_in);

	--dbms_output.put_line('spaced_hex len: ' || to_char(i_text_len));
	--dbms_output.put_line('text_in: ' || text_in);

	if i_text_len = 0
		or i_text_len is null
	then
		return '';
	end if;

	while true	
	loop
		begin
			dbms_lob.read(
				lob_loc	=> text_in,
				amount	=> i_blob_read_sz,
				offset	=> i_blob_offset,
				buffer	=> r_buf
			);
			i_blob_offset := i_blob_offset + i_blob_read_sz;
		exception
		when no_data_found then
			exit;
		when others then
			raise;
		end;

		v_ret_string := v_ret_string || rawtohex(r_buf) || ' ';
		--dbms_output.put_line('v_ret_str: ' || v_ret_string);

	end loop;

	v_ret_string := rtrim(v_ret_string);

	return v_ret_string;

end;

function safe_to_print (text_in raw) return varchar2
is
	i_text_len integer;
	v_ret_string varchar2(50);
	i_ascii_val integer;
	v_chr varchar2(2);
begin

	i_text_len := utl_raw.length(text_in);
	--dbms_output.put_line('stp i_text_len: ' || i_text_len);
	--return 'stp dummy'; -- testing

	if i_text_len = 0 or i_text_len is null then
		return '|' || rpad('.',16,'.') || '|';
	end if;

	for i in 1 .. i_text_len
	loop

		begin
			v_chr := utl_raw.cast_to_varchar2(utl_raw.substr(text_in,i,1));
			--dbms_output.put_line('safe_print loop - v_chr: ' || to_char(ascii(v_chr)));
			i_ascii_val := ascii(v_chr);
		exception
		when others then
			dbms_output.put_line('stp exception in loop: ' || sqlcode);
			dbms_output.put_line('i value: ' || i);
			dbms_output.put_line('i_text_len: ' || i_text_len);
			dbms_output.put_line('v_chr value: ' || '|' || v_chr || '|');
			raise;
		end;

		-- printable ascii values
		if i_ascii_val between 32 and 126 then
			v_ret_string := v_ret_string || v_chr;
		else
			v_ret_string := v_ret_string || '.';
		end if;

	end loop;

	return '|' || v_ret_string || '|';

exception
when others then
	dbms_output.put_line('stp exception - i_text_len: ' || i_text_len);
	dbms_output.put_line('stp exception - sqlcode: ' || sqlcode);
	-- shows the line number of the error
	dbms_output.put_line ('stp exception - line# : '|| dbms_utility.format_error_backtrace || ' - '||sqlerrm);
	--return 'stp exception';	
	raise;
end;

function dump_hdr (hdr_in t_hdr_row) return t_hexdump_tab pipelined
is

	$if dbms_db_version.version < 18 $then
	r_hexdump_row t_hexdump_row ;
	$else
	r_hexdump_row t_hexdump_row := t_hexdump_row(null,null,null);
	$end

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


function hexdump (blob_in blob) return t_hexdump_tab pipelined is

	i_blob_len integer := 0;
	i_blob_chunksize integer := 16;
	i_blob_chunk blob;

	$if dbms_db_version.version < 18 $then
	r_hexdump_row t_hexdump_row ;
	$else
	r_hexdump_row t_hexdump_row := t_hexdump_row(null,null,null);
	$end

	v_hex_address varchar2(8);
	i_loop_count integer := 1;
	r_text raw(16);
begin

	$if dbms_db_version.version < 18 $then
	r_hexdump_row.address := null;
	r_hexdump_row.data := null;
	r_hexdump_row.text := null;
	$end

	i_blob_len := dbms_lob.getlength(blob_in);
	--dbms_output.put_line('i_blob_len: ' || to_char(i_blob_len));

	if (not i_blob_len > 0) then
		pipe row (r_hexdump_row);
		dbms_output.put_line('early exit hexdump(blob_in)');
		return;
	end if;

	
	while true
	loop
		i_blob_chunk := dbms_lob.substr(blob_in,i_blob_chunksize, i_blob_idx);
		--dbms_output.put_line('hexdump: ' || length(utl_raw.cast_to_varchar2(i_blob_chunk)));

		-- for testing
		--exit when i_loop_count > 10;
		i_loop_count := i_loop_count + 1;

		-- exit loop when 
		if i_blob_idx >= i_blob_len then
			--dbms_output.put_line('exit hexdump(blob_in) due to i_blob_idx');
			exit;
		end if;

		r_hexdump_row.address := lpad(trim(to_char(i_blob_idx-1,'XXXXXXXX')),8,0);
		--dbms_output.put_line('row_address: ' || r_hexdump_row.address);

		r_hexdump_row.data := to_spaced_hex(i_blob_chunk);

		r_hexdump_row.text := 'testing';
		r_text := dbms_lob.substr(i_blob_chunk,i_blob_chunksize,1);
		--dbms_output.put_line('r_text: ' || r_text);
		r_hexdump_row.text := safe_to_print(r_text);

		pipe row (r_hexdump_row);

		i_blob_idx := i_blob_idx + i_blob_chunksize;


	end loop;

	return;

end;


function hexdump (hex_cursor t_blob_cursor) return t_hexdump_tab pipelined is

	$if dbms_db_version.version < 18 $then
	r_hexdump_row t_hexdump_row ;
	r_hdr_row t_hdr_row;
	$else
	r_hexdump_row t_hexdump_row := t_hexdump_row(null,null,null);
	r_hdr_row t_hdr_row := t_hdr_row(null,null,null,null);
	$end

	i_pad_char integer := 88; -- X
	i_blob_read_sz number := 32767;
	r_buf raw(32767); -- must match read size
	i_blob_offset number := 1;
	b_working_blob blob;
	i_convert_warning integer;
	i_src_offset integer := 1;
	i_dest_offset integer := 1;
	--i_lang_context integer := dbms_lob.DEFAULT_LANG_CTX ;
	i_lang_context integer := 0;
begin

	$if dbms_db_version.version < 18 $then
	r_hexdump_row.address := null;
	r_hexdump_row.data := null;
	r_hexdump_row.text := null;

	r_hdr_row.owner_in		:= null;
	r_hdr_row.tab_name_in 	:= null;
	r_hdr_row.col_name_in 	:= null;
	r_hdr_row.value_in    	:= null;
	$end

	loop
		
		fetch hex_cursor into b_working_blob;
		exit when hex_cursor%notfound ;
		--dbms_output.put_line('blob len: ' || dbms_lob.getlength(b_working_blob));

		-- header for each column dumped
		-- setting all to null causes just the header line to print
		for srec in ( select * from  table(dump_hdr(r_hdr_row)))
		loop
			r_hexdump_row.address := srec.address;
			r_hexdump_row.data := srec.data;
			r_hexdump_row.text := srec.text;
			pipe row (r_hexdump_row);
		end loop;


		i_blob_idx := 1;

		while true
		loop
			begin
				dbms_lob.read(
					lob_loc	=> b_working_blob,
					amount	=> i_blob_read_sz,
					offset	=> i_blob_offset,
					buffer	=> r_buf
				);
			exception
			when no_data_found then
				exit;
			when others then
				raise;
			end;

			exit when i_blob_offset = 0;

			i_blob_offset := i_blob_offset + i_blob_read_sz;
			--dbms_output.put_line('r_buf len: ' || utl_raw.length(r_buf));

			for srec in ( select * from  table(hexdump(r_buf)))
			loop
				null;
				r_hexdump_row.address := srec.address;
				r_hexdump_row.data := srec.data;
				r_hexdump_row.text := srec.text;
				pipe row (r_hexdump_row);
			end loop;

		end loop;

	end loop;

	return;


exception
when others then
	dbms_output.put_line('hexdump(blob_in)');
	dbms_output.put_line(dbms_utility.format_call_stack);
	raise;

end;

function hexdump_raw (hex_cursor t_raw_cursor) return t_hexdump_tab pipelined is

	$if dbms_db_version.version < 18 $then
	r_hexdump_row t_hexdump_row ;
	r_hdr_row t_hdr_row;
	$else
	r_hexdump_row t_hexdump_row := t_hexdump_row(null,null,null);
	r_hdr_row t_hdr_row := t_hdr_row(null,null,null,null);
	$end

	i_pad_char integer := 88; -- X
	i_blob_read_sz number := 32767;
	r_buf raw(32767); -- must match read size
	i_blob_offset number := 1;
	r_working_raw raw(2000);
	b_working_raw raw(2000);
	b_working_blob blob;
	i_convert_warning integer;
	i_src_offset integer := 1;
	i_dest_offset integer := 1;
	--i_lang_context integer := dbms_lob.DEFAULT_LANG_CTX ;
	i_lang_context integer := 0;
begin

	$if dbms_db_version.version < 18 $then
	r_hexdump_row.address := null;
	r_hexdump_row.data := null;
	r_hexdump_row.text := null;

	r_hdr_row.owner_in		:= null;
	r_hdr_row.tab_name_in 	:= null;
	r_hdr_row.col_name_in 	:= null;
	r_hdr_row.value_in    	:= null;
	$end

	i_blob_idx := 1;
	loop
		
		fetch hex_cursor into r_working_raw;
		b_working_blob := r_working_raw;

		exit when hex_cursor%notfound ;
		--dbms_output.put_line('blob len: ' || dbms_lob.getlength(b_working_blob));

		-- header for each column dumped
		-- setting all to null causes just the header line to print
		for srec in ( select * from  table(dump_hdr(r_hdr_row)))
		loop
			r_hexdump_row.address := srec.address;
			r_hexdump_row.data := srec.data;
			r_hexdump_row.text := srec.text;
			pipe row (r_hexdump_row);
		end loop;

		for srec in ( select * from  table(hexdump(b_working_blob)))
		loop
			r_hexdump_row.address := srec.address;
			r_hexdump_row.data := srec.data;
			r_hexdump_row.text := srec.text;
			pipe row (r_hexdump_row);
		end loop;

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


show errors package body hexdump_binary;


