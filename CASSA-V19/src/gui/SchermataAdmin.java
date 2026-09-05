package gui;

import dao.ProdottoDAO;
import model.Prodotto;

import javax.swing.*;
import java.awt.*;

public class SchermataAdmin extends JPanel {
    private JTextField txtNome;
    private JTextField txtPrezzo;
    private BottoneModerno btnSalva;
    private ProdottoDAO prodottoDAO;
    private FinestraPrincipale mainFrame;

    // Nuovi elementi per scegliere la categoria
    private JRadioButton radioCibo;
    private JRadioButton radioBevanda;
    private ButtonGroup gruppoCategoria;

    public SchermataAdmin(FinestraPrincipale main) {
        this.mainFrame = main;
        prodottoDAO = new ProdottoDAO();

        setLayout(new BorderLayout());
        setBackground(new Color(245, 246, 250));

        // --- BARRA SUPERIORE (Navigazione) ---
        JPanel panelNord = new JPanel(new BorderLayout());
        panelNord.setBackground(new Color(245, 246, 250));
        panelNord.setBorder(BorderFactory.createEmptyBorder(15, 15, 15, 15));

        BottoneModerno btnHome = new BottoneModerno("◄ Torna alla Home", new Color(149, 165, 166), 15);
        btnHome.setPreferredSize(new Dimension(180, 45));
        btnHome.addActionListener(e -> mainFrame.navigaA("HOME"));

        JLabel lblTitoloTop = new JLabel("Pannello Amministrazione", SwingConstants.CENTER);
        lblTitoloTop.setFont(new Font("Segoe UI", Font.BOLD, 22));
        lblTitoloTop.setForeground(new Color(44, 62, 80));

        panelNord.add(btnHome, BorderLayout.WEST);
        panelNord.add(lblTitoloTop, BorderLayout.CENTER);
        add(panelNord, BorderLayout.NORTH);

        // --- AREA CENTRALE (Scheda di Inserimento Centrata) ---
        JPanel wrapperCentrale = new JPanel(new GridBagLayout());
        wrapperCentrale.setBackground(new Color(245, 246, 250));

        // Scheda bianca allungata per farci stare la nuova opzione
        JPanel formCard = new JPanel();
        formCard.setLayout(new BoxLayout(formCard, BoxLayout.Y_AXIS));
        formCard.setBackground(Color.WHITE);
        formCard.setPreferredSize(new Dimension(450, 450)); // Aumentata l'altezza
        formCard.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(220, 220, 220), 1, true),
                BorderFactory.createEmptyBorder(30, 40, 30, 40)
        ));

        // Titolo interno alla scheda
        JLabel lblTitoloScheda = new JLabel("Nuovo Prodotto");
        lblTitoloScheda.setFont(new Font("Segoe UI", Font.BOLD, 24));
        lblTitoloScheda.setAlignmentX(Component.CENTER_ALIGNMENT);
        formCard.add(lblTitoloScheda);
        formCard.add(Box.createRigidArea(new Dimension(0, 30)));

        // Campo Nome
        JLabel lblNome = new JLabel("Nome Prodotto:");
        lblNome.setFont(new Font("Segoe UI", Font.BOLD, 15));
        lblNome.setAlignmentX(Component.LEFT_ALIGNMENT);
        formCard.add(lblNome);
        formCard.add(Box.createRigidArea(new Dimension(0, 5)));

        txtNome = new JTextField();
        txtNome.setFont(new Font("Segoe UI", Font.PLAIN, 16));
        txtNome.setMaximumSize(new Dimension(Integer.MAX_VALUE, 40));
        txtNome.setAlignmentX(Component.LEFT_ALIGNMENT);
        formCard.add(txtNome);
        formCard.add(Box.createRigidArea(new Dimension(0, 20)));

        // Campo Prezzo
        JLabel lblPrezzo = new JLabel("Prezzo (€):");
        lblPrezzo.setFont(new Font("Segoe UI", Font.BOLD, 15));
        lblPrezzo.setAlignmentX(Component.LEFT_ALIGNMENT);
        formCard.add(lblPrezzo);
        formCard.add(Box.createRigidArea(new Dimension(0, 5)));

        txtPrezzo = new JTextField();
        txtPrezzo.setFont(new Font("Segoe UI", Font.PLAIN, 16));
        txtPrezzo.setMaximumSize(new Dimension(Integer.MAX_VALUE, 40));
        txtPrezzo.setAlignmentX(Component.LEFT_ALIGNMENT);
        formCard.add(txtPrezzo);
        formCard.add(Box.createRigidArea(new Dimension(0, 20)));

        // --- NUOVO SELETTORE CATEGORIA (Cibo/Bevanda) ---
        JLabel lblCategoria = new JLabel("Categoria Prodotto:");
        lblCategoria.setFont(new Font("Segoe UI", Font.BOLD, 15));
        lblCategoria.setAlignmentX(Component.LEFT_ALIGNMENT);
        formCard.add(lblCategoria);

        JPanel panelRadio = new JPanel(new FlowLayout(FlowLayout.LEFT, 10, 0));
        panelRadio.setBackground(Color.WHITE);
        panelRadio.setAlignmentX(Component.LEFT_ALIGNMENT);

        radioCibo = new JRadioButton("Cibo (Arancione)");
        radioCibo.setFont(new Font("Segoe UI", Font.PLAIN, 15));
        radioCibo.setBackground(Color.WHITE);
        radioCibo.setSelected(true); // Selezionato di default

        radioBevanda = new JRadioButton("Bevanda (Blu)");
        radioBevanda.setFont(new Font("Segoe UI", Font.PLAIN, 15));
        radioBevanda.setBackground(Color.WHITE);

        gruppoCategoria = new ButtonGroup();
        gruppoCategoria.add(radioCibo);
        gruppoCategoria.add(radioBevanda);

        panelRadio.add(radioCibo);
        panelRadio.add(radioBevanda);

        formCard.add(panelRadio);
        formCard.add(Box.createRigidArea(new Dimension(0, 30)));

        // Pulsante di Salvataggio
        btnSalva = new BottoneModerno("Salva nel Listino", new Color(41, 128, 185), 15);
        btnSalva.setMaximumSize(new Dimension(Integer.MAX_VALUE, 50));
        btnSalva.setAlignmentX(Component.CENTER_ALIGNMENT);
        btnSalva.addActionListener(e -> salvaDati());
        formCard.add(btnSalva);

        wrapperCentrale.add(formCard);
        add(wrapperCentrale, BorderLayout.CENTER);
    }

    private void salvaDati() {
        try {
            String nome = txtNome.getText().trim();
            if (nome.isEmpty()) {
                JOptionPane.showMessageDialog(this, "Inserisci un nome valido per il prodotto.", "Errore", JOptionPane.WARNING_MESSAGE);
                return;
            }

            double prezzo = Double.parseDouble(txtPrezzo.getText().replace(",", "."));

            // 1 = Cibo, 2 = Bevande
            int idGruppoScelto = radioCibo.isSelected() ? 1 : 2;

            // Creazione oggetto prodotto con l'ID Gruppo corretto
            Prodotto nuovoProdotto = new Prodotto(0, idGruppoScelto, nome, prezzo, 0, false);

            prodottoDAO.inserisciProdotto(nuovoProdotto);

            JOptionPane.showMessageDialog(this, "Prodotto salvato con successo nel database!", "Successo", JOptionPane.INFORMATION_MESSAGE);

            txtNome.setText("");
            txtPrezzo.setText("");
            radioCibo.setSelected(true); // Riporta il pallino su "Cibo"
            txtNome.requestFocus();

        } catch (NumberFormatException ex) {
            JOptionPane.showMessageDialog(this,
                    "Errore: Inserisci un valore numerico valido per il prezzo (es. 2.50).",
                    "Errore di formattazione",
                    JOptionPane.ERROR_MESSAGE);
        }
    }
}