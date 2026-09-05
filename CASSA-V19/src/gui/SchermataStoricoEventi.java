package gui;

import dao.DatabaseManager;
import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.sql.*;

public class SchermataStoricoEventi extends JPanel {

    private DefaultTableModel model;
    private JTable tabella;
    private FinestraPrincipale mainFrame;

    public SchermataStoricoEventi(FinestraPrincipale main) {
        this.mainFrame = main;

        setLayout(new BorderLayout(10, 10));

        // --- BARRA SUPERIORE CON BOTTONE HOME E TITOLO ---
        JPanel panelNord = new JPanel(new BorderLayout(15, 0));
        panelNord.setBorder(BorderFactory.createEmptyBorder(15, 20, 10, 20));

        BottoneModerno btnHome = new BottoneModerno("◄ Torna alla Home", new Color(149, 165, 166), 15);
        btnHome.setPreferredSize(new Dimension(180, 45));
        btnHome.addActionListener(e -> mainFrame.navigaA("HOME"));

        JLabel lblTitolo = new JLabel("Archivio Storico Incassi ed Eventi", JLabel.CENTER);
        lblTitolo.setFont(new Font("Segoe UI", Font.BOLD, 22));

        panelNord.add(btnHome, BorderLayout.WEST);
        panelNord.add(lblTitolo, BorderLayout.CENTER);
        add(panelNord, BorderLayout.NORTH);

        // --- TABELLA CENTRALE ---
        String[] colonne = {"ID", "Nome Evento", "Data Chiusura", "Incasso Totale"};
        model = new DefaultTableModel(colonne, 0) {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;
            }
        };

        tabella = new JTable(model);
        tabella.setFont(new Font("Segoe UI", Font.PLAIN, 15));
        tabella.setRowHeight(28);
        tabella.getTableHeader().setFont(new Font("Segoe UI", Font.BOLD, 15));

        tabella.getColumnModel().getColumn(0).setMaxWidth(50);

        caricaDatiStorico();

        JScrollPane scrollPane = new JScrollPane(tabella);
        scrollPane.setBorder(BorderFactory.createEmptyBorder(10, 20, 10, 20));
        add(scrollPane, BorderLayout.CENTER);

        // --- PULSANTI IN BASSO ---
        JPanel panelBasso = new JPanel(new FlowLayout(FlowLayout.CENTER, 15, 15));

        BottoneModerno btnDettaglio = new BottoneModerno("Visualizza Scontrino", new Color(41, 128, 185), 15);
        btnDettaglio.setPreferredSize(new Dimension(200, 45));
        btnDettaglio.addActionListener(e -> apriDettaglioEvento());

        BottoneModerno btnElimina = new BottoneModerno("Elimina Evento", new Color(231, 76, 60), 15);
        btnElimina.setPreferredSize(new Dimension(160, 45));
        btnElimina.addActionListener(e -> eliminaEvento());

        BottoneModerno btnAggiorna = new BottoneModerno("Aggiorna", new Color(39, 174, 96), 15);
        btnAggiorna.setPreferredSize(new Dimension(130, 45));
        btnAggiorna.addActionListener(e -> caricaDatiStorico());

        panelBasso.add(btnDettaglio);
        panelBasso.add(btnElimina);
        panelBasso.add(btnAggiorna);
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