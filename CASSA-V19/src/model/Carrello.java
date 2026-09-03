package model;

import java.util.HashMap;
import java.util.Map;

public class Carrello {
    private static Carrello instance;
    private Map<Prodotto, Integer> prodotti;
    private double totale;

    private Carrello() {
        prodotti = new HashMap<>();
        totale = 0.0;
    }

    public static Carrello getInstance() {
        if (instance == null) {
            instance = new Carrello();
        }
        return instance;
    }

    public void aggiungiProdotto(Prodotto p) {
        prodotti.put(p, prodotti.getOrDefault(p, 0) + 1);
        totale += p.getPrezzo();
    }

    // NUOVO METODO: Sottrae 1 pezzo dell'articolo scelto e riaggiusta il totale
    public void rimuoviProdotto(Prodotto p) {
        if (prodotti.containsKey(p)) {
            int quantitaAttuale = prodotti.get(p);
            if (quantitaAttuale > 1) {
                prodotti.put(p, quantitaAttuale - 1);
            } else {
                prodotti.remove(p); // Se era l'ultimo, lo cancella dalla lista
            }
            totale -= p.getPrezzo();

            if (totale < 0) totale = 0.0; // Sicurezza per evitare rimasugli decimali
        }
    }

    public Map<Prodotto, Integer> getProdotti() {
        return prodotti;
    }

    public double getTotale() {
        return totale;
    }

    public void svuota() {
        prodotti.clear();
        totale = 0.0;
    }
}