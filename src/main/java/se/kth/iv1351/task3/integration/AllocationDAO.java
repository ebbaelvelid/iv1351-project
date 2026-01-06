package integration;
import java.sql.*;

public class AllocationDAO {

    public int countCoursesForTeacherPeriod(Connection conn, String employmentId, String period) throws SQLException {
        String sql
                = """
            SELECT COUNT(DISTINCT ci.instance_id) AS cnt
            FROM allocations a
            JOIN employee e ON a.id_person = e.id_person
            JOIN course_instance ci ON a.instance_id = ci.instance_id
            JOIN study_period_ENUM sp
                ON ci.study_period_id = sp.study_period_id
            WHERE e.employment_id = ?
              AND sp.study_period = ?
            """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, employmentId);
            ps.setString(2, period);
            ResultSet rs = ps.executeQuery();
            rs.next();
            return rs.getInt("cnt");
        }
    }

    public void createAllocation(Connection conn, int personId, String instanceId, int teachingId) throws SQLException {
        String sql
                = "INSERT INTO allocations "
                + "(id_person, instance_id, id_teaching) "
                + "VALUES (?,?,?)";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, personId);
            ps.setString(2, instanceId);
            ps.setInt(3, teachingId);
            ps.executeUpdate();
        }
    }

    public void deleteAllocation(Connection conn, int personId, String instanceId, int teachingId) throws SQLException {
        String sql
                = "DELETE FROM allocations "
                + "WHERE id_person = ? "
                + "AND instance_id = ? "
                + "AND id_teaching = ?";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, personId);
            ps.setString(2, instanceId);
            ps.setInt(3, teachingId);
            ps.executeUpdate();
        }
    }
