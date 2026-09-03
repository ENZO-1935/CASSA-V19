package gui;

import javax.swing.*;
import java.awt.*;

public class MenuPrincipale extends JFrame {

    public MenuPrincipale() {
        setTitle("Dashboard - Gestione Sagra");
        setSize(400, 300);
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE); // Chiude l'intero programma se chiudi il menu
        setLayout(new GridLayout(3, 1, 15, 15));

        // Aggiunge un po' di margine ai bordi della finestra
        ((JComponent) getContentPane()).setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20));

        // Pulsante 1: Cassa
        JButton btnCassa = new JButton("1. Apri Cassa (Modalità Vendita)");
        btnCassa.setFont(new Font("Arial", Font.BOLD, 18));
        btnCassa.setBackground(new Color(173, 216, 230)); // Azzurro chiaro
        btnCassa.addActionListener(e -> {
            SchermataCassa cassa = new SchermataCassa();
            cassa.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE); // Chiude solo la cassa
            cassa.setVisible(true);
        });

        // Pulsante 2: Amministrazione
        JButton btnAdmin = new JButton("2. Amministrazione Listino");
        btnAdmin.setFont(new Font("Arial", Font.BOLD, 16));
        btnAdmin.addActionListener(e -> {
            SchermataAdmin admin = new SchermataAdmin();
            admin.setVisible(true);
        });

        // Pulsante 3: Statistiche e Chiusura Cassa (Sbloccato)
        JButton btnStatistiche = new JButton("3. Resoconto e Statistiche");
        btnStatistiche.setFont(new Font("Arial", Font.BOLD, 16));
        btnStatistiche.setBackground(new Color(255, 228, 181)); // Giallo sabbia
        btnStatistiche.addActionListener(e -> {
            SchermataStatistiche resoconto = new SchermataStatistiche();
            resoconto.setVisible(true);
        });

        // Aggiunta dei pulsanti alla finestra
        add(btnCassa);
        add(btnAdmin);
        add(btnStatistiche);

        setLocationRelativeTo(null); // Centra la finestra sullo schermo
    }
}