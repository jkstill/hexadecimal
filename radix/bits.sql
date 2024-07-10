select radix.to_bin(power(2,level)) from dual connect by level <= 64
/
