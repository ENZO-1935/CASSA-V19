package dao;

import model.Prodotto;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ProdottoDAO {
    private static final String URL = "jdbc:sqlite:cassa_sagra.db";

    public void inserisciProdotto(Prodotto prodotto) {
        String sql = "INSERT INTO prodotto(nome, prezzo, id_gruppo) VALUES (?, ?, ?)";

        try (Connection conn = DriverManager.getConnection(URL);
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, prodotto.getNome());
            pstmt.setDouble(2, prodotto.getPrezzo());
            pstmt.setInt(3, prodotto.getIdGruppo());
            pstmt.executeUpdate();

        } catch (SQLException e) {
            System.err.println("Errore inserimento prodotto: " + e.getMessage());
        }
    }

    // Nome unificato per essere richiamato correttamente da SchermataCassa
    public List<Prodotto> ottieniTuttiProdotti() {
        List<Prodotto> prodotti = new ArrayList<>();
        String sql = "SELECT id, nome, prezzo, id_gruppo FROM prodotto";

        try (Connection conn = DriverManager.getConnection(URL);
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {

            while (rs.next()) {
                int id = rs.getInt("id");
                String nome = rs.getString("nome");
                double prezzo = rs.getDouble("prezzo");
                int idGruppo = rs.getInt("id_gruppo");

                Prodotto p = new Prodotto(id, idGruppo, nome, prezzo, 0, false);
                prodotti.add(p);
            }

        } catch (SQLException e) {
            System.err.println("Errore lettura prodotti: " + e.getMessage());
        }

        return prodotti;
    }
}