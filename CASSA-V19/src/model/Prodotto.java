package model;

public class Prodotto {
    private int idProdotto;
    private int idGruppo; // FK
    private String nome;
    private double prezzo;
    private int quantitaDisponibile; // Gestione scorte
    private boolean isBuonoSconto;   // Per gestire totali che non scendono sotto lo zero

    public Prodotto(int idProdotto, int idGruppo, String nome, double prezzo, int quantitaDisponibile, boolean isBuonoSconto) {
        this.idProdotto = idProdotto;
        this.idGruppo = idGruppo;
        this.nome = nome;
        this.prezzo = prezzo;
        this.quantitaDisponibile = quantitaDisponibile;
        this.isBuonoSconto = isBuonoSconto;
    }

    public int getIdProdotto() { return idProdotto; }
    public int getIdGruppo() { return idGruppo; }
    public String getNome() { return nome; }
    public double getPrezzo() { return prezzo; }
    public int getQuantitaDisponibile() { return quantitaDisponibile; }
    public boolean isBuonoSconto() { return isBuonoSconto; }

    public void setQuantitaDisponibile(int quantita) { this.quantitaDisponibile = quantita; }
}