package integration;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import model.AllocationDTO;

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
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt("cnt");
            }
        }
    }

    public void createAllocation(Connection conn, int personId, String instanceId, int teachingId) throws SQLException {
        String sql
                = "INSERT INTO allocations "
                + "(id_person, instance_id, id_teaching, allocated_hours) "
                + "VALUES (?,?,?, ?)";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, personId);
            ps.setString(2, instanceId);
            ps.setInt(3, teachingId);
            ps.setInt(4, 0); // initialize allocated_hours to zero
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
    
    public List<AllocationDTO> readExerciseAllocationsByInstance(Connection conn, String instanceId) throws SQLException {
        String sql = """
        SELECT
            cl.course_code,
            cl.course_name,
            ci.instance_id,
            e.employment_id
        FROM allocations a
        JOIN employee e ON a.id_person = e.id_person
        JOIN course_instance ci ON a.instance_id = ci.instance_id
        JOIN course_layout cl ON ci.id_layout = cl.id
        JOIN teaching_activity ta ON a.id_teaching = ta.id
        WHERE ci.instance_id = ?
          AND ta.activity_name = 'Exercise'
        """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, instanceId);
            try (ResultSet rs = ps.executeQuery()) {
                List<AllocationDTO> list = new ArrayList<>();
                while (rs.next()) {
                    list.add(new AllocationDTO(
                            rs.getString("course_code"),
                            rs.getString("course_name"),
                            rs.getString("instance_id"),
                            rs.getString("employment_id")
                    ));
                }
                return list;
            }
        }
    }
}
