package gui;

import javax.imageio.ImageIO;
import javax.swing.*;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.InputStream;

public class MenuPrincipale extends JFrame {

    private BufferedImage logoScalato = null;
    private boolean logoCaricatoCorrettamente = false;

    public MenuPrincipale() {
        setTitle("Cassa Automatica Sagra - Menu Principale");
        setSize(500, 850); // Leggermente più alto per far respirare i pulsanti
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setLocationRelativeTo(null);
        setLayout(new BorderLayout());

        // Colore di sfondo moderno (Grigio chiarissimo "Cloud")
        getContentPane().setBackground(new Color(245, 246, 250));

        // Caricamento del logo (inalterato per mantenere la massima qualità)
        try {
            InputStream is = getClass().getResourceAsStream("/img/logo.png");
            if (is == null) is = getClass().getResourceAsStream("/logo.png");

            BufferedImage rawImage = null;
            if (is != null) {
                rawImage = ImageIO.read(is);
            } else {
                File fileLogo = new File("src/img/logo.png");
                if (!fileLogo.exists()) fileLogo = new File("img/logo.png");
                if (!fileLogo.exists()) fileLogo = new File("logo.png");

                if (fileLogo.exists()) {
                    rawImage = ImageIO.read(fileLogo);
                }
            }

            if (rawImage != null) {
                logoScalato = riduciImmagineAltaQualita(rawImage, 220, 220);
                BufferedImage iconaWin = riduciImmagineAltaQualita(rawImage, 64, 64);
                setIconImage(iconaWin);
                logoCaricatoCorrettamente = true;
            }
        } catch (Exception e) {
            System.out.println("Errore caricamento logo: " + e.getMessage());
        }

        JPanel panelContenuto = new JPanel();
        panelContenuto.setLayout(new BoxLayout(panelContenuto, BoxLayout.Y_AXIS));
        panelContenuto.setBorder(BorderFactory.createEmptyBorder(30, 20, 30, 20));
        panelContenuto.setBackground(new Color(245, 246, 250)); // Stesso sfondo

        JPanel panelLogo = new JPanel() {
            @Override
            protected void paintComponent(Graphics g) {
                super.paintComponent(g);
                if (logoCaricatoCorrettamente && logoScalato != null) {
                    Graphics2D g2d = (Graphics2D) g.create();
                    g2d.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
                    g2d.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
                    g2d.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

                    int x = (getWidth() - logoScalato.getWidth()) / 2;
                    int y = (getHeight() - logoScalato.getHeight()) / 2;
                    g2d.drawImage(logoScalato, x, y, this);
                    g2d.dispose();
                }
            }
        };

        panelLogo.setPreferredSize(new Dimension(220, 220));
        panelLogo.setMaximumSize(new Dimension(220, 220));
        panelLogo.setBackground(new Color(245, 246, 250));
        panelLogo.setAlignmentX(Component.CENTER_ALIGNMENT);
        panelContenuto.add(panelLogo);
        panelContenuto.add(Box.createRigidArea(new Dimension(0, 25)));

        // Titolo con Font moderno e colore blu notte scuro scuro
        JLabel lblTitolo = new JLabel("SAGRA PAESANA v19");
        lblTitolo.setFont(new Font("Segoe UI", Font.BOLD, 26));
        lblTitolo.setForeground(new Color(44, 62, 80));
        lblTitolo.setAlignmentX(Component.CENTER_ALIGNMENT);
        panelContenuto.add(lblTitolo);
        panelContenuto.add(Box.createRigidArea(new Dimension(0, 40)));

        // =========================================================================
        // QUI USIAMO LA TUA NUOVA CLASSE "BottoneModerno"
        // Formato: nuovo BottoneModerno("Testo", ColoreSfondo, RaggioArrotondamento)
        // =========================================================================

        // 1. Cassa (Verde Smeraldo opaco moderno)
        BottoneModerno btnCassa = new BottoneModerno("1. Apri Cassa (Vendita)", new Color(39, 174, 96), 25);
        impostaStileBottone(btnCassa);
        btnCassa.addActionListener(e -> new SchermataCassa().setVisible(true));
        panelContenuto.add(btnCassa);
        panelContenuto.add(Box.createRigidArea(new Dimension(0, 20))); // Spazio tra i bottoni

        // 2. Admin (Blu "Belize" moderno)
        BottoneModerno btnAdmin = new BottoneModerno("2. Gestione Listino (Admin)", new Color(41, 128, 185), 25);
        impostaStileBottone(btnAdmin);
        btnAdmin.addActionListener(e -> new SchermataAdmin().setVisible(true));
        panelContenuto.add(btnAdmin);
        panelContenuto.add(Box.createRigidArea(new Dimension(0, 20)));

        // 3. Statistiche (Arancione tramonto moderno)
        BottoneModerno btnStats = new BottoneModerno("3. Statistiche & Chiusura", new Color(243, 156, 18), 25);
        impostaStileBottone(btnStats);
        btnStats.addActionListener(e -> new SchermataStatistiche().setVisible(true));
        panelContenuto.add(btnStats);
        panelContenuto.add(Box.createRigidArea(new Dimension(0, 20)));

        // 4. Storico (Grigio cemento elegante)
        BottoneModerno btnStorico = new BottoneModerno("4. Storico Eventi Passati", new Color(149, 165, 166), 25);
        impostaStileBottone(btnStorico);
        btnStorico.addActionListener(e -> new SchermataStoricoEventi().setVisible(true));
        panelContenuto.add(btnStorico);

        add(panelContenuto, BorderLayout.CENTER);
    }

    // Metodo di utilità per non ripetere le dimensioni su ogni bottone
    private void impostaStileBottone(BottoneModerno btn) {
        btn.setAlignmentX(Component.CENTER_ALIGNMENT);
        btn.setPreferredSize(new Dimension(360, 60)); // Più alti (60px) per un look "App" touch
        btn.setMaximumSize(new Dimension(360, 60));
    }

    private BufferedImage riduciImmagineAltaQualita(BufferedImage src, int targetWidth, int targetHeight) {
        int currentWidth = src.getWidth();
        int currentHeight = src.getHeight();

        BufferedImage intermediateImg = src;

        while (currentWidth > targetWidth * 2 || currentHeight > targetHeight * 2) {
            currentWidth /= 2;
            currentHeight /= 2;
            if (currentWidth < targetWidth) currentWidth = targetWidth;
            if (currentHeight < targetHeight) currentHeight = targetHeight;

            BufferedImage temp = new BufferedImage(currentWidth, currentHeight, BufferedImage.TYPE_INT_ARGB);
            Graphics2D g2 = temp.createGraphics();
            g2.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
            g2.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
            g2.drawImage(intermediateImg, 0, 0, currentWidth, currentHeight, null);
            g2.dispose();
            intermediateImg = temp;
        }

        BufferedImage finalImg = new BufferedImage(targetWidth, targetHeight, BufferedImage.TYPE_INT_ARGB);
        Graphics2D gFinal = finalImg.createGraphics();
        gFinal.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
        gFinal.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
        gFinal.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        gFinal.drawImage(intermediateImg, 0, 0, targetWidth, targetHeight, null);
        gFinal.dispose();

        return finalImg;
    }
}