package gui;

import dao.OrdineDAO;
import dao.ProdottoDAO;
import hardware.GestoreStampa;
import model.Carrello;
import model.Prodotto;

import javax.swing.*;
import java.awt.*;
import java.util.List;
import java.util.Map;

public class SchermataCassa extends JPanel {

    private JPanel panelListaScontrino;
    private JPanel panelGriglia;
    private JLabel lblTotale;
    private BottoneModerno btnPaga;
    private Carrello carrello;
    private ProdottoDAO prodottoDAO;
    private FinestraPrincipale mainFrame;

    public SchermataCassa(FinestraPrincipale main) {
        this.mainFrame = main;
        carrello = Carrello.getInstance();
        prodottoDAO = new ProdottoDAO();

        setLayout(new BorderLayout());
        setBackground(new Color(245, 246, 250));

        // --- BARRA SUPERIORE ---
        JPanel panelNord = new JPanel(new BorderLayout());
        panelNord.setBackground(new Color(245, 246, 250));
        panelNord.setBorder(BorderFactory.createEmptyBorder(10, 15, 10, 15));

        BottoneModerno btnHome = new BottoneModerno("◄ Torna alla Home", new Color(149, 165, 166), 15);
        btnHome.setPreferredSize(new Dimension(180, 45));
        btnHome.addActionListener(e -> mainFrame.navigaA("HOME"));

        JLabel lblTitolo = new JLabel("Cassa - Modalità Vendita", SwingConstants.CENTER);
        lblTitolo.setFont(new Font("Segoe UI", Font.BOLD, 22));
        lblTitolo.setForeground(new Color(44, 62, 80));

        panelNord.add(btnHome, BorderLayout.WEST);
        panelNord.add(lblTitolo, BorderLayout.CENTER);
        add(panelNord, BorderLayout.NORTH);

        // --- ZONA PRODOTTI (Sinistra) ---
        panelGriglia = new JPanel(new GridLayout(0, 3, 15, 15));
        panelGriglia.setBackground(new Color(245, 246, 250));

        JPanel panelProdotti = new JPanel(new BorderLayout());
        panelProdotti.setBackground(new Color(245, 246, 250));
        panelProdotti.setBorder(BorderFactory.createEmptyBorder(10, 15, 15, 15));
        panelProdotti.add(panelGriglia, BorderLayout.NORTH);

        JScrollPane scrollProdotti = new JScrollPane(panelProdotti);
        scrollProdotti.getVerticalScrollBar().setUnitIncrement(16);
        scrollProdotti.setBorder(null);
        scrollProdotti.getViewport().setBackground(new Color(245, 246, 250));

        // --- ZONA SCONTRINO (Destra) ---
        JPanel panelScontrino = new JPanel(new BorderLayout());
        panelScontrino.setPreferredSize(new Dimension(400, 0));
        panelScontrino.setBorder(BorderFactory.createMatteBorder(0, 2, 0, 0, new Color(220, 220, 220)));

        panelListaScontrino = new JPanel();
        panelListaScontrino.setLayout(new BoxLayout(panelListaScontrino, BoxLayout.Y_AXIS));
        panelListaScontrino.setBackground(Color.WHITE);

        JScrollPane scrollScontrino = new JScrollPane(panelListaScontrino);
        scrollScontrino.getVerticalScrollBar().setUnitIncrement(16);
        scrollScontrino.setBorder(null);
        panelScontrino.add(scrollScontrino, BorderLayout.CENTER);

        JPanel panelInferioreDestra = new JPanel(new BorderLayout());
        panelInferioreDestra.setBackground(Color.WHITE);
        panelInferioreDestra.setBorder(BorderFactory.createEmptyBorder(15, 15, 15, 15));

        lblTotale = new JLabel("Totale: 0.00 €", SwingConstants.CENTER);
        lblTotale.setFont(new Font("Segoe UI", Font.BOLD, 26));
        lblTotale.setForeground(new Color(39, 174, 96));
        panelInferioreDestra.add(lblTotale, BorderLayout.NORTH);

        // Abbiamo cambiato le righe a 3 per far spazio al nuovo bottone!
        JPanel panelPulsanti = new JPanel(new GridLayout(3, 1, 0, 12));
        panelPulsanti.setBackground(Color.WHITE);
        panelPulsanti.setBorder(BorderFactory.createEmptyBorder(15, 0, 0, 0));

        // NUOVO BOTTONE MODIFICA
        BottoneModerno btnModifica = new BottoneModerno("Modifica Listino", new Color(243, 156, 18), 15);
        btnModifica.setPreferredSize(new Dimension(0, 50));
        btnModifica.addActionListener(e -> apriPopupModifica());

        BottoneModerno btnSvuota = new BottoneModerno("Svuota Tutto", new Color(231, 76, 60), 15);
        btnSvuota.setPreferredSize(new Dimension(0, 50));
        btnSvuota.addActionListener(e -> svuotaTutto());

        btnPaga = new BottoneModerno("Stampa Scontrino", new Color(39, 174, 96), 15);
        btnPaga.setPreferredSize(new Dimension(0, 70));
        btnPaga.addActionListener(e -> chiudiScontrino());

        panelPulsanti.add(btnModifica);
        panelPulsanti.add(btnSvuota);
        panelPulsanti.add(btnPaga);

        panelInferioreDestra.add(panelPulsanti, BorderLayout.CENTER);
        panelScontrino.add(panelInferioreDestra, BorderLayout.SOUTH);

        add(scrollProdotti, BorderLayout.CENTER);
        add(panelScontrino, BorderLayout.EAST);

        this.addComponentListener(new java.awt.event.ComponentAdapter() {
            @Override
            public void componentShown(java.awt.event.ComponentEvent e) {
                aggiornaListinoBottoni();
            }
        });

        aggiornaVisualizzazione();
    }

