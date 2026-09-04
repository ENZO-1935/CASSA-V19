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

public class SchermataCassa extends JFrame {
    private JPanel panelListaScontrino;
    private JPanel panelGriglia;
    private JLabel lblTotale;
    private JButton btnPaga;
    private Carrello carrello;
    private ProdottoDAO prodottoDAO;

    public SchermataCassa() {
        carrello = Carrello.getInstance();
        prodottoDAO = new ProdottoDAO();

        setTitle("Cassa Automatica Sagra - Modalità Vendita");
        setSize(1000, 700);
        setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
        setLayout(new BorderLayout());

        panelGriglia = new JPanel(new GridLayout(0, 3, 15, 15));

        JPanel panelProdotti = new JPanel(new BorderLayout());
        panelProdotti.setBorder(BorderFactory.createEmptyBorder(15, 15, 15, 15));
        panelProdotti.add(panelGriglia, BorderLayout.NORTH);

        JScrollPane scrollProdotti = new JScrollPane(panelProdotti);
        scrollProdotti.getVerticalScrollBar().setUnitIncrement(16);
        scrollProdotti.setBorder(null);

        JPanel panelScontrino = new JPanel(new BorderLayout());
        panelScontrino.setPreferredSize(new Dimension(400, 0));

        panelListaScontrino = new JPanel();
        panelListaScontrino.setLayout(new BoxLayout(panelListaScontrino, BoxLayout.Y_AXIS));
        panelListaScontrino.setBackground(Color.WHITE);

        JScrollPane scrollScontrino = new JScrollPane(panelListaScontrino);
        scrollScontrino.getVerticalScrollBar().setUnitIncrement(16);
        panelScontrino.add(scrollScontrino, BorderLayout.CENTER);

        JPanel panelInferioreDestra = new JPanel(new BorderLayout());
        panelInferioreDestra.setBorder(BorderFactory.createEmptyBorder(10, 5, 5, 5));

        lblTotale = new JLabel("Totale: 0.00 €", SwingConstants.CENTER);
        lblTotale.setFont(new Font("Arial", Font.BOLD, 26));
        panelInferioreDestra.add(lblTotale, BorderLayout.NORTH);

        JPanel panelPulsanti = new JPanel(new GridLayout(2, 1, 0, 10));
        panelPulsanti.setBorder(BorderFactory.createEmptyBorder(15, 0, 0, 0));

        JButton btnSvuota = new JButton("Svuota Tutto");
        btnSvuota.setBackground(new Color(220, 20, 60));
        btnSvuota.setForeground(Color.WHITE);
        btnSvuota.setFont(new Font("Arial", Font.BOLD, 18));
        btnSvuota.addActionListener(e -> svuotaTutto());

        btnPaga = new JButton("Stampa Scontrino");
        btnPaga.setBackground(new Color(34, 139, 34));
        btnPaga.setForeground(Color.WHITE);
        btnPaga.setFont(new Font("Arial", Font.BOLD, 22));
        btnPaga.setPreferredSize(new Dimension(0, 70));
        btnPaga.addActionListener(e -> chiudiScontrino());

        panelPulsanti.add(btnSvuota);
        panelPulsanti.add(btnPaga);

        panelInferioreDestra.add(panelPulsanti, BorderLayout.CENTER);
        panelScontrino.add(panelInferioreDestra, BorderLayout.SOUTH);

        add(scrollProdotti, BorderLayout.CENTER);
        add(panelScontrino, BorderLayout.EAST);
        setLocationRelativeTo(null);

        // EVENTO INFALLIBILE: Scatta ogni volta che la finestra viene cliccata o aperta
        addWindowListener(new java.awt.event.WindowAdapter() {
            @Override
            public void windowActivated(java.awt.event.WindowEvent e) {
                aggiornaListinoBottoni();
            }
        });

        aggiornaVisualizzazione();
    }

    // Metodo dedicato esclusivamente a svuotare e ricaricare i bottoni
    private void aggiornaListinoBottoni() {
        panelGriglia.removeAll();

        List<Prodotto> menu = prodottoDAO.ottieniTuttiProdotti();
        System.out.println("DEBUG - Prodotti trovati nel database: " + menu.size()); // Controlla la console!

        for (Prodotto p : menu) {
            JButton btn = new JButton("<html><center>" + p.getNome() + "<br><br><b>" +
                    String.format("%.2f", p.getPrezzo()) + "€</b></center></html>");

            btn.setPreferredSize(new Dimension(130, 130));
            btn.setFont(new Font("Arial", Font.PLAIN, 15));
            btn.setFocusPainted(false);
            btn.setBorder(BorderFactory.createLineBorder(Color.GRAY, 1));

            if (p.getIdGruppo() == 1) {
                btn.setBackground(new Color(255, 235, 156));
            } else {
                btn.setBackground(new Color(189, 215, 238));
            }

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
            rigaPanel.setMaximumSize(new Dimension(Integer.MAX_VALUE, 45));
            rigaPanel.setBorder(BorderFactory.createCompoundBorder(
                    BorderFactory.createMatteBorder(0, 0, 1, 0, new Color(220, 220, 220)),
                    BorderFactory.createEmptyBorder(5, 10, 5, 10)
            ));

            JLabel lblTesto = new JLabel(q + "x " + p.getNome() + " - " + String.format("%.2f", totaleRiga) + "€");
            lblTesto.setFont(new Font("Arial", Font.BOLD, 15));

            JButton btnMeno = new JButton("-");
            btnMeno.setFont(new Font("Arial", Font.BOLD, 16));
            btnMeno.setBackground(new Color(255, 99, 71));
            btnMeno.setForeground(Color.WHITE);
            btnMeno.setMargin(new Insets(2, 8, 2, 8));
            btnMeno.setFocusPainted(false);

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