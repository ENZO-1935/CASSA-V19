import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/prodotto.dart';
import '../models/evento_archiviato.dart';
import 'cassa_screen.dart';
import 'listino_screen.dart';
import 'statistiche_screen.dart';
import 'storico_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _indiceSelezionato = 0;
  List<Prodotto> _prodottiGlobali = [];
  List<EventoArchiviato> _eventiPassati = [];

  // Dati statistici evento corrente
  double _incassoTotale = 0.0;
  int _numeroScontrini = 0;
  Map<String, int> _prodottiVenduti = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _caricaDatiSalvati();
  }

  Future<void> _caricaDatiSalvati() async {
    final prefs = await SharedPreferences.getInstance();

    // Carica prodotti
    final String? prodottiString = prefs.getString('lista_prodotti');
    if (prodottiString != null) {
      final List decoded = jsonDecode(prodottiString);
      _prodottiGlobali = decoded.map((item) => Prodotto.fromJson(item)).toList();
    } else {
      _prodottiGlobali = [
        Prodotto(id: '1', nome: 'Birra', prezzo: 3.00, tipologia: 'bevanda'),
        Prodotto(id: '2', nome: 'Pizza', prezzo: 5.00, tipologia: 'cibo'),
        Prodotto(id: '3', nome: 'Acqua', prezzo: 1.00, tipologia: 'bevanda'),
        Prodotto(id: '4', nome: 'Spritz', prezzo: 3.50, tipologia: 'bevanda'),
        Prodotto(id: '5', nome: 'Panino', prezzo: 5.00, tipologia: 'cibo'),
      ];
    }

    // Carica storico eventi
    final String? storicoString = prefs.getString('storico_eventi');
    if (storicoString != null) {
      final List decodedStorico = jsonDecode(storicoString);
      _eventiPassati = decodedStorico.map((item) => EventoArchiviato.fromJson(item)).toList();
    }

    // Carica statistiche correnti
    _incassoTotale = prefs.getDouble('incasso_corrente') ?? 0.0;
    _numeroScontrini = prefs.getInt('scontrini_correnti') ?? 0;
    final String? vendutiString = prefs.getString('venduti_correnti');
    if (vendutiString != null) {
      _prodottiVenduti = Map<String, int>.from(jsonDecode(vendutiString));
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _salvaDatiCorrenti() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('incasso_corrente', _incassoTotale);
    await prefs.setInt('scontrini_correnti', _numeroScontrini);
    await prefs.setString('venduti_correnti', jsonEncode(_prodottiVenduti));
    await prefs.setString('lista_prodotti', jsonEncode(_prodottiGlobali.map((p) => p.toJson()).toList()));
  }

  Future<void> _salvaStorico() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('storico_eventi', jsonEncode(_eventiPassati.map((e) => e.toJson()).toList()));
  }

  // Registra scontrino dalla cassa
  void _registraVendita(Map<Prodotto, int> carrello, double totale) {
    setState(() {
      _incassoTotale += totale;
      _numeroScontrini += 1;

      carrello.forEach((prodotto, quantita) {
        if (_prodottiVenduti.containsKey(prodotto.nome)) {
          _prodottiVenduti[prodotto.nome] = _prodottiVenduti[prodotto.nome]! + quantita;
        } else {
          _prodottiVenduti[prodotto.nome] = quantita;
        }
      });
    });
    _salvaDatiCorrenti();
  }

  // Archivia e azzera (Punto 4)
  void _archiviaEazzera() {
    final nuovoEvento = EventoArchiviato(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      dataChiusura: DateTime.now().toString().substring(0, 16),
      incassoTotale: _incassoTotale,
      numeroScontriniEmessi: _numeroScontrini,
      prodottiVenduti: Map.from(_prodottiVenduti),
      prezziProdotti: {},
    );

    setState(() {
      _eventiPassati.add(nuovoEvento);
      // Azzera incassi, scontrini e listino come richiesto
      _incassoTotale = 0.0;
      _numeroScontrini = 0;
      _prodottiVenduti.clear();
      _prodottiGlobali.clear();
    });

    _salvaStorico();
    _salvaDatiCorrenti();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Evento archiviato con successo e dati azzerati!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.indigo)),
      );
    }

    final List<Widget> schermate = [
      const _HomeView(),
      ListinoScreen(
        prodotti: _prodottiGlobali,
        onAggiornato: () {
          setState(() {});
          _salvaDatiCorrenti();
        },
      ),
      CassaScreen(
        prodotti: _prodottiGlobali,
        onStampaScontrino: _registraVendita,
      ),
      StatisticheScreen(
        incassoTotale: _incassoTotale,
        numeroScontrini: _numeroScontrini,
        prodottiVenduti: _prodottiVenduti,
        onAggiorna: () => setState(() {}),
        onStampaChiusura: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Scontrino di chiusura stampato con successo!')),
          );
        },
        onArchiviaEazzera: _archiviaEazzera,
      ),
      StoricoScreen(
        eventiPassati: _eventiPassati,
        onAggiorna: () => setState(() {}),
        onEliminaEvento: (id) {
          setState(() {
            _eventiPassati.removeWhere((e) => e.id == id);
          });
          _salvaStorico();
        },
      ),
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
          Icon(Icons.home, size: 30, color: Colors.indigo),
          Icon(Icons.list_alt, size: 30, color: Colors.indigo),
          Icon(Icons.shopping_cart, size: 30, color: Colors.indigo),
          Icon(Icons.bar_chart, size: 30, color: Colors.indigo),
          Icon(Icons.history, size: 30, color: Colors.indigo),
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
            'CASSA-V19',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
        ],
      ),
    );
  }
}