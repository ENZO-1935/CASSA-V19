package gui;

import dao.DatabaseManager;
import dao.ProdottoDAO;
import model.Prodotto;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.List;

public class PopupModificaProdotti extends JDialog {

    private JTable tabella;
    private DefaultTableModel model;
    private JTextField txtNome;
    private JTextField txtPrezzo;
    private JRadioButton radioCibo;
    private JRadioButton radioBevanda;
    private int idSelezionato = -1;
    private ProdottoDAO prodottoDAO;

    public PopupModificaProdotti(Frame parent) {
        super(parent, "Gestione e Modifica Listino", true); // "true" blocca l'app finché non lo chiudi
        setSize(750, 550);
        setLocationRelativeTo(parent);
        setLayout(new BorderLayout(10, 10));
        getContentPane().setBackground(new Color(245, 246, 250));

        prodottoDAO = new ProdottoDAO();

        // --- TITOLO ---
        JLabel lblTitolo = new JLabel("Modifica o Elimina Prodotti", JLabel.CENTER);
        lblTitolo.setFont(new Font("Segoe UI", Font.BOLD, 20));
        lblTitolo.setBorder(BorderFactory.createEmptyBorder(15, 0, 10, 0));
        add(lblTitolo, BorderLayout.NORTH);

        // --- TABELLA CENTRALE ---
        String[] colonne = {"ID", "Nome Prodotto", "Prezzo", "Categoria"};
        model = new DefaultTableModel(colonne, 0) {
            @Override
            public boolean isCellEditable(int row, int column) { return false; }
        };

        tabella = new JTable(model);
        tabella.setFont(new Font("Segoe UI", Font.PLAIN, 15));
        tabella.setRowHeight(28);
        tabella.getTableHeader().setFont(new Font("Segoe UI", Font.BOLD, 15));
        tabella.getColumnModel().getColumn(0).setMaxWidth(50); // Colonna ID stretta

        JScrollPane scrollPane = new JScrollPane(tabella);
        scrollPane.setBorder(BorderFactory.createEmptyBorder(0, 20, 0, 20));
        add(scrollPane, BorderLayout.CENTER);

        // Quando clicchi su una riga della tabella, riempie i campi di modifica
        tabella.getSelectionModel().addListSelectionListener(e -> riempiCampiDaTabella());

        // --- PANNELLO INFERIORE (Campi di Modifica) ---
        JPanel panelSud = new JPanel(new BorderLayout());
        panelSud.setBackground(new Color(245, 246, 250));
        panelSud.setBorder(BorderFactory.createEmptyBorder(15, 20, 15, 20));

        // Griglia per Nome e Prezzo
        JPanel panelInput = new JPanel(new GridLayout(2, 2, 10, 10));
        panelInput.setBackground(new Color(245, 246, 250));

        panelInput.add(new JLabel("Nome Prodotto:"));
        txtNome = new JTextField();
        txtNome.setFont(new Font("Segoe UI", Font.PLAIN, 15));
        panelInput.add(txtNome);

        panelInput.add(new JLabel("Prezzo (€):"));
        txtPrezzo = new JTextField();
        txtPrezzo.setFont(new Font("Segoe UI", Font.PLAIN, 15));
        panelInput.add(txtPrezzo);

        // Selettore Categoria
        JPanel panelRadio = new JPanel(new FlowLayout(FlowLayout.LEFT));
        panelRadio.setBackground(new Color(245, 246, 250));
        radioCibo = new JRadioButton("Cibo");
        radioBevanda = new JRadioButton("Bevanda");
        radioCibo.setBackground(new Color(245, 246, 250));
        radioBevanda.setBackground(new Color(245, 246, 250));
        ButtonGroup bg = new ButtonGroup();
        bg.add(radioCibo);
        bg.add(radioBevanda);
        panelRadio.add(new JLabel("Categoria: "));
        panelRadio.add(radioCibo);
        panelRadio.add(radioBevanda);

        // Pulsanti Salva / Elimina
        JPanel panelPulsanti = new JPanel(new FlowLayout(FlowLayout.RIGHT, 15, 0));
        panelPulsanti.setBackground(new Color(245, 246, 250));

        BottoneModerno btnElimina = new BottoneModerno("Elimina Prodotto", new Color(231, 76, 60), 10);
        btnElimina.setPreferredSize(new Dimension(150, 40));
        btnElimina.addActionListener(e -> eliminaProdotto());

        BottoneModerno btnSalva = new BottoneModerno("Salva Modifiche", new Color(39, 174, 96), 10);
        btnSalva.setPreferredSize(new Dimension(150, 40));
        btnSalva.addActionListener(e -> aggiornaProdotto());

        panelPulsanti.add(btnElimina);
        panelPulsanti.add(btnSalva);

        // Assemblo la parte sud
        JPanel wrapperSud = new JPanel(new BorderLayout(0, 10));
        wrapperSud.setBackground(new Color(245, 246, 250));
        wrapperSud.add(panelInput, BorderLayout.NORTH);
        wrapperSud.add(panelRadio, BorderLayout.CENTER);
        wrapperSud.add(panelPulsanti, BorderLayout.SOUTH);

        panelSud.add(wrapperSud, BorderLayout.CENTER);
        add(panelSud, BorderLayout.SOUTH);

        caricaProdotti();
    }

