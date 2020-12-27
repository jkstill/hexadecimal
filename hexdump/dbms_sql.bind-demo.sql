declare
procedure p ( p_in in sys.anydata ) is
	v_type_name varchar2(32);
	v_sql clob;
	i_col_cnt integer;
	rec_tab DBMS_SQL.DESC_TAB;
	v_bind_val varchar2(128);
	i_csr integer;
	i_rows integer;
	v_col_name varchar2(32);
begin
	v_sql := 'select dummy from dual where dummy = :r';
	v_type_name := SYS.ANYDATA.getTypeName(p_in);

	dbms_output.put_line(v_type_name);
	v_bind_val := dbms_assert.enquote_literal(sys.anydata.accessVarchar2(p_in));

	i_csr := dbms_sql.open_cursor;
	dbms_sql.parse(i_csr, v_sql,DBMS_SQL.NATIVE);
	dbms_sql.describe_columns(i_csr, i_col_cnt, rec_tab);

	dbms_output.put_line('v_sql: ' || v_sql);
	dbms_output.put_line('rec_tab.1: ' || rec_tab(1).col_name);
	dbms_output.put_line('v_bind_val: ' || v_bind_val);

	dbms_sql.bind_variable(i_csr, ':r', v_bind_val);
	i_rows := dbms_sql.execute_and_fetch(i_csr);
	dbms_sql.close_cursor(i_csr);
end;
begin
	p(p_in =>  SYS.ANYDATA.convertVarchar2('X'));
end;
/
