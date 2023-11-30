
CREATE OR REPLACE FUNCTION long_raw_to_blob(tableName IN VARCHAR2, columnName IN VARCHAR2, rowId IN VARCHAR2)
RETURN BLOB AS LANGUAGE JAVA
NAME 'LongRawToBlobConverter.longRawToBlob(java.lang.String, java.lang.String, java.lang.String) return oracle.sql.BLOB';
/

show error function long_raw_to_blob