    private void caricaProdotti() {
        model.setRowCount(0);
        List<Prodotto> lista = prodottoDAO.ottieniTuttiProdotti();
        for (Prodotto p : lista) {
            String categoria = (p.getIdGruppo() == 1) ? "Cibo" : "Bevanda";
            model.addRow(new Object[]{p.getId(), p.getNome(), String.format("%.2f", p.getPrezzo()), categoria});
        }
        svuotaCampi();
    }

    private void riempiCampiDaTabella() {
        int riga = tabella.getSelectedRow();
        if (riga >= 0) {
            idSelezionato = (int) model.getValueAt(riga, 0);
            txtNome.setText((String) model.getValueAt(riga, 1));
            String prezzoStr = (String) model.getValueAt(riga, 2);
            txtPrezzo.setText(prezzoStr.replace(",", ".")); // formatto per i calcoli

            String categoria = (String) model.getValueAt(riga, 3);
            if (categoria.equals("Cibo")) {
                radioCibo.setSelected(true);
            } else {
                radioBevanda.setSelected(true);
            }
        }
    }

    private void svuotaCampi() {
        idSelezionato = -1;
        txtNome.setText("");
        txtPrezzo.setText("");
        radioCibo.setSelected(false);
        radioBevanda.setSelected(false);
        tabella.clearSelection();
    }

    private void aggiornaProdotto() {
        if (idSelezionato == -1) {
            JOptionPane.showMessageDialog(this, "Seleziona prima un prodotto dalla tabella.", "Attenzione", JOptionPane.WARNING_MESSAGE);
            return;
        }

        try {
            String nuovoNome = txtNome.getText().trim();
            double nuovoPrezzo = Double.parseDouble(txtPrezzo.getText().replace(",", "."));
            int nuovoGruppo = radioCibo.isSelected() ? 1 : 2;

            try (Connection conn = DatabaseManager.connetti();
                 PreparedStatement pstmt = conn.prepareStatement("UPDATE prodotto SET nome = ?, prezzo = ?, id_gruppo = ? WHERE id = ?")) {
                pstmt.setString(1, nuovoNome);
                pstmt.setDouble(2, nuovoPrezzo);
                pstmt.setInt(3, nuovoGruppo);
                pstmt.setInt(4, idSelezionato);
                pstmt.executeUpdate();

                JOptionPane.showMessageDialog(this, "Prodotto aggiornato correttamente!");
                caricaProdotti();
            }
        } catch (NumberFormatException ex) {
            JOptionPane.showMessageDialog(this, "Prezzo non valido.", "Errore", JOptionPane.ERROR_MESSAGE);
        } catch (SQLException ex) {
            JOptionPane.showMessageDialog(this, "Errore DB: " + ex.getMessage(), "Errore", JOptionPane.ERROR_MESSAGE);
        }
    }

    private void eliminaProdotto() {
        if (idSelezionato == -1) {
            JOptionPane.showMessageDialog(this, "Seleziona un prodotto da eliminare.", "Attenzione", JOptionPane.WARNING_MESSAGE);
            return;
        }

        int conferma = JOptionPane.showConfirmDialog(this, "Sei sicuro di voler eliminare questo prodotto?", "Conferma", JOptionPane.YES_NO_OPTION);
        if (conferma == JOptionPane.YES_OPTION) {
            try (Connection conn = DatabaseManager.connetti();
                 PreparedStatement pstmt = conn.prepareStatement("DELETE FROM prodotto WHERE id = ?")) {
                pstmt.setInt(1, idSelezionato);
                pstmt.executeUpdate();
                caricaProdotti();
            } catch (SQLException ex) {
                JOptionPane.showMessageDialog(this, "Errore DB: " + ex.getMessage(), "Errore", JOptionPane.ERROR_MESSAGE);
            }
        }
    }
}