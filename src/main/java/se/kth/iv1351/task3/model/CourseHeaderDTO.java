package model;

public class CourseHeaderDTO {
    public final String courseCode;
    public final String instanceId;
    public final String studyPeriod;

    public CourseHeaderDTO(String courseCode, String instanceId, String studyPeriod) {
        this.courseCode = courseCode;
        this.instanceId = instanceId;
        this.studyPeriod = studyPeriod;
    }
}
