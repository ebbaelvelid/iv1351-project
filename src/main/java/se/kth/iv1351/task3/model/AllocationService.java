package model;

import integration.*;
import java.util.List;

public class AllocationService {
    private final CourseDAO courseDAO = new CourseDAO();
    private final AllocationDAO allocationDAO = new AllocationDAO();
    private final ActivityDAO activityDAO = new ActivityDAO();
    private final EmployeeDAO employeeDAO = new EmployeeDAO();

    public void increaseStudents(String instanceId, int delta) throws Exception {
        TransactionManager.run(conn -> {
            int current = courseDAO.readStudentsForUpdate(conn, instanceId);
            courseDAO.updateStudents(conn, instanceId, current + delta);
            return null;
        });
    }

    public CourseCostDTO computeCourseCost(String instanceId) throws Exception {
        return TransactionManager.run(conn -> {
            CourseHeaderDTO header = courseDAO.readCourseHeader(conn, instanceId);
            if (header == null) {
                throw new RuntimeException("Course instance not found");
            }

            double plannedHours = courseDAO.readPlannedHours(conn, instanceId);
            double actualHours = courseDAO.readActualAllocatedHours(conn, instanceId);

            return new CourseCostDTO(header.courseCode, header.instanceId, header.studyPeriod, plannedHours, actualHours);
        });
    }

    public void allocateTeacher(String employmentId, int teachingId, String instanceId, String period) throws Exception {
        TransactionManager.run(conn -> {
            Integer personId = employeeDAO.readPersonIdByEmploymentId(conn, employmentId);
            if (personId == null) {
                throw new RuntimeException("Employee not found");
            }

            int count = allocationDAO.countCoursesForTeacherPeriod(conn, employmentId, period);
            if (count >= 4) {
                throw new RuntimeException("Teacher exceeds max course load");
            }

            allocationDAO.createAllocation(conn, personId, instanceId, teachingId);
            return null;
        });
    }

    public void deallocateTeacher(String employmentId, int teachingId, String instanceId) throws Exception {
        TransactionManager.run(conn -> {
            Integer personId = employeeDAO.readPersonIdByEmploymentId(conn, employmentId);
            if (personId == null) {
                throw new RuntimeException("Employee not found");
            }
            allocationDAO.deleteAllocation(conn, personId, instanceId, teachingId);
            return null;
        });
    }

    public void addExerciseActivity(String instanceId, int personId) throws Exception {
        TransactionManager.run(conn -> {
            int activityId = activityDAO.createActivity(conn, "Exercise", 1.0);
            activityDAO.addToPlannedActivity(conn, activityId, instanceId, 20);
            allocationDAO.createAllocation(conn, personId, instanceId, activityId);
            return null;
        });
    }

    public List<AllocationDTO> readExerciseAllocation(String instanceId) throws Exception {
        return TransactionManager.run(conn -> allocationDAO.readExerciseAllocationsByInstance(conn, instanceId));
    }
}
