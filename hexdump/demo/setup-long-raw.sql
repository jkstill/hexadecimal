-- Test data for hexdump_binary.hexdump_long_raw: LONG RAW
-- Requires the Oracle JVM, as does hexdump_long_raw itself.
create table hexdump_demo_long_raw (
	id number primary key,
	name varchar2(30),
	payload long raw
);

insert into hexdump_demo_long_raw values (1, 'short', utl_raw.cast_to_raw('A short LONG RAW value'));

insert into hexdump_demo_long_raw values (2, 'null', null);

-- PL/SQL cannot bind more than 32760 bytes to a LONG RAW.
-- This Java procedure loads a value of any size, bytes 00 to FF repeated.
set define off
create or replace and compile java source named "HexdumpDemoLoad" as
import java.io.ByteArrayInputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;

public class HexdumpDemoLoad {
    public static void load(int id, String name, int size) throws Exception {
        byte[] data = new byte[size];
        for (int i = 0; i < size; i++) data[i] = (byte) i;
        Connection conn = DriverManager.getConnection("jdbc:default:connection:");
        try (PreparedStatement stmt = conn.prepareStatement(
                "insert into hexdump_demo_long_raw values (?, ?, ?)")) {
            stmt.setInt(1, id);
            stmt.setString(2, name);
            stmt.setBinaryStream(3, new ByteArrayInputStream(data), size);
            stmt.executeUpdate();
        }
    }
}
/
show errors java source "HexdumpDemoLoad"
set define on

create or replace procedure hexdump_demo_load_long_raw (id_in number, name_in varchar2, size_in number)
as language java name 'HexdumpDemoLoad.load(int, java.lang.String, int)';
/

-- 100000 bytes: larger than the 32767 byte PL/SQL limit
exec hexdump_demo_load_long_raw(3, 'large', 100000)

-- 257 bytes: one full cycle of 00 to FF plus one byte, so the last line is partial
exec hexdump_demo_load_long_raw(4, 'cycle', 257)

commit;
