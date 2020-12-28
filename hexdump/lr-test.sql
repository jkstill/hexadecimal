
set serveroutput on format wrapped size unlimited

declare

	lr_data long raw;
	lr_work long raw;
	lr_len pls_integer;
	lr_idx integer;
	lr_failsafe integer := 0;
	lr_chunk raw(16);

function sanitize ( data_in raw ) return varchar2
is
	v_clean_str varchar2(32) := '';
	v_chr varchar2(2);
	v_int integer;
begin

	for i in 1 .. length(data_in)
	loop
		continue when mod(i,2) = 0;
		v_chr := substr(data_in,i,2);
		v_int := to_number(v_chr,'XX');

		if v_int between 32 and 126 then
			--dbms_output.put_line('v_int: ' || v_int);
			--dbms_output.put_line('v_chr: ' || v_chr);
			v_clean_str := v_clean_str || chr(v_int);
		else
			v_clean_str := v_clean_str || '.';
		end if;
	end loop;

	return v_clean_str;

end;


begin
	null;

	-- works for the 'LONG RAW' row, which is a 65k
	-- the 'VERY LONG RAW' row has a 1.2M LONG RAW, and this does not work
	select my_long_raw into lr_data from binary_test where name = 'VERY LONG RAW';

	for i in 1 .. 2000
	loop
		begin
			lr_work := lr_work || lr_data;
		exception
		when others then
			dbms_output.put_line('lr_work len: ' || to_char(length(lr_work)));
			exit;
		end;
	end loop;

	lr_idx := 1;

	while true
	loop
		lr_chunk := substr(lr_work,lr_idx,32);
		lr_len := length(lr_chunk);

		exit when lr_len is null;
		dbms_output.put(lr_chunk || ' ');
		dbms_output.put_line(sanitize(lr_chunk));

		--dbms_output.put_line ('lr_len: ' || to_char(lr_len));

		lr_idx := lr_idx + 16;

		lr_failsafe := lr_failsafe + 1;

		--exit when lr_failsafe > 30;
		
	end loop;



end;
/


