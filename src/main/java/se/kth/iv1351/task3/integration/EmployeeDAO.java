package integration;
import java.sql.*;

public class EmployeeDAO {

    public Integer findPersonIdByEmploymentId(Connection conn, String employmentId) throws SQLException {
        String sql = "SELECT id_person FROM employee WHERE employment_id = ?";
        
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, employmentId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt("id_person");
            }
            return null;
        }
    }
}
