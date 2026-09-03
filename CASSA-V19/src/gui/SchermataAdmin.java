package gui;

import dao.ProdottoDAO;
import model.Prodotto;

import javax.swing.*;
import java.awt.*;

public class SchermataAdmin extends JFrame {
    private JTextField txtNome;
    private JTextField txtPrezzo;
    private JButton btnSalva;
    private ProdottoDAO prodottoDAO;

    public SchermataAdmin() {
        prodottoDAO = new ProdottoDAO();

        setTitle("Pannello Amministrazione - Inserimento Prodotti");
        setSize(400, 200); // Leggermente più piccola visto che c'è un campo in meno
        setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
        setLayout(new GridLayout(3, 2, 10, 10)); // Ridotta a 3 righe

        // Margini interni
        ((JComponent) getContentPane()).setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));

        // Creazione campi di input
        add(new JLabel("Nome Prodotto: "));
        txtNome = new JTextField();
        add(txtNome);

        add(new JLabel("Prezzo: "));
        txtPrezzo = new JTextField();
        add(txtPrezzo);

        // Bottone di salvataggio
        add(new JLabel("")); // Spazio vuoto per allineare il bottone
        btnSalva = new JButton("Salva nel Listino");
        add(btnSalva);

        // Ascoltatore eventi per il clic sul bottone
        btnSalva.addActionListener(e -> salvaDati());

        setLocationRelativeTo(null);
    }

    private void salvaDati() {
        try {
            String nome = txtNome.getText().trim();
            if (nome.isEmpty()) {
                JOptionPane.showMessageDialog(this, "Inserisci un nome valido per il prodotto.", "Errore", JOptionPane.WARNING_MESSAGE);
                return;
            }

            // Sostituisce la virgola col punto per evitare crash sui decimali
            double prezzo = Double.parseDouble(txtPrezzo.getText().replace(",", "."));

            // Creazione oggetto prodotto senza scorte (passiamo 0 o valori di default)
            Prodotto nuovoProdotto = new Prodotto(0, 1, nome, prezzo, 0, false);

            // Salva fisicamente su SQLite
            prodottoDAO.inserisciProdotto(nuovoProdotto);

            JOptionPane.showMessageDialog(this, "Prodotto salvato con successo nel database!");

            // Svuota i campi per il prossimo inserimento
            txtNome.setText("");
            txtPrezzo.setText("");

        } catch (NumberFormatException ex) {
            JOptionPane.showMessageDialog(this,
                    "Errore: Inserisci un valore numerico valido per il prezzo.",
                    "Errore di formattazione",
                    JOptionPane.ERROR_MESSAGE);
        }
    }
}