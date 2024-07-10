
-- test-02.sql
-- make sure the formatting for bin,oct,hex is working correctly
-- 2 million tests = 1M below 1G and 1M above 1G
-- takes about 30 seconds on my 2 vcpu vbox machine
-- takes 19 seconds on latest 20 core i7 (2024)

declare
	i_begin pls_integer := power(2,30) - power(2,20);
	i_max pls_integer := power(2,30) +  power(2,20);
	i pls_integer;
	v_hex varchar2(64);
	v_oct varchar2(128);
	v_bin varchar2(256);

	b_verbose boolean := false;

	procedure pl(p_in varchar2)
	is
	begin
		dbms_output.put_line(p_in);
	end;

begin
	i := i_begin;

	loop
		
		v_hex := radix.to_hex(i);
		v_oct := radix.to_oct(i);
		v_bin := radix.to_bin(i);

		if b_verbose then
			pl('v_hex: ' || v_hex);
			pl('v_oct: ' || v_oct);
			pl('v_bin: ' || v_bin);
		end if;

		if mod(length(v_hex),2) != 0 then
			raise_application_error(-21001,'to_hex length error: ' || length(v_hex));
		end if;

		if mod(length(v_oct),3) != 0 then
			raise_application_error(-21002,'to_oct length error: ' || length(v_oct));
		end if;

		if mod(length(v_bin),4) != 0 then
			raise_application_error(-21003,'to_bin length error: ' || length(v_bin));
		end if;

		i := i + 1;
		exit when i > i_max;

	end loop;
end;
/
