:



export PATH=$PATH:$ORACLE_HOME/jdk/bin
export CLASSPATH=./:$ORACLE_HOME/jdbc/lib/ojdbc8.jar
# this Java is in the package oraConnect, and so must live in the oraConnect directory
# obvious to Java developers, new to me
# using -d oraConnect will nest a level deeper - oraConnect/oraConnect/OracleConnect.class
# by default the oraConnect directory is used
#[[ oraConnect/OracleConnect.java -nt oraConnect/OracleConnect.class ]] && {
	#echo Building oraConnect/OracleConnect.class >&2
	#javac -Xdiags:verbose -d oraConnect oraConnect/OracleConnect.java
#}


[[ LongRawToBlobConverter.java -nt LongRawToBlobConverter.class ]] && {
	echo Building LongRawToBlobConverter.class >&2
	#javac  -Xlint:deprecation  -Xdiags:verbose  LongRawToBlobConverter.java
	javac  -nowarn  -Xdiags:verbose  LongRawToBlobConverter.java
}

loadjava -user  jkstill/grok@ora192rac02/pdb1.jks.com LongRawToBlobConverter.class


# database username password
# database can be EZ Connect
#time java RetrieveDirFile "$ORADB" "$ORAUSER" "$ORAPASSWORD" $ORADIR "$tracefile" > trace/"$tracefile"


