package integration;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import model.CourseHeaderDTO;

public class CourseDAO {

    public CourseHeaderDTO readCourseHeader(Connection conn, String instanceId) throws SQLException {
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

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, instanceId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new CourseHeaderDTO(
                        rs.getString("course_code"),
                        rs.getString("instance_id"),
                        rs.getString("study_period")
                    );
                }
                return null;
            }
        }
    }

    public double readActualAllocatedHours(Connection conn, String instanceId) throws SQLException {
        String sql = """
        SELECT COALESCE(SUM(
            CASE
                WHEN ta.activity_name IN ('Lecture','Tutorial','Lab','Seminar','Others')
                    THEN a.allocated_hours * ta.factor
                WHEN ta.activity_name IN ('Administration','Examination')
                    THEN a.allocated_hours
                ELSE 0
            END
        ), 0) AS total
        FROM allocations a
        JOIN teaching_activity ta ON a.id_teaching = ta.id
        WHERE a.instance_id = ?
        """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, instanceId);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getDouble("total");
            }
        }
    }

    public double readPlannedHours(Connection conn, String instanceId) throws SQLException {
        String sql = """
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
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getDouble("total");
            }
        }
    }

    public int readStudentsForUpdate(Connection conn, String instanceId) throws SQLException {
        String sql = """
                SELECT num_students
                FROM course_instance
                WHERE instance_id = ?
                FOR UPDATE
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, instanceId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("num_students");
                }
                throw new SQLException("Course instance not found");
            }
        }
    }

    public void updateStudents(Connection conn, String instanceId, int newValue) throws SQLException {
        String sql = """
                UPDATE course_instance
                SET num_students = ?
                WHERE instance_id = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, newValue);
            ps.setString(2, instanceId);
            ps.executeUpdate();
        }
    }
}
