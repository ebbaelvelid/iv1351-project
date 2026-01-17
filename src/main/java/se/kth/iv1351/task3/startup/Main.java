package startup;

import controller.Controller;
import view.CLIView;

public class Main {
    public static void main(String[] args) {
        Controller controller = new Controller();
        CLIView view = new CLIView(controller);
        view.run();
    }
}
