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
  final PageController _pageController = PageController(initialPage: 0);

  List<Prodotto> _prodottiGlobali = [];
  List<EventoArchiviato> _eventiPassati = [];
  String _nomeEvento = '';

  double _incassoTotale = 0.0;
  int _numeroScontrini = 0;
  Map<String, int> _prodottiVenduti = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _caricaDatiSalvati();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _caricaDatiSalvati() async {
    final prefs = await SharedPreferences.getInstance();

    String? nomeSalvato = prefs.getString('nome_evento');
    if (nomeSalvato == 'NESSUN EVENTO IMPOSTATO') nomeSalvato = '';
    _nomeEvento = nomeSalvato ?? '';

    final String? prodottiString = prefs.getString('lista_prodotti_v2');

    if (prodottiString != null) {
      final List decoded = jsonDecode(prodottiString);
      _prodottiGlobali = decoded.map((item) => Prodotto.fromJson(item)).toList();
    } else {
      _prodottiGlobali = [
        Prodotto(id: '1', nome: 'Birra', prezzo: 3.00, tipologia: 'bevanda'),
        Prodotto(id: '2', nome: 'Acqua', prezzo: 1.00, tipologia: 'bevanda'),
        Prodotto(id: '3', nome: 'Coca Cola', prezzo: 2.00, tipologia: 'bevanda'),
        Prodotto(id: '4', nome: 'Cocktail', prezzo: 5.00, tipologia: 'bevanda'),
        Prodotto(id: '5', nome: 'Campari', prezzo: 3.50, tipologia: 'bevanda'),
        Prodotto(id: '6', nome: 'Spritz', prezzo: 4.00, tipologia: 'bevanda'),
        Prodotto(id: '7', nome: 'Bicchiere di Vino', prezzo: 2.50, tipologia: 'bevanda'),
        Prodotto(id: '8', nome: 'Bottiglia di Vino', prezzo: 10.00, tipologia: 'bevanda'),
        Prodotto(id: '9', nome: 'Prosecco', prezzo: 3.00, tipologia: 'bevanda'),
        Prodotto(id: '10', nome: 'Cicchetto', prezzo: 2.00, tipologia: 'bevanda'),
        Prodotto(id: '11', nome: 'Caffè', prezzo: 1.00, tipologia: 'bevanda'),
        Prodotto(id: '12', nome: 'Pizza', prezzo: 5.00, tipologia: 'cibo'),
        Prodotto(id: '13', nome: 'Panino con Salsiccia', prezzo: 5.00, tipologia: 'cibo'),
        Prodotto(id: '14', nome: 'Panino con Wrustel', prezzo: 4.50, tipologia: 'cibo'),
        Prodotto(id: '15', nome: 'Provolone Impiccato', prezzo: 6.00, tipologia: 'cibo'),
        Prodotto(id: '16', nome: 'Focaccia', prezzo: 3.00, tipologia: 'cibo'),
        Prodotto(id: '17', nome: 'Pasta', prezzo: 5.50, tipologia: 'cibo'),
        Prodotto(id: '18', nome: 'Zeppole', prezzo: 2.50, tipologia: 'cibo'),
      ];
      _salvaDatiCorrenti();
    }

    final String? storicoString = prefs.getString('storico_eventi');
    if (storicoString != null) {
      final List decodedStorico = jsonDecode(storicoString);
      _eventiPassati = decodedStorico.map((item) => EventoArchiviato.fromJson(item)).toList();
    }

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
    await prefs.setString('nome_evento', _nomeEvento);
    await prefs.setDouble('incasso_corrente', _incassoTotale);
    await prefs.setInt('scontrini_correnti', _numeroScontrini);
    await prefs.setString('venduti_correnti', jsonEncode(_prodottiVenduti));
    await prefs.setString('lista_prodotti_v2', jsonEncode(_prodottiGlobali.map((p) => p.toJson()).toList()));
  }

  Future<void> _salvaStorico() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('storico_eventi', jsonEncode(_eventiPassati.map((e) => e.toJson()).toList()));
  }

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

  void _archiviaEazzera(bool azzeraListino) {
    if (_nomeEvento.isEmpty) return;

    final nuovoEvento = EventoArchiviato(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nomeEvento: _nomeEvento,
      dataChiusura: DateTime.now().toString().substring(0, 16),
      incassoTotale: _incassoTotale,
      numeroScontriniEmessi: _numeroScontrini,
      prodottiVenduti: Map.from(_prodottiVenduti),
      prezziProdotti: {},
    );

    setState(() {
      _eventiPassati.add(nuovoEvento);
      _incassoTotale = 0.0;
      _numeroScontrini = 0;
      _prodottiVenduti.clear();

      if (azzeraListino) {
        _prodottiGlobali.clear();
      }

      _nomeEvento = '';
    });

    _salvaStorico();
    _salvaDatiCorrenti();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(azzeraListino ? 'Evento archiviato e listino azzerato!' : 'Evento archiviato. Listino mantenuto.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.indigo)));
    }

    final List<Widget> schermate = [
      _HomeView(
        nomeEvento: _nomeEvento,
        onNomeCambiato: (nuovoNome) {
          setState(() => _nomeEvento = nuovoNome);
          _salvaDatiCorrenti();
        },
      ),
      ListinoScreen(
        prodotti: _prodottiGlobali,
        onAggiornato: () {
          setState(() {});
          _salvaDatiCorrenti();
        },
      ),
      CassaScreen(
        prodotti: _prodottiGlobali,
        nomeEvento: _nomeEvento,
        onStampaScontrino: _registraVendita,
      ),
      StatisticheScreen(
        nomeEvento: _nomeEvento,
        incassoTotale: _incassoTotale,
        numeroScontrini: _numeroScontrini,
        prodottiVenduti: _prodottiVenduti,
        onAggiorna: () => setState(() {}),
        onStampaChiusura: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Scontrino di chiusura stampato con successo!')),
          );
        },
        onArchiviaEazzera: (bool azzeraListino) => _archiviaEazzera(azzeraListino),
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

      body: PageView.builder(
        controller: _pageController,
        physics: const BouncingScrollPhysics(), // <-- Aggiunto per scorrimento fluido "gommoso" su tablet
        onPageChanged: (index) {
          setState(() {
            _indiceSelezionato = index;
          });
        },
        itemCount: schermate.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double distanza = 0.0;

              if (_pageController.position.haveDimensions) {
                distanza = (index.toDouble() - (_pageController.page ?? 0)).abs();
              } else {
                distanza = (index.toDouble() - _indiceSelezionato.toDouble()).abs();
              }

              double opacita = (1 - distanza).clamp(0.0, 1.0);
              double scala = 1.0 - (distanza * 0.15);

              return Opacity(
                opacity: opacita,
                child: Transform.scale(
                  scale: scala,
                  child: child,
                ),
              );
            },
            child: schermate[index],
          );
        },
      ),

      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.grey.shade100,
        color: Colors.white,
        buttonBackgroundColor: Colors.white,
        animationCurve: Curves.easeOutQuint, // <-- Aggiunto per l'onda fluida
        animationDuration: const Duration(milliseconds: 400), // <-- Allungato leggermente per la fluidità
        index: _indiceSelezionato,
        onTap: (int index) {
          setState(() {
            _indiceSelezionato = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutQuint, // <-- Sincronizzato con l'onda
          );
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
  final String nomeEvento;
  final Function(String) onNomeCambiato;

  const _HomeView({required this.nomeEvento, required this.onNomeCambiato});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/logo.png', height: 220),
          const SizedBox(height: 20),

          const Text(
            'CASSA-V19',
            style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.indigo, letterSpacing: 2),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: nomeEvento.isEmpty ? Colors.red.shade100 : Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: nomeEvento.isEmpty ? Colors.red.shade300 : Colors.green.shade300, width: 2),
            ),
            child: Text(
              nomeEvento.isEmpty ? 'NESSUN EVENTO CREATO' : 'EVENTO ATTIVO: ${nomeEvento.toUpperCase()}',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: nomeEvento.isEmpty ? Colors.red.shade800 : Colors.green.shade900
              ),
            ),
          ),

          const SizedBox(height: 30),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.edit_calendar),
            label: const Text('Crea / Modifica Evento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            onPressed: () {
              final controller = TextEditingController(text: nomeEvento);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Inserisci il nome dell\'evento'),
                  content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Es: Festa della Birra 2026',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annulla', style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                      onPressed: () {
                        if (controller.text.trim().isNotEmpty) {
                          onNomeCambiato(controller.text.trim());
                        }
                        Navigator.pop(context);
                      },
                      child: const Text('Salva Evento'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}