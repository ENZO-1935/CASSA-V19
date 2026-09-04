package hardware;

import dao.DatabaseManager;
import model.Carrello;
import model.Prodotto;
import java.io.ByteArrayOutputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Map;

public class GestoreStampa {

    // Credenziali e Endpoint VPrinter ufficiali corretti
    private static final String VPRINTER_URL = "https://api.vprinter.dev/api/workspace/V19/prints";
    private static final String API_KEY = "at_9c3d0d8928fe45749f490244bda54ff0.efe139a68fe077b7181029d1b45f11d62ae4db608315d24bbec00d4f54ae0ada";

    // Comandi ESC/POS per gestire stampanti hardware
    private static final byte[] INIT = {0x1B, 0x40};
    private static final byte[] ALLINEA_CENTRO = {0x1B, 0x61, 1};
    private static final byte[] ALLINEA_SINISTRA = {0x1B, 0x61, 0};
    private static final byte[] FONT_GRANDE = {0x1D, 0x21, 0x11};
    private static final byte[] FONT_NORMALE = {0x1D, 0x21, 0x00};
    private static final byte[] TAGLIO_CARTA = {0x1D, 0x56, 0x41, 0x10};

    private static final int LARGHEZZA_SCONTRINO = 42;

    // --- METODO 1: Stampa Scontrino di Vendita e Ticket Stand ---
    public void stampaScontrino(Carrello carrello, int numeroScontrino) {
        new Thread(() -> eseguiStampa(carrello, numeroScontrino)).start();
    }

    private void eseguiStampa(Carrello carrello, int numeroScontrino) {
        try {
            // FOTOGRAFIA DELL'ORDINE: clona i prodotti prima che la GUI svuoti il carrello
            java.util.Map<Prodotto, Integer> copiaOrdine = new java.util.HashMap<>(carrello.getProdotti());

            // ==========================================
            // 1. SCONTRINO RIEPILOGATIVO CLIENTE
            // ==========================================
            ByteArrayOutputStream bufferPrincipale = new ByteArrayOutputStream();
            bufferPrincipale.write(INIT);

            bufferPrincipale.write(ALLINEA_CENTRO);
            bufferPrincipale.write(FONT_GRANDE);
            bufferPrincipale.write("FESTA DEL PAESE\n".getBytes());
            bufferPrincipale.write(FONT_NORMALE);
            bufferPrincipale.write("Associazione Pro Loco\n".getBytes());
            String dataOra = new SimpleDateFormat("dd/MM/yyyy HH:mm:ss").format(new Date());

            bufferPrincipale.write(("\nData: " + dataOra + "\n").getBytes());
            bufferPrincipale.write(FONT_GRANDE);
            bufferPrincipale.write(("SCONTRINO N. " + numeroScontrino + "\n\n").getBytes());
            bufferPrincipale.write(FONT_NORMALE);
            bufferPrincipale.write(ALLINEA_SINISTRA);
            bufferPrincipale.write("------------------------------------------\n".getBytes());

            // Usiamo la COPIA dell'ordine, non il carrello originale
            for (Map.Entry<Prodotto, Integer> entry : copiaOrdine.entrySet()) {
                Prodotto p = entry.getKey();
                int quantita = entry.getValue();
                double totaleRiga = p.getPrezzo() * quantita;
                String riga = formattaRiga(quantita + "x " + p.getNome(), String.format("%.2f", totaleRiga));
                bufferPrincipale.write((riga + "\n").getBytes());
            }
            bufferPrincipale.write("------------------------------------------\n".getBytes());
            bufferPrincipale.write(ALLINEA_CENTRO);
            bufferPrincipale.write(FONT_GRANDE);
            bufferPrincipale.write(("TOTALE: " + String.format("%.2f", carrello.getTotale()) + " EUR\n\n\n").getBytes());
            bufferPrincipale.write(FONT_NORMALE);
            bufferPrincipale.write("Grazie per aver partecipato!\n\n\n".getBytes());
            bufferPrincipale.write(TAGLIO_CARTA);

            System.out.println("Invio scontrino principale in corso...");
            inviaAVPrinter(bufferPrincipale.toByteArray());

            Thread.sleep(1500);

            // ==========================================
            // 2. TICKET SINGOLI PER STAND
            // ==========================================
            int contatoreTicket = 1;

            // Usiamo di nuovo la COPIA dell'ordine
            for (Map.Entry<Prodotto, Integer> entry : copiaOrdine.entrySet()) {
                Prodotto p = entry.getKey();
                int quantita = entry.getValue();

                for (int i = 0; i < quantita; i++) {
                    ByteArrayOutputStream bufferTicket = new ByteArrayOutputStream();

                    bufferTicket.write(INIT);
                    bufferTicket.write(ALLINEA_CENTRO);
                    bufferTicket.write(FONT_NORMALE);
                    bufferTicket.write(("Ordine " + numeroScontrino + " - Ticket " + contatoreTicket + "\n").getBytes());
                    bufferTicket.write("------------------------\n\n".getBytes());

                    bufferTicket.write(FONT_GRANDE);
                    bufferTicket.write(("1x " + p.getNome().toUpperCase() + "\n\n").getBytes());

                    bufferTicket.write(FONT_NORMALE);
                    bufferTicket.write("------------------------\n".getBytes());
                    bufferTicket.write("Da consegnare allo stand\n\n\n\n".getBytes());
                    bufferTicket.write(TAGLIO_CARTA);

                    System.out.println("Invio ticket " + contatoreTicket + " per " + p.getNome() + "...");
                    inviaAVPrinter(bufferTicket.toByteArray());

                    contatoreTicket++;
                    Thread.sleep(1500);
                }
            }

            System.out.println("Elaborazione ordine conclusa!");

        } catch (Exception e) {
            System.out.println("Errore generazione comandi vendita: " + e.getMessage());
        }
    }

