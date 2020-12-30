
// create the directory object

CREATE OR REPLACE DIRECTORY JavaDir AS '/u01/files';

// compile the java source

drop java source source01;

CREATE AND COMPILE JAVA SOURCE NAMED source01
USING BFILE (JavaDir,'StockPivotImpl.java');
/
show errors java source source01

-- Create the implementation type

drop  TYPE StockPivotImpl ;

CREATE TYPE StockPivotImpl AS OBJECT
(
  key INTEGER,

  STATIC FUNCTION ODCITableStart(sctx OUT StockPivotImpl, cur SYS_REFCURSOR)
    RETURN NUMBER
    AS LANGUAGE JAVA
    NAME 'StockPivotImpl.ODCITableStart(oracle.sql.STRUCT[], java.sql.ResultSet) 
return java.math.BigDecimal',

  MEMBER FUNCTION ODCITableFetch(self IN OUT StockPivotImpl, nrows IN NUMBER,
                                 outSet OUT TickerTypeSet) RETURN NUMBER
    AS LANGUAGE JAVA
    NAME 'StockPivotImpl.ODCITableFetch(java.math.BigDecimal, 
oracle.sql.ARRAY[]) return java.math.BigDecimal',

  MEMBER FUNCTION ODCITableClose(self IN StockPivotImpl) RETURN NUMBER
    AS LANGUAGE JAVA
    NAME 'StockPivotImpl.ODCITableClose() return java.math.BigDecimal'

);
/
show errors
