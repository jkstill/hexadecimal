
create or replace package hexdump_blob
is

	/*
	$ hexdump -C j.sql
00000000  
0a 63 72 65 61 74 65 20  75 73 65 72 20 6a 6b 73  |.create user jks|
00000010  74 69 6c 6c 20 69 64 65  6e 74 69 66 65 64 20 62  |till identifed b|
00000020  79 20 67 72 6f 6b 3b 0a  0a                       |y grok;..|
00000029
	*/

	type t_blob_row is record (
		working_data blob
	);


	type t_hexdump_row is record (
		address	varchar2(8),
		data		varchar2(48),
		text		varchar2(2048)
	);

	type t_hexdump_tab is table of t_hexdump_row;

	type t_hexdump_cursor is ref cursor return t_hexdump_row;
	type t_blob_cursor is ref cursor return t_blob_row;

	function hexdump (blob_in blob ) return t_hexdump_tab pipelined;
	function hexdump (hex_cursor t_blob_cursor) return t_hexdump_tab pipelined;

	function  to_spaced_hex (text_in blob ) return varchar2;
	function safe_to_print (text_in raw) return varchar2;

end;
/


show errors package hexdump_blob;



create or replace package body hexdump_blob
is

	/*
		this global is the simplest way to keep an address between 
		calls to hexdump(blob) in 32 k chunks
	*/
	i_blob_idx binary_integer;

-- using varchar2 as the length should always be <= 16 clob, <= 32 for blob (hex)
function  to_spaced_hex (text_in blob ) return varchar2
is
	i_text_len integer := 0;
	--v_ret_string varchar2(48) := '';
	v_ret_string varchar2(256) := '';
	i_blob_read_sz number := 1;
	r_buf raw(1); -- must match read size
	i_blob_offset number := 1;
	b_working_blob blob;
begin

	--return 'tsh dummy'; -- testing

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
	--dbms_output.put_line('stp text: |' || text_in || '|');
	--return 'stp dummy'; -- testing

	if i_text_len = 0 or i_text_len is null then
		return '|' || rpad('.',16,'.') || '|';
	end if;

	--return 'stp dummy'; -- testing

	for i in 1 .. i_text_len
	loop
		continue when mod(i,2) = 0;
		v_chr := substr(text_in,i,2);
		--i_ascii_val := ascii(v_chr);
		i_ascii_val := to_number(v_chr,'XX');
		--dbms_output.put_line('v_chr: ' || v_chr);
		--dbms_output.put_line('i_ascii_val: ' || to_char(i_ascii_val));
		if i_ascii_val between 32 and 122 then
			v_ret_string := v_ret_string || chr(i_ascii_val);
		else
			v_ret_string := v_ret_string || '.';
		end if;
	end loop;

	return '|' || v_ret_string || '|';
exception
when others then
	dbms_output.put_line('stp exception - i_text_len: ' || i_text_len);
	raise;
end;


function hexdump (blob_in blob) return t_hexdump_tab pipelined is

	b_working_blob blob;
	i_blob_len integer := 0;
	i_blob_chunksize integer := 16;
	i_blob_chunk blob;
	r_hexdump_row t_hexdump_row := t_hexdump_row(null,null,null);
	v_hex_address varchar2(8);
begin

	--b_working_blob := blob_in;
	i_blob_len := dbms_lob.getlength(blob_in);

	if (not i_blob_len > 0) then
		pipe row (r_hexdump_row);
		return;
	end if;

	
	while true
	loop
		i_blob_chunk := dbms_lob.substr(blob_in,i_blob_chunksize, i_blob_idx);
		--dbms_output.put_line('hexdump: ' || length(utl_raw.cast_to_varchar2(i_blob_chunk)));

		-- exit loop when 
		if i_blob_idx >= i_blob_len then
			exit;
		end if;

		r_hexdump_row.address := lpad(trim(to_char(i_blob_idx-1,'XXXXXXXX')),8,0);

		--r_hexdump_row.data := to_spaced_hex(utl_raw.cast_to_varchar2(i_blob_chunk),true);
		r_hexdump_row.data := to_spaced_hex(i_blob_chunk);

		--r_hexdump_row.text := 'testing';
		r_hexdump_row.text := safe_to_print(i_blob_chunk);

		pipe row (r_hexdump_row);

		i_blob_idx := i_blob_idx + i_blob_chunksize;


	end loop;

	return;

end;


function hexdump (hex_cursor t_blob_cursor) return t_hexdump_tab pipelined is
	r_hexdump_row t_hexdump_row := t_hexdump_row(null,null,null);

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

	loop
		
		fetch hex_cursor into b_working_blob;
		exit when hex_cursor%notfound ;
		--dbms_output.put_line('blob len: ' || dbms_lob.getlength(b_working_blob));

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

			--exit;

		end loop;
		--*/

	end loop;

	--dbms_lob.filecloseall;

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


show errors package body hexdump_blob;


