package controller;

import java.util.List;
import model.AllocationDTO;
import model.AllocationService;
import model.CourseCostDTO;

public class Controller {
    private final AllocationService service = new AllocationService();

    public void increaseStudents(String instanceId, int delta) throws Exception {
        service.increaseStudents(instanceId, delta);
    }

    public CourseCostDTO computeCourseCost(String instanceId) throws Exception {
        return service.computeCourseCost(instanceId);
    }

    public void allocateTeacher(String employmentId, int teachingId, String instanceId, String period) throws Exception {
        service.allocateTeacher(employmentId, teachingId, instanceId, period);
    }

    public void deallocateTeacher(String employmentId, int teachingId, String instanceId) throws Exception {
        service.deallocateTeacher(employmentId, teachingId, instanceId);
    }

    public void addExerciseActivity(String instanceId, int personId) throws Exception {
        service.addExerciseActivity(instanceId, personId);
    }

    public List<AllocationDTO> readExerciseAllocation(String instanceId) throws Exception {
        return service.readExerciseAllocation(instanceId);
    }
}
