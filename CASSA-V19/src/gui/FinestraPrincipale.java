package gui;

import javax.swing.*;
import java.awt.*;

public class FinestraPrincipale extends JFrame {
    private CardLayout gestorePagine;
    private JPanel contenitorePagine;

    public FinestraPrincipale() {
        setTitle("Cassa Automatica Sagra");
        setSize(1100, 750);
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setLocationRelativeTo(null);

        gestorePagine = new CardLayout();
        contenitorePagine = new JPanel(gestorePagine);

        // Aggiungiamo tutte le schermate assegnando i nomi esatti usati nel MenuPrincipale
        contenitorePagine.add(new MenuPrincipale(this), "HOME");
        contenitorePagine.add(new SchermataCassa(this), "CASSA");
        contenitorePagine.add(new SchermataAdmin(this), "ADMIN");
        contenitorePagine.add(new SchermataStatistiche(this), "STATISTICHE");
        contenitorePagine.add(new SchermataStoricoEventi(this), "STORICO");

        add(contenitorePagine);
        gestorePagine.show(contenitorePagine, "HOME"); // Parte dal menu
    }

    public void navigaA(String nomePagina) {
        gestorePagine.show(contenitorePagine, nomePagina);
    }
}