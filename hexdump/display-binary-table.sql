
set long 100

select name, my_blob from binary_test where name = 'BLOB';

select name, dump(my_raw) from binary_test where name = 'RAW';

select name, my_long_raw from binary_test where name = 'LONG RAW';

