

CREATE TABLE StockTable (
  ticker VARCHAR(4),
  openprice NUMBER,
  closeprice NUMBER
);

-- Create the types for the table function's output collection 
-- and collection elements

CREATE  TYPE TickerType AS OBJECT
(
  ticker VARCHAR2(4),
  PriceType VARCHAR2(1),
  price NUMBER
);
/

CREATE  TYPE TickerTypeSet AS TABLE OF TickerType;
/

-- Define the ref cursor type

CREATE or replace PACKAGE refcur_pkg IS
  TYPE refcur_t IS REF CURSOR RETURN StockTable%ROWTYPE;
END refcur_pkg;
/

-- Create table function

CREATE or replace FUNCTION StockPivot(p refcur_pkg.refcur_t) RETURN TickerTypeSet
PIPELINED USING StockPivotImpl;
/
