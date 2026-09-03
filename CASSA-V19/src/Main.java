import dao.DatabaseManager;
import gui.MenuPrincipale;
import javax.swing.SwingUtilities;

public class Main {
    public static void main(String[] args) {
        // 1. Assicura che il database e le tabelle esistano
        DatabaseManager.inizializzaDatabase();

        // 2. Avvia il Menu Principale
        SwingUtilities.invokeLater(() -> {
            MenuPrincipale menu = new MenuPrincipale();
            menu.setVisible(true);
        });
    }
}