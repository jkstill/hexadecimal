
set serveroutput on size unlimited

DECLARE
    hex_value VARCHAR2(32767);
    cursor c is select my_long_raw from binary_test where name = 'VERY LONG RAW';
    l_chunk RAW(32767);
	 i_chunk_size pls_integer := 32767;

	i_pass pls_integer := 0;
BEGIN
    FOR rec IN c LOOP
        -- Assuming 'your_long_raw_column' is the LONG RAW data
        -- Loop through the data in 32767-byte chunks
        FOR i IN 0 .. TRUNC(DBMS_LOB.GETLENGTH(rec.my_long_raw) / 32767) LOOP
            DBMS_LOB.READ(rec.my_long_raw, i_chunk_size, i * 32767 + 1, l_chunk);
            --hex_value := convert_long_raw_to_hex(l_chunk);
				dbms_output.put_line('pass: ' || to_char(i_pass) || ' size: ' || to_char(i_chunk_size) );
            -- Further processing with hex_value
        END LOOP;
    END LOOP;
END;
/