    // --- NUOVO METODO PER IL POPUP ---
    private void apriPopupModifica() {
        // Recupera la finestra principale per sovrapporre il popup
        Window parentWindow = SwingUtilities.getWindowAncestor(this);
        PopupModificaProdotti popup = new PopupModificaProdotti((Frame) parentWindow);
        popup.setVisible(true); // L'esecuzione del programma si "ferma" qui finché non chiudi il popup

        // Appena il popup viene chiuso, ricarichiamo i bottoni!
        aggiornaListinoBottoni();

        // Svuotiamo il carrello per evitare scontrini errati con prodotti appena eliminati o modificati
        carrello.svuota();
        aggiornaVisualizzazione();
    }

    private void aggiornaListinoBottoni() {
        panelGriglia.removeAll();

        List<Prodotto> menu = prodottoDAO.ottieniTuttiProdotti();

        for (Prodotto p : menu) {
            Color coloreGruppo = (p.getIdGruppo() == 1) ? new Color(243, 156, 18) : new Color(41, 128, 185);

            BottoneModerno btn = new BottoneModerno("<html><center>" + p.getNome() + "<br><br><b>" +
                    String.format("%.2f", p.getPrezzo()) + "€</b></center></html>", coloreGruppo, 20);

            btn.setPreferredSize(new Dimension(130, 130));

            btn.addActionListener(e -> {
                carrello.aggiungiProdotto(p);
                aggiornaVisualizzazione();
            });
            panelGriglia.add(btn);
        }

        panelGriglia.revalidate();
        panelGriglia.repaint();
    }

    private void aggiornaVisualizzazione() {
        panelListaScontrino.removeAll();

        for (Map.Entry<Prodotto, Integer> entry : carrello.getProdotti().entrySet()) {
            Prodotto p = entry.getKey();
            int q = entry.getValue();
            double totaleRiga = p.getPrezzo() * q;

            JPanel rigaPanel = new JPanel(new BorderLayout(10, 0));
            rigaPanel.setBackground(Color.WHITE);
            rigaPanel.setMaximumSize(new Dimension(Integer.MAX_VALUE, 50));
            rigaPanel.setBorder(BorderFactory.createCompoundBorder(
                    BorderFactory.createMatteBorder(0, 0, 1, 0, new Color(230, 230, 230)),
                    BorderFactory.createEmptyBorder(5, 10, 5, 10)
            ));

            JLabel lblTesto = new JLabel(q + "x " + p.getNome() + " - " + String.format("%.2f", totaleRiga) + "€");
            lblTesto.setFont(new Font("Segoe UI", Font.BOLD, 16));

            BottoneModerno btnMeno = new BottoneModerno("-", new Color(231, 76, 60), 10);
            btnMeno.setPreferredSize(new Dimension(40, 40));
            btnMeno.addActionListener(e -> {
                carrello.rimuoviProdotto(p);
                aggiornaVisualizzazione();
            });

            rigaPanel.add(lblTesto, BorderLayout.CENTER);
            rigaPanel.add(btnMeno, BorderLayout.EAST);

            panelListaScontrino.add(rigaPanel);
        }

        lblTotale.setText("Totale: " + String.format("%.2f", carrello.getTotale()) + " €");

        panelListaScontrino.revalidate();
        panelListaScontrino.repaint();
    }

    private void svuotaTutto() {
        if (carrello.getTotale() == 0) return;

        int scelta = JOptionPane.showConfirmDialog(this,
                "Sei sicuro di voler ANNULLARE TUTTO l'ordine in corso?",
                "Conferma Cancellazione",
                JOptionPane.YES_NO_OPTION,
                JOptionPane.ERROR_MESSAGE);

        if (scelta == JOptionPane.YES_OPTION) {
            carrello.svuota();
            aggiornaVisualizzazione();
        }
    }

    private void chiudiScontrino() {
        if (carrello.getTotale() == 0) return;

        btnPaga.setEnabled(false);
        btnPaga.setText("Elaborazione...");

        try {
            OrdineDAO ordineDAO = new OrdineDAO();
            int numeroScontrino = ordineDAO.salvaOrdine(carrello);

            GestoreStampa stampante = new GestoreStampa();
            stampante.stampaScontrino(carrello, numeroScontrino);

            JOptionPane.showMessageDialog(this,
                    "Ordine salvato!\nSCONTRINO N° " + numeroScontrino + "\nTotale: " + String.format("%.2f", carrello.getTotale()) + "€",
                    "Operazione Riuscita",
                    JOptionPane.INFORMATION_MESSAGE);

            carrello.svuota();
            aggiornaVisualizzazione();

        } catch (Exception ex) {
            JOptionPane.showMessageDialog(this,
                    "ERRORE CRITICO DI SALVATAGGIO!\nIl database non ha registrato l'ordine.\n\nDettagli: " + ex.getMessage(),
                    "Errore Sistema",
                    JOptionPane.ERROR_MESSAGE);
        } finally {
            btnPaga.setEnabled(true);
            btnPaga.setText("Stampa Scontrino");
        }
    }
}