package integration;
import java.sql.*;

public class ActivityDAO {

    public int createActivity(Connection conn, String name, double factor) throws SQLException {
        String sql
                = "INSERT INTO teaching_activity (id, activity_name, factor) "
                + "VALUES ((SELECT COALESCE(MAX(id), 0) + 1 FROM teaching_activity), ?, ?) "
                + "RETURNING id";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, name);
            ps.setDouble(2, factor);
            ResultSet rs = ps.executeQuery();
            rs.next();
            return rs.getInt(1);
        }
    }

    public void addToPlannedActivity(Connection conn, int teachingId, String instanceId, double plannedHours) throws SQLException {
        String sql
                = "INSERT INTO planned_activity "
                + "(id_teaching, instance_id, planned_hours) "
                + "VALUES (?,?,?)";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, teachingId);
            ps.setString(2, instanceId);
            ps.setDouble(3, plannedHours);
            ps.executeUpdate();
        }
    }
}
