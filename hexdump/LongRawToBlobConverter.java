import java.sql.*;
import oracle.jdbc.driver.*;
import oracle.sql.BLOB;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.IOException;
import java.io.InputStreamReader;

public class LongRawToBlobConverter {
    public static BLOB longRawToBlob(String tableName, String columnName, String rowId) throws SQLException {
        Connection conn = new OracleDriver().defaultConnection();
        BLOB blob = null;

        String query = "SELECT " + columnName + " FROM " + tableName + " WHERE ROWID = ?";
        try (PreparedStatement pstmt = conn.prepareStatement(query)) {
            pstmt.setString(1, rowId);
            
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                // Create a temporary BLOB
                blob = BLOB.createTemporary(conn, false, BLOB.DURATION_SESSION);

                // Open the BLOB to write data
                blob.open(BLOB.MODE_READWRITE);

                // Get the LONG RAW data as a stream
                try (InputStream rawStream = rs.getBinaryStream(1);
                     OutputStream blobStream = blob.setBinaryStream(0L)) {
                    
                    byte[] buffer = new byte[8192];
                    int bytesRead;
                    while ((bytesRead = rawStream.read(buffer)) != -1) {
                        blobStream.write(buffer, 0, bytesRead);
                    }
                    blobStream.flush();
                } catch (IOException e) {
                    // Handle IOException
                    throw new SQLException("Error processing the LONG RAW data", e);
                }
            }
        }

        return blob;
    }
}

