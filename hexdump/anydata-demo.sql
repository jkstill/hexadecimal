declare
procedure p ( p_in in sys.anydata ) is
	v_type_name varchar2(32);
begin
	v_type_name := SYS.ANYDATA.getTypeName(p_in);
	dbms_output.put_line(v_type_name);
end;
begin
	p(p_in =>  SYS.ANYDATA.convertVarchar2('testing'));
end;
/
