
CREATE OR REPLACE AND COMPILE JAVA SOURCE NAMED "HelloWorld" AS
public class HelloWorld
{
	public static String sayHello( String pName ){
		return "Hello World from " + pName;
	}

	//public static void main( String args[] ){ 
		//System.out.println( sayHello( "Oracle" ) ); 
	//}

};
/

show error java source "HelloWorld"

