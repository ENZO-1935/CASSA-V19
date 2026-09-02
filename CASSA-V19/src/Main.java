public class Main {
    public static void main(String[] args) {
        // 1. Inizializziamo i dati (nella realtà verranno letti dal database SQLite)
        GruppoStampa cucina = new GruppoStampa(1, "Cucina", "#FF0000", false);
        GruppoStampa sconti = new GruppoStampa(9, "Sconti", "#00FF00", false);

        // Creiamo un prodotto con sole 2 unità disponibili
        Prodotto salsiccia = new Prodotto(101, cucina.getIdGruppo(), "Panino Salsiccia", 5.00, 2, false);
        Prodotto patatine = new Prodotto(102, cucina.getIdGruppo(), "Patatine", 3.50, 50, false);
        Prodotto buonoStaff = new Prodotto(901, sconti.getIdGruppo(), "Buono Staff", 5.00, 999, true);

        // 2. Simuliamo il lavoro del cassiere
        Carrello carrello = Carrello.getInstance();
        System.out.println("--- INIZIO ORDINE ---");

        // Il cassiere preme 3 volte il tasto "Panino Salsiccia" in modo molto rapido
        carrello.aggiungiProdotto(salsiccia);
        carrello.aggiungiProdotto(salsiccia);
        carrello.aggiungiProdotto(salsiccia); // Il sistema deve intercettare e bloccare questo inserimento

        carrello.aggiungiProdotto(patatine);

        System.out.println("Totale provvisorio: " + carrello.getTotale() + "€");

        // Applichiamo lo sconto
        carrello.aggiungiProdotto(buonoStaff);

        // 3. Chiusura Scontrino
        Ordine ordine = new Ordine(1, 1001, System.currentTimeMillis());
        ordine.setTotale(carrello.getTotale());
        ordine.setNomeCliente("Mario Rossi");
        ordine.setTavolo("12A");

        System.out.println("\n--- SCONTRINO CHIUSO ---");
        System.out.println("Cliente: " + ordine.getNomeCliente() + " | Tavolo: " + ordine.getTavolo());
        System.out.println("TOTALE DA PAGARE: " + ordine.getTotale() + "€");

        // Svuotiamo la memoria per il cliente successivo
        carrello.svuota();
    }
}