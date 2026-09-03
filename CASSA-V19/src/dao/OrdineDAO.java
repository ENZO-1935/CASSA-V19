package dao;

import model.Carrello;
import model.Prodotto;
import java.sql.*;
import java.util.LinkedHashMap;
import java.util.Map;

public class OrdineDAO {
    private static final String URL = "jdbc:sqlite:cassa_sagra.db";

    public int salvaOrdine(Carrello carrello) throws SQLException {
        int prossimoNumero = ottieniProssimoNumeroScontrino();

        String sqlOrdine = "INSERT INTO ordine(numero_scontrino, data_ora, totale) VALUES (?, ?, ?)";
        String sqlDettaglio = "INSERT INTO dettaglio_ordine(numero_scontrino, nome_prodotto, quantita, prezzo_totale) VALUES (?, ?, ?, ?)";

        try (Connection conn = DriverManager.getConnection(URL)) {
            // 1. Salva il totale dello scontrino
            try (PreparedStatement pstmt = conn.prepareStatement(sqlOrdine)) {
                pstmt.setInt(1, prossimoNumero);
                pstmt.setLong(2, System.currentTimeMillis());
                pstmt.setDouble(3, carrello.getTotale());
                pstmt.executeUpdate();
            }

            // 2. Salva ogni singolo articolo dello scontrino
            try (PreparedStatement pstmtDet = conn.prepareStatement(sqlDettaglio)) {
                for (Map.Entry<Prodotto, Integer> entry : carrello.getProdotti().entrySet()) {
                    pstmtDet.setInt(1, prossimoNumero);
                    pstmtDet.setString(2, entry.getKey().getNome());
                    pstmtDet.setInt(3, entry.getValue()); // Quantità
                    pstmtDet.setDouble(4, entry.getKey().getPrezzo() * entry.getValue()); // Prezzo riga
                    pstmtDet.executeUpdate();
                }
            }
            return prossimoNumero;
        }
    }

    public double calcolaIncassoTotale() {
        String sql = "SELECT SUM(totale) AS incasso FROM ordine";
        try (Connection conn = DriverManager.getConnection(URL);
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) return rs.getDouble("incasso");
        } catch (SQLException e) {}
        return 0.0;
    }

    // NUOVO: Crea la statistica per il report di chiusura
    public Map<String, double[]> generaReportArticoli() {
        Map<String, double[]> report = new LinkedHashMap<>();
        // Somma le quantità e gli incassi raggruppandoli per nome prodotto
        String sql = "SELECT nome_prodotto, SUM(quantita) as tot_qta, SUM(prezzo_totale) as tot_prezzo FROM dettaglio_ordine GROUP BY nome_prodotto ORDER BY nome_prodotto";

        try (Connection conn = DriverManager.getConnection(URL);
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {

            while (rs.next()) {
                double[] valori = new double[2];
                valori[0] = rs.getInt("tot_qta");
                valori[1] = rs.getDouble("tot_prezzo");
                report.put(rs.getString("nome_prodotto"), valori);
            }
        } catch (SQLException e) {
            System.err.println("Errore report: " + e.getMessage());
        }
        return report;
    }

    private int ottieniProssimoNumeroScontrino() throws SQLException {
        String sql = "SELECT MAX(numero_scontrino) AS max_num FROM ordine";
        try (Connection conn = DriverManager.getConnection(URL);
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) return rs.getInt("max_num") + 1;
        }
        return 1;
    }
}