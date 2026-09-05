package gui;

import javax.swing.*;
import javax.swing.table.DefaultTableCellRenderer;
import javax.swing.table.DefaultTableModel;
import java.awt.*;

public class SchermataDettaglioEvento extends JFrame { // Rimane JFrame perché è un popup!

    public SchermataDettaglioEvento(int idEvento, String nomeEvento, String dataChiusura, double incassoTotale, String dettagliVendite) {
        setTitle("Scontrino Chiusura Evento: " + nomeEvento);
        setSize(700, 520);
        setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE); // Si chiude solo lei, non tutta l'app
        setLocationRelativeTo(null); // Centra il popup sullo schermo
        setLayout(new BorderLayout(10, 10));

        // Sfondo moderno per il popup
        getContentPane().setBackground(new Color(245, 246, 250));

        JPanel panelNord = new JPanel(new GridLayout(3, 1, 5, 5));
        panelNord.setBackground(new Color(245, 246, 250));
        panelNord.setBorder(BorderFactory.createEmptyBorder(15, 20, 10, 20));

        JLabel lblTitolo = new JLabel("EVENTO: " + nomeEvento, JLabel.CENTER);
        lblTitolo.setFont(new Font("Segoe UI", Font.BOLD, 20)); // Font moderno
        panelNord.add(lblTitolo);

        JLabel lblData = new JLabel("Ultimo aggiornamento: " + dataChiusura, JLabel.CENTER);
        lblData.setFont(new Font("Segoe UI", Font.PLAIN, 15));
        panelNord.add(lblData);

        JLabel lblIncasso = new JLabel(String.format("Incasso Totale Unificato: € %.2f", incassoTotale), JLabel.CENTER);
        lblIncasso.setFont(new Font("Segoe UI", Font.BOLD, 18));
        lblIncasso.setForeground(new Color(39, 174, 96)); // Verde smeraldo moderno
        panelNord.add(lblIncasso);

        add(panelNord, BorderLayout.NORTH);

        boolean haDettagli = false;
        DefaultTableModel model = new DefaultTableModel(new String[]{"Descrizione", "Quantità", "Incasso"}, 0) {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;
            }
        };

        if (dettagliVendite != null && !dettagliVendite.trim().isEmpty()) {
            String[] righe = dettagliVendite.split("\n");
            for (String riga : righe) {
                if (riga.trim().isEmpty()) continue;

                if (riga.startsWith("[SESSIONE]")) {
                    String titoloSessione = riga.replace("[SESSIONE]", "").trim().toUpperCase();
                    model.addRow(new Object[]{"► " + titoloSessione, "-", "-"});
                    haDettagli = true;
                } else {
                    String[] parti = riga.split(";");
                    if (parti.length == 3) {
                        try {
                            String nome = parti[0];
                            String qta = parti[1];
                            double incasso = Double.parseDouble(parti[2]);
                            model.addRow(new Object[]{"    " + nome, qta, String.format("€ %.2f", incasso)});
                            haDettagli = true;
                        } catch (Exception ignored) {}
                    }
                }
            }
        }

        if (!haDettagli) {
            JPanel panelAvviso = new JPanel(new GridBagLayout());
            panelAvviso.setBackground(new Color(245, 246, 250));
            JLabel lblAvviso = new JLabel("<html><center><b>Dettaglio prodotti non disponibile</b><br><br>Questo evento è stato archiviato prima dell'aggiornamento.<br>Contiene unicamente il totale dell'incasso registrato.</center></html>", JLabel.CENTER);
            lblAvviso.setFont(new Font("Segoe UI", Font.PLAIN, 16));
            lblAvviso.setForeground(new Color(150, 40, 40));
            panelAvviso.add(lblAvviso);
            add(panelAvviso, BorderLayout.CENTER);
        } else {
            JTable tabella = new JTable(model);
            tabella.setFont(new Font("Segoe UI", Font.PLAIN, 15));
            tabella.setRowHeight(30); // Più respiro per le righe
            tabella.getTableHeader().setFont(new Font("Segoe UI", Font.BOLD, 15));
            tabella.setShowGrid(false); // Niente griglia per un look più pulito

            tabella.setDefaultRenderer(Object.class, new DefaultTableCellRenderer() {
                @Override
                public Component getTableCellRendererComponent(JTable table, Object value, boolean isSelected, boolean hasFocus, int row, int column) {
                    Component c = super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, column);
                    String nome = (String) table.getValueAt(row, 0);
                    if (nome != null && nome.startsWith("►")) {
                        c.setFont(new Font("Segoe UI", Font.BOLD, 15));
                        c.setBackground(new Color(230, 240, 250));
                        c.setForeground(new Color(41, 128, 185)); // Blu elegante per il divisore
                    } else {
                        c.setFont(new Font("Segoe UI", Font.PLAIN, 15));
                        c.setBackground(Color.WHITE);
                        c.setForeground(Color.BLACK);
                    }
                    if (isSelected) c.setBackground(new Color(184, 207, 229));
                    return c;
                }
            });

            JScrollPane scrollPane = new JScrollPane(tabella);
            scrollPane.setBorder(BorderFactory.createEmptyBorder(10, 20, 10, 20));
            scrollPane.getViewport().setBackground(Color.WHITE);
            add(scrollPane, BorderLayout.CENTER);
        }

        JPanel panelSud = new JPanel();
        panelSud.setBackground(new Color(245, 246, 250));

        // Sostituito con il BottoneModerno!
        BottoneModerno btnChiudi = new BottoneModerno("Chiudi Scontrino", new Color(149, 165, 166), 15);
        btnChiudi.setPreferredSize(new Dimension(180, 45));
        btnChiudi.addActionListener(e -> dispose());

        panelSud.add(btnChiudi);
        panelSud.setBorder(BorderFactory.createEmptyBorder(0, 0, 15, 0));
        add(panelSud, BorderLayout.SOUTH);
    }
}