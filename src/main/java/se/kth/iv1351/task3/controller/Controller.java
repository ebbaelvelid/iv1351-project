package controller;
import integration.*;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;

public class Controller {

    private static final double COST_PER_HOUR = 1.2;
    private final CourseDAO courseDAO = new CourseDAO();
    private final AllocationDAO allocationDAO = new AllocationDAO();
    private final ActivityDAO activityDAO = new ActivityDAO();
    private final EmployeeDAO employeeDAO = new EmployeeDAO();

    public void increaseStudents(String instanceId, int delta) {
        try (Connection conn = DB.getConnection()) {
            try {
                int current = courseDAO.findStudentsForUpdate(conn, instanceId);
                courseDAO.updateStudents(conn, instanceId, current + delta);
                conn.commit();
                System.out.println("Student count updated.");
            } catch (Exception e) {
                conn.rollback();
                throw e;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void printCost(String instanceId) {
        try (Connection conn = DB.getConnection()) {
            ResultSet rs = courseDAO.findCourseHeader(conn, instanceId);
            if (!rs.next()) {
                throw new RuntimeException("Course instance not found");
            }

            String courseCode = rs.getString("course_code");
            String instance = rs.getString("instance_id");
            String period = rs.getString("study_period");

            double plannedHours = courseDAO.findPlannedHours(conn, instanceId);
            double actualHours = courseDAO.findActualAllocatedHours(conn, instanceId);

            System.out.println("Course code: " + courseCode);
            System.out.println("Course instance: " + instance);
            System.out.println("Period: " + period);
            System.out.println("Planned cost: " + plannedHours * COST_PER_HOUR + " KSEK");
            System.out.println("Actual cost: " + actualHours * COST_PER_HOUR + " KSEK");

            conn.rollback();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void allocateTeacher(String employmentId, int teachingId, String instanceId, String period) {
        try (Connection conn = DB.getConnection()) {
            try {
                Integer personId = employeeDAO.findPersonIdByEmploymentId(conn, employmentId);
                if (personId == null) {
                    throw new RuntimeException("Employee not found");
                }

                int count = allocationDAO.countCoursesForTeacherPeriod(conn, employmentId, period);
                if (count >= 4) {
                    throw new RuntimeException("Teacher exceeds max course load");
                }

                allocationDAO.createAllocation(conn, personId, instanceId, teachingId);
                conn.commit();
                System.out.println("Allocation successful.");
            } catch (Exception e) {
                conn.rollback();
                System.out.println("ERROR: " + e.getMessage());
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    public void addExerciseActivity(String instanceId, int personId) {
        try (Connection conn = DB.getConnection()) {
            try {
                int activityId = activityDAO.createActivity(conn, "Exercise", 1.0);
                activityDAO.addToPlannedActivity(conn, activityId, instanceId, 20);
                allocationDAO.createAllocation(conn, personId, instanceId, activityId);

                conn.commit();
                System.out.println("Exercise activity added.");
            } catch (Exception e) {
                conn.rollback();
                System.out.println("ERROR: " + e.getMessage());
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    public void deallocateTeacher(String employmentId, int teachingId, String instanceId) {
        try (Connection conn = DB.getConnection()) {
            try {
                String sql = "SELECT id_person FROM employee WHERE employment_id = ?";
                int personId;
                try (java.sql.PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setString(1, employmentId);
                    java.sql.ResultSet rs = ps.executeQuery();
                    if (!rs.next()) {
                        throw new RuntimeException("Employee not found");
                    }
                    personId = rs.getInt("id_person");
                }

                allocationDAO.deleteAllocation(conn, personId, instanceId, teachingId);
                conn.commit();
                System.out.println("Deallocation successful.");
            } catch (Exception e) {
                conn.rollback();
                System.out.println("ERROR: " + e.getMessage());
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    public void displayExerciseAllocation(String instanceId) {
        try (Connection conn = DB.getConnection()) {
            String sql = """
            SELECT
                cl.course_code,
                cl.course_name,
                ci.instance_id,
                ta.activity_name,
                e.employment_id
            FROM allocations a
            JOIN employee e ON a.id_person = e.id_person
            JOIN course_instance ci ON a.instance_id = ci.instance_id
            JOIN course_layout cl ON ci.id_layout = cl.id
            JOIN teaching_activity ta ON a.id_teaching = ta.id
            WHERE ci.instance_id = ?
              AND ta.activity_name = 'Exercise'
            """;

            try (var ps = conn.prepareStatement(sql)) {
                ps.setString(1, instanceId);
                var rs = ps.executeQuery();

                System.out.println("Exercise allocation for course instance:");
                boolean found = false;

                while (rs.next()) {
                    found = true;
                    System.out.println(
                            rs.getString("course_code") + " - "
                            + rs.getString("course_name") + ", "
                            + rs.getString("instance_id") + ", Teacher: "
                            + rs.getString("employment_id")
                    );
                }

                if (!found) {
                    System.out.println("No Exercise allocation found.");
                }
            }
            conn.rollback();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
