package gui;

import javax.swing.*;
import java.awt.*;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;

// Creiamo un bottone personalizzato disegnato da zero
public class BottoneModerno extends JButton {
    private Color coloreSfondo;
    private Color coloreHover;
    private int raggioBordo;

    public BottoneModerno(String testo, Color coloreBase, int raggio) {
        super(testo);
        this.coloreSfondo = coloreBase;
        // Calcola in automatico un colore leggermente più chiaro per l'effetto hover
        this.coloreHover = coloreBase.brighter();
        this.raggioBordo = raggio;

        // Togliamo i bordi e gli sfondi standard brutti di Java
        setContentAreaFilled(false);
        setFocusPainted(false);
        setBorderPainted(false);
        setOpaque(false);

        setForeground(Color.WHITE);
        setFont(new Font("Segoe UI", Font.BOLD, 15)); // Font più moderno
        setCursor(new Cursor(Cursor.HAND_CURSOR)); // Cursore a manina

        // Aggiungiamo l'animazione al passaggio del mouse
        addMouseListener(new MouseAdapter() {
            @Override
            public void mouseEntered(MouseEvent e) {
                coloreSfondo = coloreHover;
                repaint();
            }
            @Override
            public void mouseExited(MouseEvent e) {
                coloreSfondo = coloreBase;
                repaint();
            }
        });
    }

    // Qui diciamo a Java come "disegnare" fisicamente la forma del bottone
    @Override
    protected void paintComponent(Graphics g) {
        Graphics2D g2 = (Graphics2D) g.create();
        // Attiviamo l'anti-aliasing per avere bordi curvi morbidissimi e non seghettati
        g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

        g2.setColor(coloreSfondo);
        g2.fillRoundRect(0, 0, getWidth(), getHeight(), raggioBordo, raggioBordo);

        g2.dispose();
        super.paintComponent(g); // Disegna il testo sopra
    }
}