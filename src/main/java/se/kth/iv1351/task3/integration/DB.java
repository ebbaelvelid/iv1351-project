package integration;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DB {
    private static final String URL = "jdbc:postgresql://localhost:5432/iv1351";
    private static final String USER = "postgres";
    private static final String PWD = "password";

    public static Connection getConnection() throws SQLException {
        Connection conn = DriverManager.getConnection(URL, USER, PWD);
        conn.setAutoCommit(false);
        return conn;
    }
}
