
create or replace package radix
is

	function to_base( p_dec in number, p_base in number ) 
	return varchar2;

	function to_dec (
		p_str in varchar2, 
		p_from_base in number default 16 
	) return number;

	function to_hex( p_dec in number ) return varchar2;
	function to_bin( p_dec in number ) return varchar2;
	function to_oct( p_dec in number ) return varchar2;
	function to_36( p_dec in number ) return varchar2;
	function to_32( p_dec in number ) return varchar2;
	function to_64( p_dec in number ) return varchar2;
	function bitor( x in integer, y in integer) return integer;
	function bitxor( x in integer, y in integer) return integer;
	function num_format(v_num in varchar2, v_num_type in varchar2 ) return varchar2;

	--pragma restrict_references( to_base, wnds, rnds, wnps, rnps );
	--pragma restrict_references( to_dec, wnds, rnds, wnps, rnps );
	--pragma restrict_references( to_hex, wnds, rnds, wnps, rnps );
	--pragma restrict_references( to_bin, wnds, rnds, wnps, rnps );
	--pragma restrict_references( to_oct, wnds, rnds, wnps, rnps );
	--pragma restrict_references( to_36, wnds, rnds, wnps, rnps );
	--pragma restrict_references( to_64, wnds, rnds, wnps, rnps );

	procedure debug_on;
	procedure debug_off;

end radix;
/

show errors

create or replace package body radix
is

	hex_debug boolean;

	procedure debug_on
	is
	begin
		hex_debug := true;
	end;

	procedure debug_off
	is
	begin
		hex_debug := false;
	end;

	procedure p ( p_output varchar2) 
	is
	begin
		dbms_output.put_line(p_output);
	end;
		
	function to_base( p_dec in number, p_base in number ) 
	return varchar2
	is
		l_str	varchar2(255) default NULL;
		l_num	number	default p_dec;
		l_hex	varchar2(64) := '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
	begin
		-- base 64 for Oracle extended rowid format
		if p_base = 64 then
			l_hex := 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
		elsif p_base = 32 then
			-- non-standard base 32 alphabet - used for Oracle SQL_ID
			l_hex := '0123456789abcdfghjkmnpqrstuvwxyz';
		end if;
		
		if hex_debug then
			p('P_DEC : ' || to_char(p_dec));
			p('L_NUM : ' || to_char(l_num));
			p('P_BASE: ' || to_char(p_base));
			p('L_HEX : ' || l_hex);
		end if;

		if ( trunc(p_dec) <> p_dec OR p_dec <  0 ) then
			raise INVALID_NUMBER;
		end if;
		loop
			l_str := substr( l_hex, mod(l_num,p_base)+1, 1 ) || l_str;
			l_num := trunc( l_num/p_base );
			if hex_debug then
				p('L_STR: ' || l_str);
				p('L_NUM: ' || to_char(l_num));
			end if;
			exit when ( l_num = 0 );
		end loop;
		return l_str;
	end to_base;

	function to_dec ( 
		p_str in varchar2, 
		p_from_base in number default 16 ) 
	return number
	is
		l_num   number default 0;
		l_hex   varchar2(64) := '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
	begin
		-- base 64 for Oracle extended rowid format
		if p_from_base = 64 then
			l_hex := 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
		elsif p_from_base = 32 then
			-- non-standard base 32 alphabet - used for Oracle SQL_ID
			l_hex := '0123456789abcdfghjkmnpqrstuvwxyz';
		end if;
		for i in 1 .. length(p_str) loop
			if p_from_base = 64 then
				l_num := l_num * p_from_base + instr(l_hex,substr(p_str,i,1))-1;
			else
				l_num := l_num * p_from_base + instr(l_hex,upper(substr(p_str,i,1)))-1;
			end if;
		end loop;
		return l_num;
	end to_dec;

	-- for bin, oct, hex at this time
	function num_format(v_num in varchar2, v_num_type in varchar2 ) return varchar2
	is
		v_fmt_formatted varchar2(64);
		i_fmt_length pls_integer;
		i_fmt_radix pls_integer;
		v_type_internal varchar2(20);
		v_zero_pad varchar2(100) := rpad('0',100,'0');
		i_substr_len pls_integer;
	begin
		
		v_type_internal := upper(v_num_type);

		case
			when v_type_internal = 'HEX' then i_fmt_radix := 2;
			when v_type_internal = 'OCT' then i_fmt_radix := 3;
			when v_type_internal = 'BIN' then i_fmt_radix := 4;
			else raise_application_error(-20001, 'unrecogized type: ' || v_num_type );
		end case;

		i_fmt_length := length(v_num);

		if mod(i_fmt_length,i_fmt_radix) = 0 then
			i_substr_len := i_fmt_length;
		else
			i_substr_len :=  i_fmt_length + (i_fmt_radix - mod(i_fmt_length,i_fmt_radix));
		end if;

		v_fmt_formatted := substr(v_zero_pad || v_num,i_substr_len*-1);

		if hex_debug then
			p('i_substr_len: ' || to_char(i_substr_len));
			p('-i_substr_len: ' || to_char(-1*i_substr_len));
		end if;

		return v_fmt_formatted;

	end num_format;

	function to_hex( p_dec in number ) return varchar2
	is
	begin
		return num_format(to_base( p_dec, 16 ),'HEX');
	end to_hex;

	function to_bin( p_dec in number ) return varchar2
	is
	begin
		return  num_format(to_base( p_dec, 2 ),'BIN');
	end to_bin;

	function to_oct( p_dec in number ) return varchar2
	is
	begin
		return num_format(to_base( p_dec, 8 ),'OCT');
	end to_oct;

	function to_36( p_dec in number ) return varchar2
	is
	begin
		return to_base( p_dec, 36 );
	end to_36;

	function to_32( p_dec in number ) return varchar2
	is
	begin
		return to_base( p_dec, 32 );
	end to_32;

	function to_64( p_dec in number ) return varchar2
	is
	begin
		return to_base( p_dec, 64 );
	end to_64;

	function bitor( x in integer, y in integer) return integer
	is
	begin
		return (x + y) - bitand(x,y);
	end bitor;

	function bitxor( x in integer, y in integer) return integer
	is
	begin
		return (x + y) - ( bitand(x, y) * 2 );
	end bitxor;


begin
	hex_debug := false;
end;
/


show errors

