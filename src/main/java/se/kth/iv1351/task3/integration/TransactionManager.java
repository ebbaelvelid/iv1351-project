package integration;

import java.sql.Connection;

public class TransactionManager {
    public interface Transaction<T> {
        T run(Connection conn) throws Exception;
    }

    public static <T> T run(Transaction<T> tx) throws Exception {
        try (Connection conn = DB.getConnection()) {
            try {
                T result = tx.run(conn);
                conn.commit();
                return result;
            } catch (Exception e) {
                conn.rollback();
                throw e;
            }
        }
    }
}
