-- Java reader, iterator type and chunk function for hexdump_binary.hexdump_long_raw.
-- Requires the Oracle JVM. Install after hexdump-binary.sql. BLOB and RAW dumps do not need it.
set define off
create or replace and compile java source named "HexdumpLongRaw" authid current_user as
import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
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
    private final String rowSql;
    private final byte[] buffer = new byte[2000];
    private PreparedStatement rowStatement;
    private InputStream stream;
    private byte[] first;

    private HexdumpLongRaw(PreparedStatement statement, ResultSet rows, String rowSql) {
        this.statement = statement;
        this.rows = rows;
        this.rowSql = rowSql;
    }

    // keySql selects the ROWIDs to dump. rowSql selects one LONG RAW by ROWID.
    public static int open(String keySql, String rowSql, String bindType, String text,
            BigDecimal number) throws SQLException {
        Connection conn = DriverManager.getConnection("jdbc:default:connection:");
        try (PreparedStatement probe = conn.prepareStatement(rowSql)) {
            if (probe.getMetaData().getColumnType(1) != Types.LONGVARBINARY)
                throw new SQLException("Expected a LONG RAW column");
        }
        PreparedStatement stmt = conn.prepareStatement(keySql);
        try {
            if ("SYS.NUMBER".equals(bindType)) stmt.setBigDecimal(1, number);
            if ("SYS.VARCHAR2".equals(bindType)) stmt.setString(1, text);
            ResultSet rows = stmt.executeQuery();
            do {
                sequence++;
            } while (readers.containsKey(sequence));
            readers.put(sequence, new HexdumpLongRaw(stmt, rows, rowSql));
            return sequence;
        } catch (SQLException | RuntimeException e) {
            stmt.close();
            throw e;
        }
    }

    private void closeRow() throws SQLException, IOException {
        try {
            if (stream != null) stream.close();
        } finally {
            stream = null;
            first = null;
            if (rowStatement != null) rowStatement.close();
            rowStatement = null;
        }
    }

    private static HexdumpLongRaw reader(int id) throws SQLException {
        HexdumpLongRaw r = readers.get(id);
        if (r == null) throw new SQLException("Unknown LONG RAW reader");
        return r;
    }

    public static int next(int id) throws SQLException, IOException {
        HexdumpLongRaw r = reader(id);
        r.closeRow();
        if (!r.rows.next()) return 0;
        // executeQuery, next and the first read of a LONG RAW must share one
        // database call. Later reads of the same value may span calls.
        r.rowStatement = DriverManager.getConnection("jdbc:default:connection:")
                .prepareStatement(r.rowSql);
        r.rowStatement.setString(1, r.rows.getString(1));
        ResultSet value = r.rowStatement.executeQuery();
        if (value.next()) r.stream = value.getBinaryStream(1);
        r.first = r.fill();
        return 1;
    }

    public static byte[] read(int id) throws SQLException, IOException {
        HexdumpLongRaw r = reader(id);
        if (r.first != null) {
            byte[] chunk = r.first;
            r.first = null;
            return chunk;
        }
        return r.fill();
    }

    private byte[] fill() throws IOException {
        if (stream == null) return null;
        int used = 0;
        while (used < buffer.length) {
            int n = stream.read(buffer, used, buffer.length - used);
            if (n < 0) break;
            used += n;
        }
        if (used == 0) return null;
        return used == buffer.length ? buffer : Arrays.copyOf(buffer, used);
    }

    public static void close(int id) throws SQLException, IOException {
        HexdumpLongRaw r = readers.remove(id);
        if (r == null) return;
        try {
            r.closeRow();
        } finally {
            r.statement.close();
        }
    }
}
/
show errors java source "HexdumpLongRaw"
set define on

-- One null chunk marks the start of each source row, including null values.
create or replace type hexdump_raw_scan authid current_user as object (
    reader_id number,
    need_row number,
    static function open_reader(stmt varchar2, row_stmt varchar2, typ varchar2, txt varchar2,
            num number) return number,
    static function next_row(id number) return number,
    static function read_chunk(id number) return raw,
    static procedure close_reader(id number),
    static function ODCITableStart(ctx out hexdump_raw_scan, stmt varchar2, row_stmt varchar2,
        bind_type varchar2, bind_text varchar2, bind_number number) return number,
    member function ODCITableFetch(self in out hexdump_raw_scan, nrows number,
        chunks out sys.odcirawlist) return number,
    member function ODCITableClose(self in hexdump_raw_scan) return number
);
/
create or replace type body hexdump_raw_scan as
    static function open_reader(stmt varchar2, row_stmt varchar2, typ varchar2, txt varchar2,
            num number) return number as language java name
            'HexdumpLongRaw.open(java.lang.String, java.lang.String, java.lang.String, java.lang.String, java.math.BigDecimal) return int';
    static function next_row(id number) return number as language java
            name 'HexdumpLongRaw.next(int) return int';
    static function read_chunk(id number) return raw as language java
            name 'HexdumpLongRaw.read(int) return byte[]';
    static procedure close_reader(id number) as language java
            name 'HexdumpLongRaw.close(int)';
    static function ODCITableStart(ctx out hexdump_raw_scan, stmt varchar2, row_stmt varchar2,
        bind_type varchar2, bind_text varchar2, bind_number number) return number is
    begin
        ctx := hexdump_raw_scan(open_reader(stmt, row_stmt, bind_type, bind_text, bind_number), 1);
        return odciconst.success;
    end;
    member function ODCITableFetch(self in out hexdump_raw_scan, nrows number,
        chunks out sys.odcirawlist) return number is
        piece raw(2000);
    begin
        chunks := sys.odcirawlist();
        while need_row <> 2 and chunks.count < least(greatest(nrows,1),4) loop
            if need_row = 1 then
                if hexdump_raw_scan.next_row(reader_id) = 0 then
                    need_row := 2;
                    exit;
                end if;
                chunks.extend;
                need_row := 0;
            else
                piece := hexdump_raw_scan.read_chunk(reader_id);
                if piece is null then
                    need_row := 1;
                else
                    chunks.extend;
                    chunks(chunks.last) := piece;
                end if;
            end if;
        end loop;
        return odciconst.success;
    end;
    member function ODCITableClose(self in hexdump_raw_scan) return number is
    begin
        hexdump_raw_scan.close_reader(reader_id);
        return odciconst.success;
    end;
end;
/
show errors type body hexdump_raw_scan
create or replace function hexdump_raw_chunks(stmt varchar2, row_stmt varchar2, bind_type varchar2,
    bind_text varchar2, bind_number number) return sys.odcirawlist
    authid current_user pipelined using hexdump_raw_scan;
/
show errors function hexdump_raw_chunks
