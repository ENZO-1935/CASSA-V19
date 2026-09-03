package dao;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;

public class DatabaseManager {
    private static final String URL = "jdbc:sqlite:cassa_sagra.db";

    public static void inizializzaDatabase() {
        try (Connection conn = DriverManager.getConnection(URL);
             Statement stmt = conn.createStatement()) {

            // 1. Mantiene il listino prodotti intatto
            String sqlProdotto = "CREATE TABLE IF NOT EXISTS prodotto ("
                    + "id INTEGER PRIMARY KEY AUTOINCREMENT,"
                    + "nome TEXT NOT NULL,"
                    + "prezzo REAL NOT NULL,"
                    + "id_gruppo INTEGER DEFAULT 1);";
            stmt.execute(sqlProdotto);

            // 2. FORZATURA: Elimina le vecchie tabelle degli ordini bloccate
            stmt.execute("DROP TABLE IF EXISTS ordine");
            stmt.execute("DROP TABLE IF EXISTS dettaglio_ordine");

            // 3. Ricrea le tabelle con la nuova struttura per il Report Z
            String sqlOrdine = "CREATE TABLE IF NOT EXISTS ordine ("
                    + "numero_scontrino INTEGER PRIMARY KEY,"
                    + "data_ora INTEGER,"
                    + "totale REAL);";
            stmt.execute(sqlOrdine);

            String sqlDettaglio = "CREATE TABLE IF NOT EXISTS dettaglio_ordine ("
                    + "numero_scontrino INTEGER,"
                    + "nome_prodotto TEXT,"
                    + "quantita INTEGER,"
                    + "prezzo_totale REAL);";
            stmt.execute(sqlDettaglio);

            System.out.println("Database allineato con successo.");

        } catch (Exception e) {
            System.out.println("Errore di inizializzazione DB: " + e.getMessage());
        }
    }
}