    // --- METODO 2: Stampa Report Statistiche Fine Serata ---
    public void stampaReportZ(double incassoTotale, Map<String, double[]> datiReport) {
        new Thread(() -> {
            try {
                ByteArrayOutputStream buffer = new ByteArrayOutputStream();

                buffer.write(INIT);
                buffer.write(ALLINEA_CENTRO);
                buffer.write(FONT_GRANDE);
                buffer.write("REPORT CHIUSURA\n".getBytes());
                buffer.write(FONT_NORMALE);

                String dataOra = new SimpleDateFormat("dd/MM/yyyy HH:mm").format(new Date());
                buffer.write(("STAMPA REPORT DEL " + dataOra + "\n\n").getBytes());

                buffer.write(ALLINEA_SINISTRA);

                for (Map.Entry<String, double[]> entry : datiReport.entrySet()) {
                    String nome = entry.getKey().toUpperCase();
                    int qta = (int) entry.getValue()[0];
                    String prezzoStr = String.format("%.2f", entry.getValue()[1]);

                    String riga = formattaRiga(qta + " " + nome, prezzoStr);
                    buffer.write((riga + "\n").getBytes());
                    buffer.write("------------------------------------------\n".getBytes());
                }

                buffer.write(ALLINEA_CENTRO);
                buffer.write("\nTOTALE DOCUMENTO CASSA\n".getBytes());
                buffer.write(FONT_GRANDE);
                buffer.write((String.format("%.2f EUR", incassoTotale) + "\n\n\n").getBytes());

                buffer.write(FONT_NORMALE);
                buffer.write(TAGLIO_CARTA);

                inviaAVPrinter(buffer.toByteArray());

            } catch (Exception e) {
                System.out.println("Errore generazione report VPrinter: " + e.getMessage());
            }
        }).start();
    }

