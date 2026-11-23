set serveroutput on
declare
    offset_bytes pls_integer;
    headers pls_integer;
    expected_hex varchar2(48);
    expected_text varchar2(18);
    byte_val pls_integer;
begin
    for rec in (select id from hxatp_fixture order by id) loop
        offset_bytes := 0;
        headers := 0;
        for line in (select address,data,text from table(hxatp_dump.hexdump_long_raw(
            'HXATP_FIXTURE',null,'PAYLOAD','where id = :b',sys.anydata.convertnumber(rec.id)))) loop
            if line.address = '========' then
                if headers <> 0 or offset_bytes <> 0 then raise_application_error(-20000,'unexpected header'); end if;
                headers := 1;
            else
                expected_hex := null;
                expected_text := '|';
                for idx in 1..least(16,rec.id-offset_bytes) loop
                    byte_val := mod(offset_bytes+idx-1,256);
                    expected_hex := expected_hex || lpad(to_char(byte_val,'FMXX'),2,'0') || ' ';
                    expected_text := expected_text || case when byte_val between 32 and 126 then chr(byte_val) else '.' end;
                end loop;
                if nvl(line.address,'?') <> lpad(to_char(offset_bytes,'FMXXXXXXXX'),8,'0')
                    or nvl(line.data,'?') <> rtrim(expected_hex)
                    or nvl(line.text,'?') <> expected_text||'|' then
                    raise_application_error(-20000,'mismatch at '||rec.id||'/'||offset_bytes);
                end if;
                offset_bytes := offset_bytes + least(16,rec.id-offset_bytes);
            end if;
        end loop;
        if offset_bytes <> rec.id or headers <> 1 then raise_application_error(-20000,'row count mismatch'); end if;
        dbms_output.put_line('Verified '||rec.id||' bytes');
    end loop;
end;
/
