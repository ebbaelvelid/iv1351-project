package view;

import controller.Controller;
import java.util.List;
import java.util.Scanner;
import model.AllocationDTO;
import model.CourseCostDTO;

public class CLIView {
    private final Controller controller;
    private final Scanner scanner = new Scanner(System.in);
    private static final double COST_PER_HOUR = 1.2;

    public CLIView(Controller controller) {
        this.controller = controller;
    }

    public void run() {
        printWelcome();
        boolean running = true;
        while (running) {
            System.out.print("\n> ");
            String line = scanner.nextLine().trim();
            if (line.isEmpty()) continue;

            String[] parts = line.split("\\s+");
            String cmd = parts[0].toLowerCase();

            try {
                switch (cmd) {
                    case "help":
                        printHelp();
                        break;
                    case "quit":
                        running = false;
                        break;
                    case "compute":
                        if (parts.length < 2) {
                            System.out.println("Usage: compute <instanceId>");
                            break;
                        }
                        handleCompute(parts[1]);
                        break;
                    case "increase":
                        if (parts.length < 3) {
                            System.out.println("Usage: increase <instanceId> <delta>");
                            break;
                        }
                        handleIncrease(parts[1], Integer.parseInt(parts[2]));
                        break;
                    case "allocate":
                        if (parts.length < 5) {
                            System.out.println("Usage: allocate <employmentId> <teachingId> <instanceId> <period>");
                            break;
                        }
                        handleAllocate(parts[1], Integer.parseInt(parts[2]), parts[3], parts[4]);
                        break;
                    case "deallocate":
                        if (parts.length < 4) {
                            System.out.println("Usage: deallocate <employmentId> <teachingId> <instanceId>");
                            break;
                        }
                        handleDeallocate(parts[1], Integer.parseInt(parts[2]), parts[3]);
                        break;
                    case "addexercise":
                        if (parts.length < 3) {
                            System.out.println("Usage: addexercise <instanceId> <personId>");
                            break;
                        }
                        handleAddExercise(parts[1], Integer.parseInt(parts[2]));
                        break;
                    case "showexercise":
                        if (parts.length < 2) {
                            System.out.println("Usage: showexercise <instanceId>");
                            break;
                        }
                        handleShowExercise(parts[1]);
                        break;
                    default:
                        System.out.println("Unknown command. Type 'help' to see available commands.");
                }
            } catch (NumberFormatException nfe) {
                System.out.println("Number parsing error: " + nfe.getMessage());
            } catch (Exception e) {
                System.out.println("ERROR: " + e.getMessage());
            }
        }
    }

    private void printWelcome() {
        System.out.println("Type 'help' to see available commands.");
    }

    private void printHelp() {
        System.out.println("Available commands:");
        System.out.println("  help                            : Show this help");
        System.out.println("  quit                            : Exit");
        System.out.println("  compute <instanceId>            : Compute planned and actual teaching cost (KSEK) for the instance");
        System.out.println("  increase <instanceId> <delta>   : Increase number of students for the instance by delta");
        System.out.println("  allocate <employmentId> <teachingId> <instanceId> <period>");
        System.out.println("                                  : Allocate a teaching activity to a teacher");
        System.out.println("  deallocate <employmentId> <teachingId> <instanceId>");
        System.out.println("                                  : Deallocate a teaching activity from a teacher");
        System.out.println("  addexercise <instanceId> <personId>");
        System.out.println("                                  : Add 'Exercise' activity to the instance and allocate to personId");
        System.out.println("  showexercise <instanceId>       : Show exercise allocations for the instance");
    }

    private void handleCompute(String instanceId) throws Exception {
        CourseCostDTO cost = controller.computeCourseCost(instanceId);
        if (cost == null) {
            System.out.println("Course instance not found: " + instanceId);
            return;
        }
        System.out.println("Course Code\tInstance\tPeriod\tPlanned Cost (KSEK)\tActual Cost (KSEK)");
        System.out.printf("%s\t%s\t%s\t%.1f\t%.1f%n",
                cost.courseCode,
                cost.instanceId,
                cost.period,
                cost.plannedHours * COST_PER_HOUR,
                cost.actualHours * COST_PER_HOUR
        );
    }

    private void handleIncrease(String instanceId, int delta) throws Exception {
        controller.increaseStudents(instanceId, delta);
        System.out.println("Student count updated for " + instanceId);
    }

    private void handleAllocate(String employmentId, int teachingId, String instanceId, String period) throws Exception {
        controller.allocateTeacher(employmentId, teachingId, instanceId, period);
        System.out.println("Allocation successful.");
    }

    private void handleDeallocate(String employmentId, int teachingId, String instanceId) throws Exception {
        controller.deallocateTeacher(employmentId, teachingId, instanceId);
        System.out.println("Deallocation successful.");
    }

    private void handleAddExercise(String instanceId, int personId) throws Exception {
        controller.addExerciseActivity(instanceId, personId);
        System.out.println("Exercise activity added and allocated to person id " + personId);
    }

    private void handleShowExercise(String instanceId) throws Exception {
        List<AllocationDTO> rows = controller.readExerciseAllocation(instanceId);
        if (rows == null || rows.isEmpty()) {
            System.out.println("No Exercise allocation found for " + instanceId);
            return;
        }
        System.out.println("CourseCode - CourseName, InstanceId, TeacherEmploymentId");
        for (AllocationDTO r : rows) {
            System.out.println(r.courseCode + " - " + r.courseName + ", " + r.instanceId + ", Teacher: " + r.employmentId);
        }
    }
}
