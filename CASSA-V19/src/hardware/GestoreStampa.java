package hardware;

import model.Carrello;
import model.Prodotto;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Map;

public class GestoreStampa {
    private static final String IP_STAMPANTE = "192.168.1.100";
    private static final int PORTA = 9100;
    private static final int TIMEOUT_MS = 2000;

    private static final byte[] INIT = {0x1B, 0x40};
    private static final byte[] ALLINEA_CENTRO = {0x1B, 0x61, 1};
    private static final byte[] ALLINEA_SINISTRA = {0x1B, 0x61, 0};
    private static final byte[] FONT_GRANDE = {0x1D, 0x21, 0x11};
    private static final byte[] FONT_NORMALE = {0x1D, 0x21, 0x00};
    private static final byte[] TAGLIO_CARTA = {0x1D, 0x56, 0x41, 0x10};
    private static final byte[] APRI_CASSETTO = {0x1B, 0x70, 0x00, 0x32, (byte) 0xFA};

    private static final int LARGHEZZA_SCONTRINO = 42;

    public void stampaScontrino(Carrello carrello, int numeroScontrino) {
        new Thread(() -> eseguiStampa(carrello, numeroScontrino)).start();
    }

    private void eseguiStampa(Carrello carrello, int numeroScontrino) {
        try (Socket socket = new Socket()) {
            socket.connect(new InetSocketAddress(IP_STAMPANTE, PORTA), TIMEOUT_MS);
            OutputStream out = socket.getOutputStream();

            out.write(INIT);
            out.write(ALLINEA_CENTRO);
            out.write(FONT_GRANDE);
            out.write("FESTA DEL PAESE\n".getBytes());
            out.write(FONT_NORMALE);
            out.write("Associazione Pro Loco\n".getBytes());
            String dataOra = new SimpleDateFormat("dd/MM/yyyy HH:mm").format(new Date());

            out.write(("\nData: " + dataOra + "\n").getBytes());
            out.write(FONT_GRANDE);
            out.write(("SCONTRINO N. " + numeroScontrino + "\n\n").getBytes());
            out.write(FONT_NORMALE);
            out.write(ALLINEA_SINISTRA);
            out.write("------------------------------------------\n".getBytes());

            for (Map.Entry<Prodotto, Integer> entry : carrello.getProdotti().entrySet()) {
                Prodotto p = entry.getKey();
                int quantita = entry.getValue();
                double totaleRiga = p.getPrezzo() * quantita;
                String riga = formattaRiga(quantita + "x " + p.getNome(), String.format("%.2f", totaleRiga));
                out.write((riga + "\n").getBytes());
            }
            out.write("------------------------------------------\n".getBytes());
            out.write(ALLINEA_CENTRO);
            out.write(FONT_GRANDE);
            out.write(("TOTALE: " + String.format("%.2f", carrello.getTotale()) + " EUR\n\n\n").getBytes());
            out.write(FONT_NORMALE);
            out.write("Grazie per aver partecipato!\n\n\n".getBytes());
            out.write(TAGLIO_CARTA);
            out.write(APRI_CASSETTO);
            out.flush();
        } catch (Exception e) {
            System.out.println("Errore stampante scontrino: " + e.getMessage());
        }
    }

    // NUOVO: Stampa il resoconto finale della giornata in puro stile ESC/POS (come la tua foto)
    public void stampaReportZ(double incassoTotale, Map<String, double[]> datiReport) {
        new Thread(() -> {
            try (Socket socket = new Socket()) {
                socket.connect(new InetSocketAddress(IP_STAMPANTE, PORTA), TIMEOUT_MS);
                OutputStream out = socket.getOutputStream();

                out.write(INIT);
                out.write(ALLINEA_CENTRO);
                out.write(FONT_GRANDE);
                out.write("REPORT CHIUSURA\n".getBytes());
                out.write(FONT_NORMALE);

                String dataOra = new SimpleDateFormat("dd/MM/yyyy HH:mm").format(new Date());
                out.write(("STAMPA REPORT DEL " + dataOra + "\n\n").getBytes());

                out.write(ALLINEA_SINISTRA);

                // Stampa la lista degli articoli totalizzati
                for (Map.Entry<String, double[]> entry : datiReport.entrySet()) {
                    String nome = entry.getKey().toUpperCase();
                    int qta = (int) entry.getValue()[0];
                    String prezzoStr = String.format("%.2f", entry.getValue()[1]);

                    String riga = formattaRiga(qta + " " + nome, prezzoStr);
                    out.write((riga + "\n").getBytes());
                    out.write("------------------------------------------\n".getBytes());
                }

                // Stampa l'incasso finale
                out.write(ALLINEA_CENTRO);
                out.write("\nTOTALE DOCUMENTO CASSA\n".getBytes());
                out.write(FONT_GRANDE);
                out.write((String.format("%.2f EUR", incassoTotale) + "\n\n\n").getBytes());

                out.write(FONT_NORMALE);
                out.write(TAGLIO_CARTA);
                out.flush();
            } catch (Exception e) {
                System.out.println("Errore stampante report: " + e.getMessage());
            }
        }).start();
    }

    private String formattaRiga(String sinistra, String destra) {
        int spaziMancanti = LARGHEZZA_SCONTRINO - sinistra.length() - destra.length();
        if (spaziMancanti < 1) {
            sinistra = sinistra.substring(0, LARGHEZZA_SCONTRINO - destra.length() - 2) + ".";
            spaziMancanti = 1;
        }
        StringBuilder sb = new StringBuilder(sinistra);
        for (int i = 0; i < spaziMancanti; i++) sb.append(" ");
        sb.append(destra);
        return sb.toString();
    }
}