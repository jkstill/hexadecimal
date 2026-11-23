-- Archived from the single-call 19c digest check. Requires the existing
-- BINARY_TEST fixtures and an Oracle JVM. These object names belong to the probe.
set define off
create java source named "Hexdump19ReadProbe" authid current_user as
import java.io.InputStream;
import java.security.MessageDigest;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

public class Hexdump19ReadProbe {
    public static String check(String name) throws Exception {
        Connection conn = DriverManager.getConnection("jdbc:default:connection:");
        String sql = "select my_long_raw from binary_test where name=?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, name);
            try (ResultSet rows = stmt.executeQuery()) {
                if (!rows.next()) return "missing";
                try (InputStream stream = rows.getBinaryStream(1)) {
                    if (stream == null) return "null";
                    byte[] buffer = new byte[8192];
                    MessageDigest digest = MessageDigest.getInstance("SHA-256");
                    long length = 0;
                    int count;
                    while ((count = stream.read(buffer)) != -1) {
                        digest.update(buffer, 0, count);
                        length += count;
                    }
                    StringBuilder hex = new StringBuilder();
                    for (byte b : digest.digest()) {
                        hex.append(String.format("%02x", b & 255));
                    }
                    return length + " " + hex;
                }
            }
        }
    }
}
/
show errors java source "Hexdump19ReadProbe"
create function hexdump19_read_probe(n varchar2) return varchar2 authid current_user
as language java name 'Hexdump19ReadProbe.check(java.lang.String) return java.lang.String';
/
column result format a90
select hexdump19_read_probe('LONG RAW') result from dual;
select hexdump19_read_probe('VERY LONG RAW') result from dual;
set define on
