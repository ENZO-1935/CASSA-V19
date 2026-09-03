package model;

public class GruppoStampa {
    private int idGruppo;
    private String nome;
    private String coloreUi;
    private boolean stampaCopiaSingola; // true per stampare un biglietto per ogni singola unità (es. Bar)

    public GruppoStampa(int idGruppo, String nome, String coloreUi, boolean stampaCopiaSingola) {
        this.idGruppo = idGruppo;
        this.nome = nome;
        this.coloreUi = coloreUi;
        this.stampaCopiaSingola = stampaCopiaSingola;
    }

    public int getIdGruppo() { return idGruppo; }
    public String getNome() { return nome; }
    public String getColoreUi() { return coloreUi; }
    public boolean isStampaCopiaSingola() { return stampaCopiaSingola; }
}