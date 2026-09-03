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
            try (PreparedStatement pstmt = conn.prepareStatement(sqlOrdine)) {
                pstmt.setInt(1, prossimoNumero);
                pstmt.setLong(2, System.currentTimeMillis());
                pstmt.setDouble(3, carrello.getTotale());
                pstmt.executeUpdate();
            }

            try (PreparedStatement pstmtDet = conn.prepareStatement(sqlDettaglio)) {
                for (Map.Entry<Prodotto, Integer> entry : carrello.getProdotti().entrySet()) {
                    pstmtDet.setInt(1, prossimoNumero);
                    pstmtDet.setString(2, entry.getKey().getNome());
                    pstmtDet.setInt(3, entry.getValue());
                    pstmtDet.setDouble(4, entry.getKey().getPrezzo() * entry.getValue());
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
        } catch (SQLException e) {
            System.err.println("Errore calcolo incasso: " + e.getMessage());
        }
        return 0.0;
    }

    public Map<String, double[]> generaReportArticoli() {
        Map<String, double[]> report = new LinkedHashMap<>();
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
            if (rs.next()) {
                int max = rs.getInt("max_num");
                return max > 0 ? max + 1 : 1;
            }
        }
        return 1;
    }

    public void svuotaTuttoDefinitivo() {
        try (Connection conn = DriverManager.getConnection(URL);
             Statement stmt = conn.createStatement()) {
            stmt.execute("DELETE FROM ordine");
            stmt.execute("DELETE FROM dettaglio_ordine");
            stmt.execute("DELETE FROM prodotto");
        } catch (SQLException e) {
            System.err.println("Errore azzeramento totale: " + e.getMessage());
        }
    }
}