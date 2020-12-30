

CREATE OR REPLACE FUNCTION 
say_hello (
	p_name varchar2 
) return varchar2
AS language java name
'HelloWorld.sayHello ( 
	java.lang.String 
) 
return java.lang.String';
/


show error function say_hello

