-- Optional Oracle JVM component for hexdump_binary.hexdump_long_raw
set define off
create or replace and compile java source named "HexdumpLongRaw" authid current_user as
import java.io.IOException;
import java.io.InputStream;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.math.BigDecimal;
import java.util.Arrays;
import java.util.HashMap;

public class HexdumpLongRaw {
    private static final HashMap<Integer, HexdumpLongRaw> readers = new HashMap<>();
    private static int sequence;
    private final PreparedStatement statement;
    private final ResultSet rows;
    private final byte[] buffer = new byte[8192];
    private InputStream stream;

    private HexdumpLongRaw(PreparedStatement statement, ResultSet rows) {
        this.statement = statement;
        this.rows = rows;
    }

    public static int open(String sql, String bindType, String text, BigDecimal number)
            throws SQLException {
        PreparedStatement stmt = DriverManager.getConnection("jdbc:default:connection:")
                .prepareStatement(sql);
        try {
            stmt.setFetchSize(1);
            if ("SYS.NUMBER".equals(bindType)) stmt.setBigDecimal(1, number);
            if ("SYS.VARCHAR2".equals(bindType)) stmt.setString(1, text);
            ResultSet rows = stmt.executeQuery();
            if (rows.getMetaData().getColumnType(1) != Types.LONGVARBINARY)
                throw new SQLException("Expected a LONG RAW column");
            do {
                sequence++;
            } while (readers.containsKey(sequence));
            readers.put(sequence, new HexdumpLongRaw(stmt, rows));
            return sequence;
        } catch (SQLException | RuntimeException e) {
            stmt.close();
            throw e;
        }
    }

    private static HexdumpLongRaw reader(int id) throws SQLException {
        HexdumpLongRaw r = readers.get(id);
        if (r == null) throw new SQLException("Unknown LONG RAW reader");
        return r;
    }

    public static int next(int id) throws SQLException, IOException {
        HexdumpLongRaw r = reader(id);
        if (r.stream != null) r.stream.close();
        r.stream = null;
        if (!r.rows.next()) return 0;
        r.stream = r.rows.getBinaryStream(1);
        return 1;
    }

    public static byte[] read(int id) throws SQLException, IOException {
        HexdumpLongRaw r = reader(id);
        if (r.stream == null) return null;
        int used = 0;
        while (used < r.buffer.length) {
            int n = r.stream.read(r.buffer, used, r.buffer.length - used);
            if (n < 0) break;
            used += n;
        }
        if (used == 0) return null;
        return used == r.buffer.length ? r.buffer : Arrays.copyOf(r.buffer, used);
    }

    public static void close(int id) throws SQLException, IOException {
        HexdumpLongRaw r = readers.remove(id);
        if (r == null) return;
        try {
            if (r.stream != null) r.stream.close();
        } finally {
            r.statement.close();
        }
    }
}
/
show errors java source "HexdumpLongRaw"
set define on
