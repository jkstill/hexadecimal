
-- will fail if the instance has insufficent memory for a java_pool of at least 100m

SELECT * FROM TABLE(StockPivot(CURSOR(SELECT * FROM StockTable)))
/
