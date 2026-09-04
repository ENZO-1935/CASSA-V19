package gui;

import dao.DatabaseManager;
import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.sql.*;

public class SchermataStoricoEventi extends JFrame {

    private DefaultTableModel model;
    private JTable tabella;

    public SchermataStoricoEventi() {
        setTitle("Storico Eventi e Sagre Passate");
        setSize(850, 500);
        setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
        setLocationRelativeTo(null);
        setLayout(new BorderLayout(10, 10));

        JLabel lblTitolo = new JLabel("Archivio Storico Incassi ed Eventi", JLabel.CENTER);
        lblTitolo.setFont(new Font("Arial", Font.BOLD, 20));
        lblTitolo.setBorder(BorderFactory.createEmptyBorder(15, 0, 10, 0));
        add(lblTitolo, BorderLayout.NORTH);

        String[] colonne = {"ID", "Nome Evento", "Data Chiusura", "Incasso Totale"};
        model = new DefaultTableModel(colonne, 0) {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;
            }
        };

        tabella = new JTable(model);
        tabella.setFont(new Font("Arial", Font.PLAIN, 14));
        tabella.setRowHeight(25);
        tabella.getTableHeader().setFont(new Font("Arial", Font.BOLD, 14));

        tabella.getColumnModel().getColumn(0).setMaxWidth(50);

        caricaDatiStorico();

        JScrollPane scrollPane = new JScrollPane(tabella);
        scrollPane.setBorder(BorderFactory.createEmptyBorder(10, 20, 10, 20));
        add(scrollPane, BorderLayout.CENTER);

        // Pannello Pulsanti in basso
        JPanel panelBasso = new JPanel(new FlowLayout(FlowLayout.CENTER, 15, 15));

        JButton btnDettaglio = new JButton("Visualizza Scontrino");
        btnDettaglio.setFont(new Font("Arial", Font.BOLD, 13));
        btnDettaglio.setBackground(new Color(40, 110, 180));
        btnDettaglio.setForeground(Color.WHITE);
        btnDettaglio.setFocusPainted(false);
        btnDettaglio.setPreferredSize(new Dimension(180, 40));
        btnDettaglio.addActionListener(e -> apriDettaglioEvento());

        JButton btnElimina = new JButton("Elimina Evento");
        btnElimina.setFont(new Font("Arial", Font.BOLD, 13));
        btnElimina.setBackground(new Color(180, 50, 50));
        btnElimina.setForeground(Color.WHITE);
        btnElimina.setFocusPainted(false);
        btnElimina.setPreferredSize(new Dimension(150, 40));
        btnElimina.addActionListener(e -> eliminaEvento());

        JButton btnAggiorna = new JButton("Aggiorna");
        btnAggiorna.setFont(new Font("Arial", Font.BOLD, 13));
        btnAggiorna.setBackground(new Color(70, 130, 180));
        btnAggiorna.setForeground(Color.WHITE);
        btnAggiorna.setFocusPainted(false);
        btnAggiorna.setPreferredSize(new Dimension(120, 40));
        btnAggiorna.addActionListener(e -> caricaDatiStorico());

        JButton btnChiudi = new JButton("Chiudi");
        btnChiudi.setFont(new Font("Arial", Font.BOLD, 13));
        btnChiudi.setBackground(new Color(105, 105, 105));
        btnChiudi.setForeground(Color.WHITE);
        btnChiudi.setFocusPainted(false);
        btnChiudi.setPreferredSize(new Dimension(120, 40));
        btnChiudi.addActionListener(e -> dispose());

        panelBasso.add(btnDettaglio);
        panelBasso.add(btnElimina);
        panelBasso.add(btnAggiorna);
        panelBasso.add(btnChiudi);
        add(panelBasso, BorderLayout.SOUTH);
    }

    private void caricaDatiStorico() {
        model.setRowCount(0);
        String query = "SELECT id, nome_evento, data_chiusura, incasso_totale FROM eventi_archiviati ORDER BY id DESC";

        try (Connection conn = DatabaseManager.connetti();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(query)) {

            while (rs.next()) {
                int id = rs.getInt("id");
                String nome = rs.getString("nome_evento");
                String data = rs.getString("data_chiusura");
                double incasso = rs.getDouble("incasso_totale");

                model.addRow(new Object[]{id, nome, data, String.format("€ %.2f", incasso)});
            }

        } catch (SQLException e) {
            System.out.println("Errore caricamento storico eventi: " + e.getMessage());
        }
    }

    private void eliminaEvento() {
        int rigaSelezionata = tabella.getSelectedRow();
        if (rigaSelezionata == -1) {
            JOptionPane.showMessageDialog(this, "Seleziona un evento dalla tabella prima di cliccare su Elimina.", "Attenzione", JOptionPane.WARNING_MESSAGE);
            return;
        }

        int idEvento = (int) model.getValueAt(rigaSelezionata, 0);
        String nomeEvento = (String) model.getValueAt(rigaSelezionata, 1);

        int conferma = JOptionPane.showConfirmDialog(this,
                "Sei sicuro di voler eliminare DEFINITIVAMENTE l'evento '" + nomeEvento + "'?\n\nL'operazione è irreversibile e i dati andranno persi.",
                "Conferma Eliminazione",
                JOptionPane.YES_NO_OPTION,
                JOptionPane.ERROR_MESSAGE);

        if (conferma == JOptionPane.YES_OPTION) {
            try (Connection conn = DatabaseManager.connetti();
                 PreparedStatement pstmt = conn.prepareStatement("DELETE FROM eventi_archiviati WHERE id = ?")) {
                pstmt.setInt(1, idEvento);
                pstmt.executeUpdate();

                caricaDatiStorico(); // Ricarica la tabella per mostrare la modifica
                JOptionPane.showMessageDialog(this, "Evento eliminato con successo.", "Eliminazione completata", JOptionPane.INFORMATION_MESSAGE);
            } catch (SQLException ex) {
                JOptionPane.showMessageDialog(this, "Errore durante l'eliminazione: " + ex.getMessage(), "Errore", JOptionPane.ERROR_MESSAGE);
            }
        }
    }

    private void apriDettaglioEvento() {
        int rigaSelezionata = tabella.getSelectedRow();
        if (rigaSelezionata == -1) {
            JOptionPane.showMessageDialog(this, "Seleziona un evento dalla tabella per visualizzarne lo scontrino.", "Attenzione", JOptionPane.WARNING_MESSAGE);
            return;
        }

        int idEvento = (int) model.getValueAt(rigaSelezionata, 0);

        String query = "SELECT id, nome_evento, data_chiusura, incasso_totale, dettagli_vendite FROM eventi_archiviati WHERE id = ?";
        try (Connection conn = DatabaseManager.connetti();
             PreparedStatement pstmt = conn.prepareStatement(query)) {
            pstmt.setInt(1, idEvento);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    String nome = rs.getString("nome_evento");
                    String data = rs.getString("data_chiusura");
                    double incasso = rs.getDouble("incasso_totale");
                    String dettagli = rs.getString("dettagli_vendite");

                    new SchermataDettaglioEvento(idEvento, nome, data, incasso, dettagli).setVisible(true);
                }
            }
        } catch (SQLException e) {
            JOptionPane.showMessageDialog(this, "Errore nel caricamento dei dettagli dell'evento: " + e.getMessage(), "Errore", JOptionPane.ERROR_MESSAGE);
        }
    }
}