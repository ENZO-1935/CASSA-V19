package dao;

import model.Prodotto;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ProdottoDAO {
    // Stesso percorso del file usato nel DatabaseManager
    private static final String URL = "jdbc:sqlite:cassa_sagra.db";

    // Metodo per salvare un nuovo prodotto nel database
    public void inserisciProdotto(Prodotto prodotto) {
        String sql = "INSERT INTO prodotto(id_gruppo, nome, prezzo, quantita_disponibile, is_buono_sconto) VALUES(?,?,?,?,?)";

        try (Connection conn = DriverManager.getConnection(URL);
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, prodotto.getIdGruppo());
            pstmt.setString(2, prodotto.getNome());
            pstmt.setDouble(3, prodotto.getPrezzo());
            pstmt.setInt(4, prodotto.getQuantitaDisponibile());
            pstmt.setInt(5, prodotto.isBuonoSconto() ? 1 : 0); // SQLite gestisce i boolean come 1 o 0

            pstmt.executeUpdate();
            System.out.println("Salvato nel DB: " + prodotto.getNome());

        } catch (SQLException e) {
            System.out.println("Errore inserimento: " + e.getMessage());
        }
    }

    // Metodo per leggere tutti i prodotti (servirà per disegnare i bottoni sulla cassa)
    public List<Prodotto> ottieniTuttiProdotti() {
        List<Prodotto> lista = new ArrayList<>();
        String sql = "SELECT * FROM prodotto";

        try (Connection conn = DriverManager.getConnection(URL);
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {

            while (rs.next()) {
                Prodotto p = new Prodotto(
                        rs.getInt("id_prodotto"),
                        rs.getInt("id_gruppo"),
                        rs.getString("nome"),
                        rs.getDouble("prezzo"),
                        rs.getInt("quantita_disponibile"),
                        rs.getInt("is_buono_sconto") == 1
                );
                lista.add(p);
            }
        } catch (SQLException e) {
            System.out.println("Errore lettura: " + e.getMessage());
        }
        return lista;
    }
}