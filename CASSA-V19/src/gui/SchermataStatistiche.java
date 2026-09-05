package gui;

import dao.OrdineDAO;
import dao.DatabaseManager;
import hardware.GestoreStampa;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.sql.*;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class SchermataStatistiche extends JPanel {

    private JLabel lblTotaleIncasso;
    private DefaultTableModel modelProdotti;
    private OrdineDAO ordineDAO;
    private FinestraPrincipale mainFrame;

    public SchermataStatistiche(FinestraPrincipale main) {
        this.mainFrame = main;
        ordineDAO = new OrdineDAO();

        setLayout(new BorderLayout(10, 10));

        // --- BARRA SUPERIORE CON BOTTONE HOME E TITOLI ---
        JPanel panelNord = new JPanel(new BorderLayout(15, 0));
        panelNord.setBorder(BorderFactory.createEmptyBorder(15, 20, 10, 20));

        BottoneModerno btnHome = new BottoneModerno("◄ Torna alla Home", new Color(149, 165, 166), 15);
        btnHome.setPreferredSize(new Dimension(180, 45));
        btnHome.addActionListener(e -> mainFrame.navigaA("HOME"));

        JPanel panelTitoli = new JPanel(new GridLayout(2, 1, 5, 5));

        JLabel lblTitolo = new JLabel("Statistiche, Stampa e Chiusura Evento", JLabel.CENTER);
        lblTitolo.setFont(new Font("Segoe UI", Font.BOLD, 22));
        panelTitoli.add(lblTitolo);

        lblTotaleIncasso = new JLabel("Incasso Totale Attuale: € 0.00", JLabel.CENTER);
        lblTotaleIncasso.setFont(new Font("Segoe UI", Font.BOLD, 18));
        lblTotaleIncasso.setForeground(new Color(39, 174, 96));
        panelTitoli.add(lblTotaleIncasso);

        panelNord.add(btnHome, BorderLayout.WEST);
        panelNord.add(panelTitoli, BorderLayout.CENTER);
        add(panelNord, BorderLayout.NORTH);

        // --- TABELLA CENTRALE ---
        String[] colonne = {"Prodotto", "Quantità Totale", "Incasso Generato"};
        modelProdotti = new DefaultTableModel(colonne, 0) {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;
            }
        };

        JTable tabella = new JTable(modelProdotti);
        tabella.setFont(new Font("Segoe UI", Font.PLAIN, 15));
        tabella.setRowHeight(28);
        tabella.getTableHeader().setFont(new Font("Segoe UI", Font.BOLD, 15));

        JScrollPane scrollPane = new JScrollPane(tabella);
        scrollPane.setBorder(BorderFactory.createEmptyBorder(10, 20, 10, 20));
        add(scrollPane, BorderLayout.CENTER);

        // --- PULSANTI IN BASSO ---
        JPanel panelSud = new JPanel(new FlowLayout(FlowLayout.CENTER, 15, 15));

        BottoneModerno btnAggiorna = new BottoneModerno("Aggiorna", new Color(41, 128, 185), 15);
        btnAggiorna.setPreferredSize(new Dimension(130, 45));
        btnAggiorna.addActionListener(e -> caricaDati());

        BottoneModerno btnStampa = new BottoneModerno("Stampa Scontrino Chiusura", new Color(52, 73, 94), 15);
        btnStampa.setPreferredSize(new Dimension(240, 45));
        btnStampa.addActionListener(e -> stampaChiusura());

        BottoneModerno btnArchivia = new BottoneModerno("Archivia & Azzera Cassa", new Color(231, 76, 60), 15);
        btnArchivia.setPreferredSize(new Dimension(220, 45));
        btnArchivia.addActionListener(e -> archiviaEAzzeraCassa());

        panelSud.add(btnAggiorna);
        panelSud.add(btnStampa);
        panelSud.add(btnArchivia);
        add(panelSud, BorderLayout.SOUTH);

        // --- IL TRUCCO DELL'AGGIORNAMENTO AUTOMATICO ---
        // Scatta da solo appena la pagina viene mostrata
        this.addComponentListener(new java.awt.event.ComponentAdapter() {
            @Override
            public void componentShown(java.awt.event.ComponentEvent e) {
                caricaDati();
            }
        });

        caricaDati(); // Caricamento iniziale
    }

    private void caricaDati() {
        modelProdotti.setRowCount(0);
        double incassoTotale = ordineDAO.calcolaIncassoTotale();
        lblTotaleIncasso.setText(String.format("Incasso Totale Attuale: € %.2f", incassoTotale));

        Map<String, double[]> report = ordineDAO.generaReportArticoli();
        for (Map.Entry<String, double[]> entry : report.entrySet()) {
            String nome = entry.getKey();
            int qta = (int) entry.getValue()[0];
            double incasso = entry.getValue()[1];
            modelProdotti.addRow(new Object[]{nome, qta, String.format("€ %.2f", incasso)});
        }
    }

    private void stampaChiusura() {
        try {
            GestoreStampa.stampaRiepilogoChiusura();
            JOptionPane.showMessageDialog(this, "Stampa scontrino di chiusura inviata con successo!", "Stampa", JOptionPane.INFORMATION_MESSAGE);
        } catch (Exception ex) {
            JOptionPane.showMessageDialog(this, "Errore durante la stampa: " + ex.getMessage(), "Errore Stampa", JOptionPane.ERROR_MESSAGE);
        }
    }

    private void archiviaEAzzeraCassa() {
        double incassoTotaleCorrente = ordineDAO.calcolaIncassoTotale();

        if (incassoTotaleCorrente <= 0) {
            JOptionPane.showMessageDialog(this, "Non ci sono vendite registrate da archiviare.", "Attenzione", JOptionPane.WARNING_MESSAGE);
            return;
        }

        List<String> opzioni = new ArrayList<>();
        opzioni.add("--- CREA NUOVO EVENTO ---");
        Map<String, Integer> eventiEsistenti = new LinkedHashMap<>();

        try (Connection conn = DatabaseManager.connetti();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT id, nome_evento FROM eventi_archiviati ORDER BY id DESC")) {
            while (rs.next()) {
                String nome = rs.getString("nome_evento");
                int id = rs.getInt("id");
                eventiEsistenti.put(nome, id);
                opzioni.add(nome);
            }
        } catch (SQLException ignored) {}

        String scelta = (String) JOptionPane.showInputDialog(this,
                "Seleziona l'evento a cui aggiungere l'incasso, oppure creane uno nuovo:",
                "Archiviazione Evento",
                JOptionPane.QUESTION_MESSAGE,
                null,
                opzioni.toArray(),
                opzioni.get(0));

        if (scelta == null) return;

        boolean isNuovo = scelta.equals("--- CREA NUOVO EVENTO ---");
        String nomeEventoFinale;
        int idEventoDaAggiornare = -1;

        if (isNuovo) {
            nomeEventoFinale = JOptionPane.showInputDialog(this, "Inserisci il nome del NUOVO evento (es. Sagra 2026):");
            if (nomeEventoFinale == null || nomeEventoFinale.trim().isEmpty()) return;
        } else {
            nomeEventoFinale = scelta;
            idEventoDaAggiornare = eventiEsistenti.get(scelta);
        }

        String dataOra = new SimpleDateFormat("dd/MM/yyyy HH:mm").format(new Date());
        StringBuilder nuovoScontrino = new StringBuilder();
        nuovoScontrino.append("[SESSIONE] Chiusura Cassa del ").append(dataOra).append("\n");

        Map<String, double[]> reportAttuale = ordineDAO.generaReportArticoli();
        for (Map.Entry<String, double[]> entry : reportAttuale.entrySet()) {
            nuovoScontrino.append(entry.getKey()).append(";")
                    .append((int) entry.getValue()[0]).append(";")
                    .append(entry.getValue()[1]).append("\n");
        }

        double incassoEsistente = 0.0;
        String dettagliDB = "";

        if (!isNuovo) {
            try (Connection conn = DatabaseManager.connetti();
                 PreparedStatement pstmt = conn.prepareStatement("SELECT incasso_totale, dettagli_vendite FROM eventi_archiviati WHERE id = ?")) {
                pstmt.setInt(1, idEventoDaAggiornare);
                ResultSet rs = pstmt.executeQuery();
                if (rs.next()) {
                    incassoEsistente = rs.getDouble("incasso_totale");
                    dettagliDB = rs.getString("dettagli_vendite");
                    if (dettagliDB == null) dettagliDB = "";
                }
            } catch (Exception e) {}
        }

        double incassoTotaleAggiornato = incassoEsistente + incassoTotaleCorrente;

        if (!dettagliDB.isEmpty() && !dettagliDB.startsWith("[SESSIONE]")) {
            dettagliDB = "[SESSIONE] Scontrini Precedenti\n" + dettagliDB;
        }

        String dettagliFinali;
        if (isNuovo) {
            dettagliFinali = nuovoScontrino.toString();
        } else {
            dettagliFinali = dettagliDB + (dettagliDB.endsWith("\n") ? "" : "\n") + "\n" + nuovoScontrino.toString();
        }

        try (Connection conn = DatabaseManager.connetti()) {
            if (isNuovo) {
                String sqlInsert = "INSERT INTO eventi_archiviati (nome_evento, incasso_totale, dettagli_vendite) VALUES (?, ?, ?)";
                try (PreparedStatement pstmt = conn.prepareStatement(sqlInsert)) {
                    pstmt.setString(1, nomeEventoFinale.trim());
                    pstmt.setDouble(2, incassoTotaleAggiornato);
                    pstmt.setString(3, dettagliFinali);
                    pstmt.executeUpdate();
                }
            } else {
                String sqlUpdate = "UPDATE eventi_archiviati SET incasso_totale = ?, dettagli_vendite = ? WHERE id = ?";
                try (PreparedStatement pstmt = conn.prepareStatement(sqlUpdate)) {
                    pstmt.setDouble(1, incassoTotaleAggiornato);
                    pstmt.setString(2, dettagliFinali);
                    pstmt.setInt(3, idEventoDaAggiornare);
                    pstmt.executeUpdate();
                }
            }

            try (Statement stmt = conn.createStatement()) {
                stmt.executeUpdate("DELETE FROM dettaglio_ordine");
                stmt.executeUpdate("DELETE FROM ordine");
            }

            JOptionPane.showMessageDialog(this,
                    "Cassa chiusa e scontrino salvato in: " + nomeEventoFinale + "\nLa cassa è azzerata e pronta.",
                    "Operazione completata",
                    JOptionPane.INFORMATION_MESSAGE);

            caricaDati(); // Ricarica la tabella ripulendola

        } catch (SQLException ex) {
            JOptionPane.showMessageDialog(this, "Errore durante l'archiviazione: " + ex.getMessage(), "Errore", JOptionPane.ERROR_MESSAGE);
        }
    }
}