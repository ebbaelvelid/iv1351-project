package integration;
import java.sql.*;

public class CourseDAO {

    public ResultSet findCourseHeader(Connection conn, String instanceId) throws SQLException {
        String sql = """
        SELECT
            cl.course_code,
            ci.instance_id,
            sp.study_period
        FROM course_instance ci
        JOIN course_layout cl ON ci.id_layout = cl.id
        JOIN study_period_ENUM sp ON ci.study_period_id = sp.study_period_id
        WHERE ci.instance_id = ?
        """;

        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setString(1, instanceId);
        return ps.executeQuery();
    }

    public double findActualAllocatedHours(Connection conn, String instanceId) throws SQLException {
        String sql = """
        SELECT COALESCE(SUM(
            CASE
                WHEN ta.activity_name IN ('Lecture','Tutorial','Lab','Seminar','Others')
                    THEN pa.planned_hours * ta.factor
                WHEN ta.activity_name = 'Administration'
                    THEN pa.planned_hours + ta.factor * ci.num_students + 2 * cl.hp
                WHEN ta.activity_name = 'Examination'
                    THEN pa.planned_hours + ta.factor * ci.num_students
                ELSE 0
            END
        ), 0) AS total
        FROM allocations a
        JOIN planned_activity pa
            ON a.id_teaching = pa.id_teaching
           AND a.instance_id = pa.instance_id
        JOIN teaching_activity ta
            ON pa.id_teaching = ta.id
        JOIN course_instance ci
            ON a.instance_id = ci.instance_id
        JOIN course_layout cl
            ON ci.id_layout = cl.id
        WHERE a.instance_id = ?
        """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, instanceId);
            ResultSet rs = ps.executeQuery();
            rs.next();
            return rs.getDouble("total");
        }
    }

    public double findPlannedHours(Connection conn, String instanceId) throws SQLException {
        String sql
                = """
            SELECT SUM(
                CASE
                    WHEN ta.activity_name IN
                        ('Lecture','Tutorial','Lab','Seminar','Others')
                        THEN pa.planned_hours * ta.factor
                    WHEN ta.activity_name = 'Administration'
                        THEN pa.planned_hours
                             + ta.factor * ci.num_students
                             + 2 * cl.hp
                    WHEN ta.activity_name = 'Examination'
                        THEN pa.planned_hours
                             + ta.factor * ci.num_students
                    ELSE 0
                END
            ) AS total
            FROM course_instance ci
            JOIN course_layout cl ON ci.id_layout = cl.id
            JOIN planned_activity pa ON ci.instance_id = pa.instance_id
            JOIN teaching_activity ta ON pa.id_teaching = ta.id
            WHERE ci.instance_id = ?
            """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, instanceId);
            ResultSet rs = ps.executeQuery();
            rs.next();
            return rs.getDouble("total");
        }
    }

    public int findStudentsForUpdate(Connection conn, String instanceId) throws SQLException {
        String sql
                = "SELECT num_students "
                + "FROM course_instance "
                + "WHERE instance_id = ? "
                + "FOR UPDATE";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, instanceId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt("num_students");
            }
            throw new SQLException("Course instance not found");
        }
    }

    public void updateStudents(Connection conn,
            String instanceId,
            int newValue) throws SQLException {

        String sql
                = "UPDATE course_instance "
                + "SET num_students = ? "
                + "WHERE instance_id = ?";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, newValue);
            ps.setString(2, instanceId);
            ps.executeUpdate();
        }
    }
}
