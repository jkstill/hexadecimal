SELECT * FROM TABLE(StockPivot(CURSOR(SELECT * FROM StockTable where rownum < 2)))
/
