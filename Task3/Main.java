package app;

import service.CourseService;

public class Main {

    public static void main(String[] args) {

        CourseService service = new CourseService();

        String id = "DD1351-2025P1";
        String id2 = "CS-1007";

        // Part 1
        System.out.println("\nComputing teaching cost");
        service.printCost(id);

        // Part 2
        System.out.println("\nIncreasing students by 100");
        service.increaseStudents(id, 100);
        service.printCost(id);

        // Part 3
        System.out.println("\nTesting allocations");
        
        // Should be a successful allocation
        System.out.println("Allocating to CS-1007");
        service.allocateTeacher(id2, 2, "SF1546-2025P1", "P1");

        // Should be another successful allocation
        System.out.println("Allocating to CS-1007 again");
        service.allocateTeacher(id2, 3, "SF1686-2025P1", "P1");

        // Teacher now has 4 activities so trigger should stop it from adding more
        System.out.println("Attempting third allocation (should fail)");
        service.allocateTeacher(id2, 4, "IV1350-2025P1", "P1");

        // Deallocation
        System.out.println("Deallocating one activity from CS-1007");
        service.deallocateTeacher(id2, 2, "SF1546-2025P1");

        // Allocation should now succeed
        System.out.println("Attempting allocation again after deallocation");
        service.allocateTeacher(id2, 4, "IV1350-2025P1", "P1");

        // Part 4
        System.out.println("\nAdding exercise activity");
        service.addExerciseActivity(id, 124);
        
        System.out.println("\nAll completed.");
    }
}

