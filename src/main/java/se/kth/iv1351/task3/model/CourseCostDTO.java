package model;

public class CourseCostDTO {
    public final String courseCode;
    public final String instanceId;
    public final String period;
    public final double plannedHours;
    public final double actualHours;

    public CourseCostDTO(String courseCode, String instanceId, String period, double plannedHours, double actualHours) {
        this.courseCode = courseCode;
        this.instanceId = instanceId;
        this.period = period;
        this.plannedHours = plannedHours;
        this.actualHours = actualHours;
    }
}
