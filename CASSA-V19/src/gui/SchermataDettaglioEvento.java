package gui;

import javax.swing.*;
import javax.swing.table.DefaultTableCellRenderer;
import javax.swing.table.DefaultTableModel;
import java.awt.*;

public class SchermataDettaglioEvento extends JFrame {

    public SchermataDettaglioEvento(int idEvento, String nomeEvento, String dataChiusura, double incassoTotale, String dettagliVendite) {
        setTitle("Scontrino Chiusura Evento: " + nomeEvento);
        setSize(700, 520);
        setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
        setLocationRelativeTo(null);
        setLayout(new BorderLayout(10, 10));

        JPanel panelNord = new JPanel(new GridLayout(3, 1, 5, 5));
        panelNord.setBorder(BorderFactory.createEmptyBorder(15, 20, 10, 20));

        JLabel lblTitolo = new JLabel("EVENTO: " + nomeEvento, JLabel.CENTER);
        lblTitolo.setFont(new Font("Arial", Font.BOLD, 18));
        panelNord.add(lblTitolo);

        JLabel lblData = new JLabel("Ultimo aggiornamento: " + dataChiusura, JLabel.CENTER);
        lblData.setFont(new Font("Arial", Font.PLAIN, 14));
        panelNord.add(lblData);

        JLabel lblIncasso = new JLabel(String.format("Incasso Totale Unificato: € %.2f", incassoTotale), JLabel.CENTER);
        lblIncasso.setFont(new Font("Arial", Font.BOLD, 16));
        lblIncasso.setForeground(new Color(34, 139, 34));
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
                if (riga.trim().isEmpty()) continue; // Salta spazi vuoti

                if (riga.startsWith("[SESSIONE]")) {
                    String titoloSessione = riga.replace("[SESSIONE]", "").trim().toUpperCase();
                    // Inserisce la riga divisoria che funge da titolo per il singolo scontrino
                    model.addRow(new Object[]{"► " + titoloSessione, "-", "-"});
                    haDettagli = true;
                } else {
                    String[] parti = riga.split(";");
                    if (parti.length == 3) {
                        try {
                            String nome = parti[0];
                            String qta = parti[1];
                            double incasso = Double.parseDouble(parti[2]);
                            // Aggiunge 4 spazi al nome del prodotto per indentarlo sotto al titolo della sessione
                            model.addRow(new Object[]{"    " + nome, qta, String.format("€ %.2f", incasso)});
                            haDettagli = true;
                        } catch (Exception ignored) {}
                    }
                }
            }
        }

        if (!haDettagli) {
            JPanel panelAvviso = new JPanel(new GridBagLayout());
            JLabel lblAvviso = new JLabel("<html><center><b>Dettaglio prodotti non disponibile</b><br><br>Questo evento è stato archiviato prima dell'aggiornamento.<br>Contiene unicamente il totale dell'incasso registrato.</center></html>", JLabel.CENTER);
            lblAvviso.setFont(new Font("Arial", Font.PLAIN, 15));
            lblAvviso.setForeground(new Color(150, 40, 40));
            panelAvviso.add(lblAvviso);
            add(panelAvviso, BorderLayout.CENTER);
        } else {
            JTable tabella = new JTable(model);
            tabella.setFont(new Font("Arial", Font.PLAIN, 14));
            tabella.setRowHeight(28);
            tabella.getTableHeader().setFont(new Font("Arial", Font.BOLD, 14));

            // Renderer personalizzato: Evidenzia le righe di intestazione "Scontrino" in azzurro scuro e in grassetto
            tabella.setDefaultRenderer(Object.class, new DefaultTableCellRenderer() {
                @Override
                public Component getTableCellRendererComponent(JTable table, Object value, boolean isSelected, boolean hasFocus, int row, int column) {
                    Component c = super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, column);
                    String nome = (String) table.getValueAt(row, 0);
                    if (nome != null && nome.startsWith("►")) {
                        c.setFont(new Font("Arial", Font.BOLD, 14));
                        c.setBackground(new Color(230, 240, 250)); // Sfondo celestino per evidenziare il separatore
                        c.setForeground(new Color(0, 50, 100));
                    } else {
                        c.setFont(new Font("Arial", Font.PLAIN, 14));
                        c.setBackground(Color.WHITE);
                        c.setForeground(Color.BLACK);
                    }
                    if (isSelected) c.setBackground(new Color(184, 207, 229));
                    return c;
                }
            });

            JScrollPane scrollPane = new JScrollPane(tabella);
            scrollPane.setBorder(BorderFactory.createEmptyBorder(10, 20, 10, 20));
            add(scrollPane, BorderLayout.CENTER);
        }

        JPanel panelSud = new JPanel();
        JButton btnChiudi = new JButton("Chiudi");
        btnChiudi.setFont(new Font("Arial", Font.BOLD, 14));
        btnChiudi.setBackground(new Color(105, 105, 105));
        btnChiudi.setForeground(Color.WHITE);
        btnChiudi.setFocusPainted(false);
        btnChiudi.setPreferredSize(new Dimension(120, 40));
        btnChiudi.addActionListener(e -> dispose());

        panelSud.add(btnChiudi);
        panelSud.setBorder(BorderFactory.createEmptyBorder(0, 0, 15, 0));
        add(panelSud, BorderLayout.SOUTH);
    }
}