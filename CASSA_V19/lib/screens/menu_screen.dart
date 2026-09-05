import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../models/prodotto.dart';
import 'cassa_screen.dart';
import 'listino_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _indiceSelezionato = 0;

  // Lista globale condivisa tra Listino e Cassa
  final List<Prodotto> _prodottiGlobali = [
    Prodotto(id: '1', nome: 'Birra', prezzo: 3.00, tipologia: 'bevanda'),
    Prodotto(id: '2', nome: 'Pizza', prezzo: 5.00, tipologia: 'cibo'),
    Prodotto(id: '3', nome: 'Acqua', prezzo: 1.00, tipologia: 'bevanda'),
    Prodotto(id: '4', nome: 'Spritz', prezzo: 3.50, tipologia: 'bevanda'),
    Prodotto(id: '5', nome: 'Panino', prezzo: 5.00, tipologia: 'cibo'),
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> schermate = [
      const _HomeView(),
      ListinoScreen(
        prodotti: _prodottiGlobali,
        onAggiornato: () => setState(() {}),
      ),
      CassaScreen(prodotti: _prodottiGlobali),
      const Center(child: Text('Statistiche (in arrivo)')),
      const Center(child: Text('Storico (in arrivo)')),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: schermate[_indiceSelezionato],
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.grey.shade100,
        color: Colors.white,
        buttonBackgroundColor: Colors.white,
        animationDuration: const Duration(milliseconds: 300),
        index: _indiceSelezionato,
        onTap: (int index) {
          setState(() {
            _indiceSelezionato = index;
          });
        },
        items: const [
          Icon(Icons.home, size: 30, color: Colors.deepOrange),
          Icon(Icons.list_alt, size: 30, color: Colors.deepOrange),
          Icon(Icons.shopping_cart, size: 30, color: Colors.deepOrange),
          Icon(Icons.bar_chart, size: 30, color: Colors.deepOrange),
          Icon(Icons.history, size: 30, color: Colors.deepOrange),
        ],
      ),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/logo.png', height: 220),
          const SizedBox(height: 30),
          const Text(
            'SAGRA PAESANA v19',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepOrange),
          ),
        ],
      ),
    );
  }
}