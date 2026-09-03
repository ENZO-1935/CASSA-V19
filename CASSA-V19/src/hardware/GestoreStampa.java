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
    // Configurazione di rete della stampante
    private static final String IP_STAMPANTE = "192.168.1.100"; // Modifica con l'IP reale della stampante
    private static final int PORTA = 9100;
    private static final int TIMEOUT_MS = 2000; // Evita il blocco della GUI se la stampante è offline

    // Set di comandi ESC/POS (Esadecimali / Decimali)
    private static final byte[] INIT = {0x1B, 0x40};
    private static final byte[] ALLINEA_CENTRO = {0x1B, 0x61, 1};
    private static final byte[] ALLINEA_SINISTRA = {0x1B, 0x61, 0};
    private static final byte[] FONT_GRANDE = {0x1D, 0x21, 0x11}; // Doppia larghezza e altezza
    private static final byte[] FONT_NORMALE = {0x1D, 0x21, 0x00};
    private static final byte[] GRASSETTO_ON = {0x1B, 0x45, 1};
    private static final byte[] GRASSETTO_OFF = {0x1B, 0x45, 0};
    private static final byte[] TAGLIO_CARTA = {0x1D, 0x56, 0x41, 0x10};
    private static final byte[] APRI_CASSETTO = {0x1B, 0x70, 0x00, 0x32, (byte) 0xFA}; // Pin 2

    // Larghezza del rotolo (modello 80mm = ~42-48 caratteri, modello 58mm = ~32 caratteri)
    private static final int LARGHEZZA_SCONTRINO = 42;

    public void stampaScontrino(Carrello carrello, int numeroScontrino) {
        // Usa un thread separato per non bloccare l'interfaccia grafica durante la rete
        new Thread(() -> eseguiStampa(carrello, numeroScontrino)).start();
    }

    private void eseguiStampa(Carrello carrello, int numeroScontrino) {
        try (Socket socket = new Socket()) {
            // Connessione con timeout di 2 secondi
            socket.connect(new InetSocketAddress(IP_STAMPANTE, PORTA), TIMEOUT_MS);
            OutputStream out = socket.getOutputStream();

            // 1. Inizializzazione
            out.write(INIT);

            // 2. Intestazione
            out.write(ALLINEA_CENTRO);
            out.write(FONT_GRANDE);
            out.write("FESTA DEL PAESE\n".getBytes());
            out.write(FONT_NORMALE);
            out.write("Associazione Pro Loco\n".getBytes());
            String dataOra = new SimpleDateFormat("dd/MM/yyyy HH:mm").format(new Date());

            // STAMPA IL NUMERO PROGRESSIVO IN GRANDE SULLO SCONTRINO
            out.write(("\nData: " + dataOra + "\n").getBytes());
            out.write(FONT_GRANDE);
            out.write(("SCONTRINO N. " + numeroScontrino + "\n\n").getBytes());
            out.write(FONT_NORMALE);

            // 3. Corpo (Lista articoli)
            out.write(ALLINEA_SINISTRA);
            out.write("------------------------------------------\n".getBytes());

            // Costruzione delle righe: Nome a sinistra, Prezzo a destra
            for (Map.Entry<Prodotto, Integer> entry : carrello.getProdotti().entrySet()) {
                Prodotto p = entry.getKey();
                int quantita = entry.getValue();
                double totaleRiga = p.getPrezzo() * quantita;

                String riga = formattaRiga(quantita + "x " + p.getNome(), String.format("%.2f", totaleRiga));
                out.write((riga + "\n").getBytes());
            }
            out.write("------------------------------------------\n".getBytes());

            // 4. Totale
            out.write(ALLINEA_CENTRO);
            out.write(FONT_GRANDE);
            out.write(("TOTALE: " + String.format("%.2f", carrello.getTotale()) + " EUR\n\n\n").getBytes());

            // 5. Chiusura
            out.write(FONT_NORMALE);
            out.write("Grazie per aver partecipato!\n\n\n".getBytes());
            out.write(TAGLIO_CARTA);
            out.write(APRI_CASSETTO); // Spinge fuori il cassetto dei contanti

            out.flush();
            System.out.println("Stampa hardware inviata con successo.");

        } catch (Exception e) {
            System.out.println("ERRORE HARDWARE: Stampante non raggiungibile o offline. Scontrino salvato ma non stampato fisicamente.");
        }
    }

    // Metodo per impaginare dinamicamente il testo a destra e sinistra
    private String formattaRiga(String nome, String prezzo) {
        int spaziMancanti = LARGHEZZA_SCONTRINO - nome.length() - prezzo.length();
        if (spaziMancanti < 1) {
            // Se il nome è troppo lungo, lo tronca per far spazio al prezzo
            nome = nome.substring(0, LARGHEZZA_SCONTRINO - prezzo.length() - 2) + ".";
            spaziMancanti = 1;
        }
        StringBuilder sb = new StringBuilder(nome);
        for (int i = 0; i < spaziMancanti; i++) {
            sb.append(" ");
        }
        sb.append(prezzo);
        return sb.toString();
    }
}