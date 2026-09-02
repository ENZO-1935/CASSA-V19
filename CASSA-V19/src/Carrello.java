import java.util.HashMap;
import java.util.Map;

public class Carrello {
    private static volatile Carrello istanza;
    private final Map<Integer, DettaglioOrdine> voci;
    private double totale;

    private Carrello() {
        this.voci = new HashMap<>();
        this.totale = 0.0;
    }

    public static Carrello getInstance() {
        if (istanza == null) {
            synchronized (Carrello.class) {
                if (istanza == null) {
                    istanza = new Carrello();
                }
            }
        }
        return istanza;
    }

    public void aggiungiProdotto(Prodotto prodotto) {
        // Blocco di sicurezza: controllo scorte (i buoni sconto non hanno scorte)
        if (prodotto.getQuantitaDisponibile() <= 0 && !prodotto.isBuonoSconto()) {
            System.out.println("-> ERRORE: " + prodotto.getNome() + " esaurito!");
            return;
        }

        int id = prodotto.getIdProdotto();

        if (prodotto.isBuonoSconto()) {
            // Logica Buoni: abbassano il totale ma non vanno mai in negativo
            if (totale - prodotto.getPrezzo() < 0) {
                totale = 0;
            } else {
                totale -= prodotto.getPrezzo();
            }
            System.out.println("-> Applicato: " + prodotto.getNome() + " (-" + prodotto.getPrezzo() + "€)");
        } else {
            // Logica Prodotti Normali
            if (voci.containsKey(id)) {
                DettaglioOrdine dettaglio = voci.get(id);
                dettaglio.setQuantita(dettaglio.getQuantita() + 1);
            } else {
                DettaglioOrdine nuovoDettaglio = new DettaglioOrdine(1, id, 1, prodotto.getPrezzo());
                voci.put(id, nuovoDettaglio);
            }
            totale += prodotto.getPrezzo();
            // Decrementa fisicamente la disponibilità residua
            prodotto.setQuantitaDisponibile(prodotto.getQuantitaDisponibile() - 1);
            System.out.println("-> Aggiunto: " + prodotto.getNome() + " (Residui: " + prodotto.getQuantitaDisponibile() + ")");
        }
    }

    public double getTotale() {
        return totale;
    }

    public void svuota() {
        voci.clear();
        totale = 0.0;
    }
}