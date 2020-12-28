
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

	lr_idx := 1;

	--select my_long_raw into lr_data from binary_test where name = 'VERY LONG RAW';

	for rec in (select my_long_raw from binary_test where name = 'VERY LONG RAW')
	loop

		null;

		/*
		lr_chunk := UTL_RAW.CAST_TO_VARCHAR2(substr(rec.my_long_raw,lr_idx,32));

		lr_len := length(lr_chunk);

		exit when lr_len is null;
		dbms_output.put(lr_chunk || ' ');
		dbms_output.put_line(sanitize(lr_chunk));

		--dbms_output.put_line ('lr_len: ' || to_char(lr_len));

		lr_idx := lr_idx + 16;

		lr_failsafe := lr_failsafe + 1;

		--exit when lr_failsafe > 30;
		*/
		
	end loop;



end;
/


