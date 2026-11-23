-- Minimal test case: server-side JDBC ResultSet over a LONG RAW column,
-- advanced to a second row in a later top-level call. No hexdump code involved.
set define off
create table lrbug_t (id number primary key, payload long raw);
create table lrbug_r (id number primary key, payload raw(2000));
begin
	insert into lrbug_r values (1, utl_raw.copies(hextoraw('41'), 2000));
	insert into lrbug_r values (2, utl_raw.copies(hextoraw('42'), 2000));
	insert into lrbug_r values (3, utl_raw.copies(hextoraw('43'), 2000));
	insert into lrbug_t values (1, utl_raw.copies(hextoraw('41'), 2000));
	insert into lrbug_t values (2, utl_raw.copies(hextoraw('42'), 2000));
	insert into lrbug_t values (3, utl_raw.copies(hextoraw('43'), 2000));
	commit;
end;
/
create or replace and compile java source named "LrBug" as
import java.io.InputStream;
import java.sql.*;

public class LrBug {
    private static PreparedStatement stmt;
    private static ResultSet rows;

    public static void open(String table) throws Exception {
        stmt = DriverManager.getConnection("jdbc:default:connection:")
                .prepareStatement("select payload from " + table + " order by id");
        stmt.setFetchSize(1);
        rows = stmt.executeQuery();
    }

    // Returns the byte count of the next row, or -1 at end of data.
    public static int next() throws Exception {
        if (!rows.next()) { stmt.close(); return -1; }
        int total = 0, n;
        byte[] buf = new byte[8192];
        try (InputStream in = rows.getBinaryStream(1)) {
            while ((n = in.read(buf)) != -1) total += n;
        }
        return total;
    }

    // Everything inside one call, for comparison.
    public static int all(String table) throws Exception {
        open(table);
        int sum = 0, n;
        while ((n = next()) != -1) sum += n;
        return sum;
    }
}
/
show errors java source "LrBug"
create or replace procedure lrbug_open(tab varchar2) as language java name 'LrBug.open(java.lang.String)';
/
create or replace function lrbug_next return number as language java name 'LrBug.next() return int';
/
create or replace function lrbug_all(tab varchar2) return number as language java name 'LrBug.all(java.lang.String) return int';
/
set define on
