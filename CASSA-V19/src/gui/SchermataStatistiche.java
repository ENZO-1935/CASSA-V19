package gui;

import dao.OrdineDAO;
import hardware.GestoreStampa;
import javax.swing.*;
import java.awt.*;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Map;

public class SchermataStatistiche extends JFrame {

    private static final int LARGHEZZA_REPORT = 42;

    public SchermataStatistiche() {
        setTitle("Report di Chiusura Cassa");
        setSize(450, 750);
        setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE); // Chiude solo la finestra senza alterare il DB
        setLayout(new BorderLayout());

        OrdineDAO dao = new OrdineDAO();
        double incassoTotale = dao.calcolaIncassoTotale();
        Map<String, double[]> datiReport = dao.generaReportArticoli();

        JTextArea areaReport = new JTextArea();
        areaReport.setEditable(false);
        areaReport.setFont(new Font("Monospaced", Font.BOLD, 15));
        areaReport.setBackground(new Color(253, 253, 230));
        areaReport.setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20));

        String dataOra = new SimpleDateFormat("dd/MM/yyyy HH:mm").format(new Date());
        areaReport.append(centraTesto("STAMPA REPORT DEL " + dataOra) + "\n\n");

        for (Map.Entry<String, double[]> entry : datiReport.entrySet()) {
            String nome = entry.getKey().toUpperCase();
            int quantita = (int) entry.getValue()[0];
            String prezzoStr = String.format("%.2f", entry.getValue()[1]);

            String riga = formattaRiga(quantita + " " + nome, prezzoStr);
            areaReport.append(riga + "\n");
            areaReport.append("------------------------------------------\n");
        }

        areaReport.append("\n" + centraTesto("TOTALE DOCUMENTO CASSA") + "\n");
        areaReport.append(centraTesto(String.format("%.2f EUR", incassoTotale)) + "\n\n");

        JScrollPane scroll = new JScrollPane(areaReport);
        scroll.getVerticalScrollBar().setUnitIncrement(16);
        add(scroll, BorderLayout.CENTER);

        // PANNELLO BOTTONI DI CHIUSURA
        JPanel panelBottoni = new JPanel(new GridLayout(2, 1, 0, 10));
        panelBottoni.setBorder(BorderFactory.createEmptyBorder(15, 10, 10, 10));

        JButton btnStampa = new JButton("1. Stampa Report su Carta");
        btnStampa.setBackground(new Color(70, 130, 180)); // Blu
        btnStampa.setForeground(Color.WHITE);
        btnStampa.setFont(new Font("Arial", Font.BOLD, 18));
        btnStampa.setPreferredSize(new Dimension(0, 50));
        btnStampa.addActionListener(e -> {
            GestoreStampa stampante = new GestoreStampa();
            stampante.stampaReportZ(incassoTotale, datiReport);
            JOptionPane.showMessageDialog(this, "Stampa del resoconto inviata alla stampante!", "Stampa Inviata", JOptionPane.INFORMATION_MESSAGE);
        });

        JButton btnAzzera = new JButton("2. Reset Totale (Nuova Festa / Pulizia)");
        btnAzzera.setBackground(new Color(220, 20, 60)); // Rosso
        btnAzzera.setForeground(Color.WHITE);
        btnAzzera.setFont(new Font("Arial", Font.BOLD, 16));
        btnAzzera.setPreferredSize(new Dimension(0, 50));
        btnAzzera.addActionListener(e -> {
            int scelta = JOptionPane.showConfirmDialog(this,
                    "ATTENZIONE PERICOLO!\nQuesta operazione cancellerà:\n- Tutti gli scontrini e gli incassi\n- L'intero listino prodotti (dovrai reinserire i piatti della nuova festa)\n\nVuoi procedere con il reset totale?",
                    "Conferma Reset Totale",
                    JOptionPane.YES_NO_OPTION,
                    JOptionPane.WARNING_MESSAGE);

            if (scelta == JOptionPane.YES_OPTION) {
                dao.svuotaTuttoDefinitivo();
                JOptionPane.showMessageDialog(this, "Reset completato.\nOra il database è completamente pulito e pronto per una nuova festa!", "Pulizia Effettuata", JOptionPane.INFORMATION_MESSAGE);
                this.dispose();
            }
        });

        panelBottoni.add(btnStampa);
        panelBottoni.add(btnAzzera);
        add(panelBottoni, BorderLayout.SOUTH);

        setLocationRelativeTo(null);
    }

    private String formattaRiga(String sinistra, String destra) {
        int spaziMancanti = LARGHEZZA_REPORT - sinistra.length() - destra.length();
        if (spaziMancanti < 1) {
            sinistra = sinistra.substring(0, LARGHEZZA_REPORT - destra.length() - 2) + ".";
            spaziMancanti = 1;
        }
        StringBuilder sb = new StringBuilder(sinistra);
        for (int i = 0; i < spaziMancanti; i++) sb.append(" ");
        sb.append(destra);
        return sb.toString();
    }

    private String centraTesto(String testo) {
        if (testo.length() >= LARGHEZZA_REPORT) return testo;
        int padding = (LARGHEZZA_REPORT - testo.length()) / 2;
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < padding; i++) sb.append(" ");
        sb.append(testo);
        return sb.toString();
    }
}