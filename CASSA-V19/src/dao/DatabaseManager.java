package dao;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;

public class DatabaseManager {
    private static final String URL_DB = "jdbc:sqlite:cassa_sagra.db";

    public static Connection connetti() throws SQLException {
        return DriverManager.getConnection(URL_DB);
    }

    public static void inizializzaDatabase() {
        creaTabellaProdotti();
        creaTabellaOrdini();
        creaTabellaDettaglioOrdini();
        creaTabellaStoricoEventi();
    }

    private static void creaTabellaProdotti() {
        String sql = "CREATE TABLE IF NOT EXISTS prodotti (" +
                "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "nome TEXT NOT NULL, " +
                "prezzo REAL NOT NULL, " +
                "categoria TEXT)";
        try (Connection conn = connetti(); Statement stmt = conn.createStatement()) {
            stmt.execute(sql);
        } catch (SQLException e) {
            System.out.println("Errore tabella prodotti: " + e.getMessage());
        }
    }

    private static void creaTabellaOrdini() {
        String sql = "CREATE TABLE IF NOT EXISTS ordini (" +
                "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "data_ora TEXT DEFAULT CURRENT_TIMESTAMP, " +
                "totale REAL NOT NULL)";
        try (Connection conn = connetti(); Statement stmt = conn.createStatement()) {
            stmt.execute(sql);
        } catch (SQLException e) {
            System.out.println("Errore tabella ordini: " + e.getMessage());
        }
    }

    private static void creaTabellaDettaglioOrdini() {
        String sql = "CREATE TABLE IF NOT EXISTS dettaglio_ordini (" +
                "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "ordine_id INTEGER, " +
                "prodotto_nome TEXT, " +
                "quantita INTEGER, " +
                "prezzo_unitario REAL)";
        try (Connection conn = connetti(); Statement stmt = conn.createStatement()) {
            stmt.execute(sql);
        } catch (SQLException e) {
            System.out.println("Errore tabella dettaglio_ordini: " + e.getMessage());
        }
    }

    public static void creaTabellaStoricoEventi() {
        String sql = "CREATE TABLE IF NOT EXISTS eventi_archiviati (" +
                "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "nome_evento TEXT NOT NULL, " +
                "data_chiusura TEXT DEFAULT CURRENT_TIMESTAMP, " +
                "incasso_totale REAL, " +
                "dettagli_vendite TEXT)";
        try (Connection conn = connetti(); Statement stmt = conn.createStatement()) {
            stmt.execute(sql);

            // Controllo di sicurezza: se la tabella esisteva già senza questa colonna, la aggiunge ora
            stmt.execute("ALTER TABLE eventi_archiviati ADD COLUMN dettagli_vendite TEXT");
        } catch (SQLException e) {
            // L'eccezione viene catturata nel caso in cui la colonna esista già (evita blocchi)
        }
    }
}