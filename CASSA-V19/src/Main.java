import gui.FinestraPrincipale; // Modificato per importare il contenitore principale
import javax.swing.*;
import javax.swing.plaf.ColorUIResource;
import java.awt.*;

public class Main {
    public static void main(String[] args) {

        try {
            // 1. Carichiamo il tema Nimbus di base (che ha già bordi smussati e animazioni)
            for (UIManager.LookAndFeelInfo info : UIManager.getInstalledLookAndFeels()) {
                if ("Nimbus".equals(info.getName())) {
                    UIManager.setLookAndFeel(info.getClassName());
                    break;
                }
            }

            // 2. INIEZIONE DI STILE MODERNO (Senza librerie esterne)
            // Cambiamo il font di sistema a tutto il programma (stile Windows 11)
            UIManager.put("defaultFont", new Font("Segoe UI", Font.PLAIN, 15));

            // Colori "Flat" e minimalisti per togliere l'effetto 3D/Plastica
            UIManager.put("control", new ColorUIResource(245, 246, 250)); // Sfondo delle finestre (grigio nuvola)
            UIManager.put("nimbusBase", new ColorUIResource(41, 128, 185)); // Colore primario (blu moderno) per le barre
            UIManager.put("nimbusFocus", new ColorUIResource(184, 207, 229)); // Colore del bordo quando clicchi
            UIManager.put("nimbusLightBackground", new ColorUIResource(255, 255, 255)); // Sfondo bianco puro per tabelle e caselle di testo

            // Modernizzazione delle Tabelle (es. storico e statistiche)
            UIManager.put("Table.rowHeight", 28); // Righe più alte e ariose
            UIManager.put("Table.showGrid", false); // Niente griglia incrociata anni 90
            UIManager.put("Table.alternateRowColor", new ColorUIResource(245, 246, 250)); // Effetto "Zebrato" moderno

            // Rende le finestre di popup (es. JOptionPane) senza bordoni pesanti
            UIManager.put("OptionPane.background", new ColorUIResource(255, 255, 255));

        } catch (Exception e) {
            System.out.println("Errore di caricamento grafica: " + e.getMessage());
        }

        // 3. Avvia la nuova architettura a singola finestra (Single Page Application)
        SwingUtilities.invokeLater(() -> {
            FinestraPrincipale app = new FinestraPrincipale();
            app.setVisible(true);
        });
    }
}