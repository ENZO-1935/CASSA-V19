package model;

public class Ordine {
    private int idOrdine;
    private int numeroScontrino;
    private long dataOra;
    private double totale;
    private String tavolo;
    private String nomeCliente;
    private int coperti;
    private String noteGenerali;
    private String metodoPagamento;
    private boolean asporto;
    private boolean annullato;

    public Ordine(int idOrdine, int numeroScontrino, long dataOra) {
        this.idOrdine = idOrdine;
        this.numeroScontrino = numeroScontrino;
        this.dataOra = dataOra;
        this.totale = 0.0;
        this.annullato = false;
        this.asporto = false;
    }

    // Getters principali
    public int getIdOrdine() { return idOrdine; }
    public int getNumeroScontrino() { return numeroScontrino; }
    public double getTotale() { return totale; }

    // I GETTERS MANCANTI CHE CAUSAVANO L'ERRORE
    public String getTavolo() { return tavolo; }
    public String getNomeCliente() { return nomeCliente; }
    public int getCoperti() { return coperti; }
    public String getNoteGenerali() { return noteGenerali; }
    public String getMetodoPagamento() { return metodoPagamento; }
    public boolean isAsporto() { return asporto; }
    public boolean isAnnullato() { return annullato; }

    // Setters
    public void setTotale(double totale) { this.totale = totale; }
    public void setTavolo(String tavolo) { this.tavolo = tavolo; }
    public void setNomeCliente(String nomeCliente) { this.nomeCliente = nomeCliente; }
    public void setCoperti(int coperti) { this.coperti = coperti; }
    public void setNoteGenerali(String noteGenerali) { this.noteGenerali = noteGenerali; }
    public void setMetodoPagamento(String metodo) { this.metodoPagamento = metodo; }
    public void setAsporto(boolean asporto) { this.asporto = asporto; }
    public void setAnnullato(boolean annullato) { this.annullato = annullato; }
}