package gui;

import dao.OrdineDAO;
import javax.swing.*;
import java.awt.*;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Map;

public class SchermataStatistiche extends JFrame {

    private static final int LARGHEZZA_REPORT = 42; // Caratteri massimi per riga

    public SchermataStatistiche() {
        setTitle("Report di Chiusura Cassa");
        setSize(450, 700);
        setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
        setLayout(new BorderLayout());

        OrdineDAO dao = new OrdineDAO();
        double incassoTotale = dao.calcolaIncassoTotale();
        Map<String, double[]> datiReport = dao.generaReportArticoli();

        // Area di testo per simulare lo scontrino fisico
        JTextArea areaReport = new JTextArea();
        areaReport.setEditable(false);
        areaReport.setFont(new Font("Monospaced", Font.BOLD, 15)); // Font da scontrino
        areaReport.setBackground(new Color(253, 253, 230)); // Colore giallino carta
        areaReport.setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20));

        // Costruzione dell'intestazione (come nella foto)
        String dataOra = new SimpleDateFormat("dd/MM/yyyy HH:mm").format(new Date());
        areaReport.append(centraTesto("STAMPA REPORT DEL " + dataOra) + "\n\n");

        // Costruzione delle righe (Q.tà + Nome a sinistra, Prezzo a destra)
        for (Map.Entry<String, double[]> entry : datiReport.entrySet()) {
            String nome = entry.getKey().toUpperCase();
            int quantita = (int) entry.getValue()[0];
            String prezzoStr = String.format("%.2f", entry.getValue()[1]);

            String riga = formattaRiga(quantita + " " + nome, prezzoStr);
            areaReport.append(riga + "\n");
            areaReport.append("------------------------------------------\n"); // Linea tratteggiata come in foto
        }

        areaReport.append("\n" + centraTesto("TOTALE DOCUMENTO CASSA") + "\n");
        areaReport.append(centraTesto(String.format("%.2f EUR", incassoTotale)) + "\n\n");

        JScrollPane scroll = new JScrollPane(areaReport);
        scroll.getVerticalScrollBar().setUnitIncrement(16);
        add(scroll, BorderLayout.CENTER);

        // Pulsante di stampa futura
        JButton btnStampa = new JButton("Stampa Report Fisico (ESC/POS)");
        btnStampa.setBackground(new Color(70, 130, 180));
        btnStampa.setForeground(Color.WHITE);
        btnStampa.setFont(new Font("Arial", Font.BOLD, 16));
        btnStampa.setPreferredSize(new Dimension(0, 50));
        // btnStampa.addActionListener(e -> inviaAllaStampante()); // Lo collegheremo al modulo hardware dopo

        add(btnStampa, BorderLayout.SOUTH);
        setLocationRelativeTo(null);
    }

    // Metodi per l'impaginazione tipografica
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