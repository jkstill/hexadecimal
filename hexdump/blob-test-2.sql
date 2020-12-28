
var blob_test blob

set serveroutput on format wrapped size unlimited

declare
	b_blob blob;
	c_str clob;
	r_buf raw(256);
begin

	dbms_lob.createtemporary (
		lob_loc	=> b_blob,
		cache		=> true,
		dur		=> dbms_lob.session
	);

	dbms_lob.createtemporary (
		lob_loc	=> c_str,
		cache		=> true,
		dur		=> dbms_lob.session
	);

	r_buf := utl_raw.cast_to_raw(rpad(chr(65),256,chr(65)));

	dbms_lob.writeappend (
		lob_loc	=> b_blob,
		amount	=> dbms_lob.getlength(r_buf),
		buffer	=> r_buf
	);

	-- a global var that must be initialized for hexdump
	hexdump_binary.set_i_blob_idx(1);

	for srec in (select * from table(hexdump_binary.hexdump(b_blob)))
	loop
		dbms_output.put(srec.address || ' ');
		dbms_output.put(srec.data || ' ');
		dbms_output.put_line(srec.text);
	end loop;

	:blob_test := b_blob;
end;
/

select :blob_test from dual;




