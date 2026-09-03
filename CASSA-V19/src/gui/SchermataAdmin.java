package gui;

import dao.ProdottoDAO;
import model.Prodotto;

import javax.swing.*;
import java.awt.*;

public class SchermataAdmin extends JFrame {
    private JTextField txtNome;
    private JTextField txtPrezzo;
    private JTextField txtQuantita;
    private JButton btnSalva;
    private ProdottoDAO prodottoDAO;

    public SchermataAdmin() {
        prodottoDAO = new ProdottoDAO();

        setTitle("Pannello Amministrazione - Inserimento Prodotti");
        setSize(450, 250);
        setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE); // Chiude solo questa finestra
        setLayout(new GridLayout(4, 2, 10, 10)); // Layout a griglia: 4 righe, 2 colonne

        // Margini interni
        ((JComponent) getContentPane()).setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));

        // Creazione campi di input
        add(new JLabel("Nome Prodotto (es. Panino):"));
        txtNome = new JTextField();
        add(txtNome);

        add(new JLabel("Prezzo (es. 5.50):"));
        txtPrezzo = new JTextField();
        add(txtPrezzo);

        add(new JLabel("Scorte disponibili (es. 100):"));
        txtQuantita = new JTextField();
        add(txtQuantita);

        // Bottone di salvataggio
        add(new JLabel("")); // Spazio vuoto per allineare il bottone a destra
        btnSalva = new JButton("Salva nel Listino");
        add(btnSalva);

        // Ascoltatore eventi per il clic sul bottone
        btnSalva.addActionListener(e -> salvaDati());

        setLocationRelativeTo(null); // Centra la finestra al centro dello schermo
    }

    private void salvaDati() {
        try {
            String nome = txtNome.getText();
            // Sostituisce la virgola col punto per evitare crash sui decimali
            double prezzo = Double.parseDouble(txtPrezzo.getText().replace(",", "."));
            int quantita = Integer.parseInt(txtQuantita.getText());

            // Crea l'oggetto (0 per ID autoincrementante, 1 per gruppo default, false per sconti)
            Prodotto nuovoProdotto = new Prodotto(0, 1, nome, prezzo, quantita, false);

            // Salva fisicamente su SQLite
            prodottoDAO.inserisciProdotto(nuovoProdotto);

            JOptionPane.showMessageDialog(this, "Prodotto salvato con successo nel database!");

            // Svuota i campi per il prossimo inserimento
            txtNome.setText("");
            txtPrezzo.setText("");
            txtQuantita.setText("");

        } catch (NumberFormatException ex) {
            JOptionPane.showMessageDialog(this,
                    "Errore: Inserisci numeri validi per prezzo e quantità.",
                    "Errore di formattazione",
                    JOptionPane.ERROR_MESSAGE);
        }
    }
}