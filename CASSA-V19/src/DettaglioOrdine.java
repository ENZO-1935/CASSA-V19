public class DettaglioOrdine {
    private int idOrdine;
    private int idProdotto;
    private int quantita;
    private double prezzoUnitario;
    private String noteArticolo; // Es. "Senza formaggio"

    public DettaglioOrdine(int idOrdine, int idProdotto, int quantita, double prezzoUnitario) {
        this.idOrdine = idOrdine;
        this.idProdotto = idProdotto;
        this.quantita = quantita;
        this.prezzoUnitario = prezzoUnitario;
        this.noteArticolo = "";
    }

    public int getIdOrdine() { return idOrdine; }
    public int getIdProdotto() { return idProdotto; }
    public int getQuantita() { return quantita; }
    public double getPrezzoUnitario() { return prezzoUnitario; }
    public String getNoteArticolo() { return noteArticolo; }

    public void setQuantita(int quantita) { this.quantita = quantita; }
    public void setNoteArticolo(String note) { this.noteArticolo = note; }
}
