
DECLARE
   my_string VARCHAR2(400 CHAR);
BEGIN
   my_string := HelloWorld();
   dbms_output.put_line('The value of the string is ' || my_string);
END;
/
