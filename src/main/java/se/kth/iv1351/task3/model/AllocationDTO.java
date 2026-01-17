package model;

public class AllocationDTO {
    public final String courseCode;
    public final String courseName;
    public final String instanceId;
    public final String employmentId;

    public AllocationDTO(String courseCode, String courseName, String instanceId, String employmentId) {
        this.courseCode = courseCode;
        this.courseName = courseName;
        this.instanceId = instanceId;
        this.employmentId = employmentId;
    }
}
