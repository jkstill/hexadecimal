-- Step-driven variant of the test case. Each lrstep('...') is one database call.
-- Steps: o = executeQuery, n = ResultSet.next() and getBinaryStream,
--        r<count> = read up to <count> bytes, R = read to end of the value.
set define off
create table lrstep_t (id number primary key, payload long raw);
declare
	v raw(32767);
begin
	v := utl_raw.copies(hextoraw('41'), 20000);
	insert into lrstep_t values (1, v);
	v := utl_raw.copies(hextoraw('42'), 20000);
	insert into lrstep_t values (2, v);
	commit;
end;
/
create or replace and compile java source named "LrStep" as
import java.io.InputStream;
import java.sql.*;

public class LrStep {
    private static PreparedStatement stmt;
    private static ResultSet rows;
    private static InputStream in;

    public static String run(String steps) throws Exception {
        StringBuilder out = new StringBuilder();
        for (String step : steps.trim().split("\\s+")) {
            if (step.equals("o")) {
                stmt = DriverManager.getConnection("jdbc:default:connection:")
                        .prepareStatement("select payload from lrstep_t order by id");
                rows = stmt.executeQuery();
                out.append("open ");
            } else if (step.equals("n")) {
                boolean more = rows.next();
                in = more ? rows.getBinaryStream(1) : null;
                out.append(more ? "row " : "end ");
            } else {
                long want = step.equals("R") ? Long.MAX_VALUE : Long.parseLong(step.substring(1));
                long got = 0;
                byte[] buf = new byte[1000];
                while (in != null && got < want) {
                    int n = in.read(buf, 0, (int) Math.min(buf.length, want - got));
                    if (n < 0) break;
                    got += n;
                }
                out.append("read=" + got + " ");
            }
        }
        return out.toString();
    }
}
/
show errors java source "LrStep"
create or replace function lrstep(steps varchar2) return varchar2 as language java name 'LrStep.run(java.lang.String) return java.lang.String';
/
set define on