    // --- METODO 3: Stampa Scontrino di Chiusura Evento (Integrazione VPrinter) ---
    public static void stampaRiepilogoChiusura() {
        new Thread(() -> {
            try {
                ByteArrayOutputStream buffer = new ByteArrayOutputStream();

                buffer.write(INIT);
                buffer.write(ALLINEA_CENTRO);
                buffer.write(FONT_GRANDE);
                buffer.write("CHIUSURA CASSA SAGRA\n".getBytes());
                buffer.write(FONT_NORMALE);

                String dataOra = new SimpleDateFormat("dd/MM/yyyy HH:mm:ss").format(new Date());
                buffer.write(("Data: " + dataOra + "\n\n").getBytes());
                buffer.write(ALLINEA_SINISTRA);
                buffer.write("------------------------------------------\n".getBytes());

                // Legge i dati aggiornati dalle tabelle corrette (ordine e dettaglio_ordine)
                try (Connection conn = DatabaseManager.connetti();
                     Statement stmt = conn.createStatement()) {

                    // Incasso totale
                    ResultSet rsTot = stmt.executeQuery("SELECT SUM(totale) AS totale FROM ordine");
                    if (rsTot.next()) {
                        double totale = rsTot.getDouble("totale");
                        buffer.write(String.format("INCASSO TOTALE: EUR %.2f\n", totale).getBytes());
                    }
                    rsTot.close();

                    buffer.write("------------------------------------------\n".getBytes());
                    buffer.write("Dettaglio Prodotti Venduti:\n".getBytes());
                    buffer.write("------------------------------------------\n".getBytes());

                    // Dettaglio prodotti con i nomi di colonna corretti di OrdineDAO
                    ResultSet rsProd = stmt.executeQuery("SELECT nome_prodotto, SUM(quantita) as qta_tot, SUM(prezzo_totale) as incasso_tot FROM dettaglio_ordine GROUP BY nome_prodotto");
                    while (rsProd.next()) {
                        String nome = rsProd.getString("nome_prodotto");
                        int qta = rsProd.getInt("qta_tot");
                        double incasso = rsProd.getDouble("incasso_tot");

                        String riga = formattaRigaStatica(qta + "x " + nome, String.format("%.2f", incasso));
                        buffer.write((riga + "\n").getBytes());
                    }
                    rsProd.close();

                } catch (Exception e) {
                    buffer.write("Errore recupero dati database\n".getBytes());
                }

                buffer.write("------------------------------------------\n".getBytes());
                buffer.write(ALLINEA_CENTRO);
                buffer.write("Fine Report Chiusura\n\n\n".getBytes());
                buffer.write(TAGLIO_CARTA);

                System.out.println("Invio scontrino di chiusura a VPrinter...");
                inviaAVPrinterStatic(buffer.toByteArray());

            } catch (Exception e) {
                System.out.println("Errore generazione comandi chiusura: " + e.getMessage());
            }
        }).start();
    }

    // --- MOTORE DI INVIO DATI VERSO IL CLOUD ---
    private void inviaAVPrinter(byte[] payload) {
        inviaAVPrinterStatic(payload);
    }

    private static void inviaAVPrinterStatic(byte[] payload) {
        try {
            URL url = new URL(VPRINTER_URL);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");

            // Intestazioni REST obbligatorie per VPrinter
            conn.setRequestProperty("Content-Type", "application/octet-stream");
            conn.setRequestProperty("Authorization", "Bearer " + API_KEY);
            conn.setDoOutput(true);

            // Scrittura fisica dei byte nella richiesta
            try (OutputStream os = conn.getOutputStream()) {
                os.write(payload);
                os.flush();
            }

            int responseCode = conn.getResponseCode();
            if (responseCode >= 200 && responseCode < 300) {
                System.out.println("Stampa inviata con successo al Cloud VPrinter!");
            } else {
                System.out.println("Errore server VPrinter. Codice HTTP: " + responseCode);
            }
            conn.disconnect();

        } catch (Exception e) {
            System.out.println("Errore di rete verso VPrinter: " + e.getMessage());
        }
    }

    // --- UTILITY: Formattazione testo per nastro termico ---
    private String formattaRiga(String sinistra, String destra) {
        return formattaRigaStatica(sinistra, destra);
    }

    private static String formattaRigaStatica(String sinistra, String destra) {
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