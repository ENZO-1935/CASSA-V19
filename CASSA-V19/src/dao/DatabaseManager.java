package dao;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;

public class DatabaseManager {
    // Percorso fisso del database nella cartella principale del progetto
    private static final String URL = "jdbc:sqlite:cassa_sagra.db";

    public static void inizializzaDatabase() {
        try {
            Class.forName("org.sqlite.JDBC");

            try (Connection conn = DriverManager.getConnection(URL);
                 Statement stmt = conn.createStatement()) {

                // Creazione tabella prodotti se non esiste
                stmt.execute("CREATE TABLE IF NOT EXISTS prodotto ("
                        + "id INTEGER PRIMARY KEY AUTOINCREMENT,"
                        + "nome TEXT NOT NULL,"
                        + "prezzo REAL NOT NULL,"
                        + "id_gruppo INTEGER DEFAULT 1);");

                // Creazione tabella ordini se non esiste
                stmt.execute("CREATE TABLE IF NOT EXISTS ordine ("
                        + "numero_scontrino INTEGER PRIMARY KEY,"
                        + "data_ora INTEGER,"
                        + "totale REAL);");

                // Creazione tabella dettagli ordine se non esiste
                stmt.execute("CREATE TABLE IF NOT EXISTS dettaglio_ordine ("
                        + "numero_scontrino INTEGER,"
                        + "nome_prodotto TEXT,"
                        + "quantita INTEGER,"
                        + "prezzo_totale REAL);");

                System.out.println("Database SQLite inizializzato correttamente su file.");

            }
        } catch (Exception e) {
            System.err.println("ERRORE INIZIALIZZAZIONE DATABASE: " + e.getMessage());
        }
    }
}