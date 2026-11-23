
set serveroutput on size unlimited

DECLARE
	lob_data BLOB;
	row_id varchar2(100); -- Assuming you have the ROWID
BEGIN
	SELECT ROWID INTO row_id FROM binary_test WHERE name = 'VERY LONG RAW';

	lob_data := long_raw_to_blob('BINARY_TEST', 'MY_LONG_RAW', row_id);

	dbms_output.put_line(dbms_lob.substr(lob_data,100,1));

	-- Now lob_data contains the BLOB data
	-- Further processing with lob_data

	-- Remember to free the BLOB
	DBMS_LOB.FREETEMPORARY(lob_data);

END;
/


