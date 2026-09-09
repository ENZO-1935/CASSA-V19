import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/prodotto.dart';
import '../models/evento_archiviato.dart';
import '../models/ordine.dart'; // Importa la classe Transazione
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
  double _incassoContanti = 0.0;
  double _incassoCarta = 0.0;
  int _numeroScontrini = 0;
  Map<String, int> _prodottiVenduti = {};

  List<Transazione> _transazioniAttive = []; // Storico orari per il filtro

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

    await prefs.remove('lista_prodotti');
    await prefs.remove('lista_prodotti_v2');

    String? nomeSalvato = prefs.getString('nome_evento');
    if (nomeSalvato == 'NESSUN EVENTO IMPOSTATO') nomeSalvato = '';
    _nomeEvento = nomeSalvato ?? '';

    final String? prodottiString = prefs.getString('lista_prodotti_v3');
    if (prodottiString != null) {
      final List decoded = jsonDecode(prodottiString);
      _prodottiGlobali = decoded.map((item) => Prodotto.fromJson(item)).toList();
    } else {
      _prodottiGlobali = [];
      await prefs.setString('lista_prodotti_v3', jsonEncode([]));
    }

    final String? storicoString = prefs.getString('storico_eventi');
    if (storicoString != null) {
      final List decodedStorico = jsonDecode(storicoString);
      _eventiPassati = decodedStorico.map((item) => EventoArchiviato.fromJson(item)).toList();
    }

    _incassoTotale = prefs.getDouble('incasso_corrente') ?? 0.0;
    _incassoContanti = prefs.getDouble('incasso_contanti') ?? 0.0;
    _incassoCarta = prefs.getDouble('incasso_carta') ?? 0.0;
    _numeroScontrini = prefs.getInt('scontrini_correnti') ?? 0;

    final String? vendutiString = prefs.getString('venduti_correnti');
    if (vendutiString != null) {
      _prodottiVenduti = Map<String, int>.from(jsonDecode(vendutiString));
    }

    final String? transString = prefs.getString('transazioni_correnti');
    if (transString != null) {
      final List decodedTrans = jsonDecode(transString);
      _transazioniAttive = decodedTrans.map((t) => Transazione.fromJson(t)).toList();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _salvaDatiCorrenti() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nome_evento', _nomeEvento);
    await prefs.setDouble('incasso_corrente', _incassoTotale);
    await prefs.setDouble('incasso_contanti', _incassoContanti);
    await prefs.setDouble('incasso_carta', _incassoCarta);
    await prefs.setInt('scontrini_correnti', _numeroScontrini);
    await prefs.setString('venduti_correnti', jsonEncode(_prodottiVenduti));
    await prefs.setString('transazioni_correnti', jsonEncode(_transazioniAttive.map((t) => t.toJson()).toList()));
    await prefs.setString('lista_prodotti_v3', jsonEncode(_prodottiGlobali.map((p) => p.toJson()).toList()));
  }

  Future<void> _salvaStorico() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('storico_eventi', jsonEncode(_eventiPassati.map((e) => e.toJson()).toList()));
  }

  void _registraVendita(Map<Prodotto, int> carrello, double totale, String metodoPagamento) {
    setState(() {
      _incassoTotale += totale;
      if (metodoPagamento == 'CARTA') {
        _incassoCarta += totale;
      } else {
        _incassoContanti += totale;
      }

      _numeroScontrini += 1;

      Map<String, int> prodottiScontrino = {};
      carrello.forEach((prodotto, quantita) {
        String nomeProdotto = prodotto.nome.toUpperCase();
        prodottiScontrino[nomeProdotto] = quantita;
        if (_prodottiVenduti.containsKey(nomeProdotto)) {
          _prodottiVenduti[nomeProdotto] = _prodottiVenduti[nomeProdotto]! + quantita;
        } else {
          _prodottiVenduti[nomeProdotto] = quantita;
        }
      });

      _transazioniAttive.add(
          Transazione(
            dataOra: DateTime.now(),
            totale: totale,
            metodoPagamento: metodoPagamento,
            prodotti: prodottiScontrino,
          )
      );
    });
    _salvaDatiCorrenti();
  }

  void _archiviaEvento(bool azzeraListino, bool azzeraIncassi) {
    if (_nomeEvento.isEmpty) return;

    int indiceEsistente = _eventiPassati.indexWhere((e) => e.nomeEvento.toLowerCase() == _nomeEvento.toLowerCase());

    if (indiceEsistente >= 0) {
      // SISTEMA ANTI-DOPPIONI: Cerca solo gli scontrini NON ancora archiviati nello storico
      List<Transazione> nuoveTransazioni = _transazioniAttive.where((tAttiva) {
        return !_eventiPassati[indiceEsistente].transazioni.any((tStorico) =>
            tStorico.dataOra.isAtSameMomentAs(tAttiva.dataOra)
        );
      }).toList();

      double nuovoIncassoTotale = 0;
      double nuovoIncassoContanti = 0;
      double nuovoIncassoCarta = 0;
      int nuovoNumeroScontrini = 0;
      Map<String, int> nuoviProdottiVenduti = {};

      // Calcola i totali SOLO dei nuovi scontrini aggiunti da dopo l'ultimo backup
      for(var t in nuoveTransazioni) {
        nuovoIncassoTotale += t.totale;
        if (t.metodoPagamento == 'CARTA') nuovoIncassoCarta += t.totale;
        else nuovoIncassoContanti += t.totale;
        nuovoNumeroScontrini += 1;
        t.prodotti.forEach((k, v) {
          String nomeU = k.toUpperCase();
          nuoviProdottiVenduti[nomeU] = (nuoviProdottiVenduti[nomeU] ?? 0) + v;
        });
      }

      // Somma il delta al database storico
      _eventiPassati[indiceEsistente].incassoTotale += nuovoIncassoTotale;
      _eventiPassati[indiceEsistente].incassoContanti += nuovoIncassoContanti;
      _eventiPassati[indiceEsistente].incassoCarta += nuovoIncassoCarta;
      _eventiPassati[indiceEsistente].numeroScontriniEmessi += nuovoNumeroScontrini;
      _eventiPassati[indiceEsistente].dataChiusura = DateTime.now().toString().substring(0, 16);

      nuoviProdottiVenduti.forEach((key, val) {
        _eventiPassati[indiceEsistente].prodottiVenduti[key] = (_eventiPassati[indiceEsistente].prodottiVenduti[key] ?? 0) + val;
      });

      for (var p in _prodottiGlobali) {
        _eventiPassati[indiceEsistente].prezziProdotti[p.nome.toUpperCase()] = p.prezzo;
      }

      _eventiPassati[indiceEsistente].transazioni.addAll(nuoveTransazioni);

    } else {
      // Primo salvataggio in assoluto
      Map<String, int> prodottiVendutiMaiuscolo = {};
      _prodottiVenduti.forEach((k, v) => prodottiVendutiMaiuscolo[k.toUpperCase()] = v);

      Map<String, double> listinoMaiuscolo = {};
      for (var p in _prodottiGlobali) {
        listinoMaiuscolo[p.nome.toUpperCase()] = p.prezzo;
      }

      final nuovoEvento = EventoArchiviato(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nomeEvento: _nomeEvento,
        dataChiusura: DateTime.now().toString().substring(0, 16),
        incassoTotale: _incassoTotale,
        incassoContanti: _incassoContanti,
        incassoCarta: _incassoCarta,
        numeroScontriniEmessi: _numeroScontrini,
        prodottiVenduti: prodottiVendutiMaiuscolo,
        prezziProdotti: listinoMaiuscolo,
        transazioni: List.from(_transazioniAttive),
      );
      _eventiPassati.add(nuovoEvento);
    }

    setState(() {
      if (azzeraIncassi) {
        _incassoTotale = 0.0;
        _incassoContanti = 0.0;
        _incassoCarta = 0.0;
        _numeroScontrini = 0;
        _prodottiVenduti.clear();
        _transazioniAttive.clear();
        _nomeEvento = '';
      }

      if (azzeraListino) {
        _prodottiGlobali.clear();
      }
    });

    _salvaStorico();
    _salvaDatiCorrenti();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(azzeraIncassi ? 'Evento archiviato e chiuso con successo.' : 'Backup archiviato nello storico (dati correnti mantenuti).')),
    );
  }

  // Genera un oggetto evento "virtuale" con i dati correnti
  EventoArchiviato? get _eventoAttivoVirtuale {
    if (_nomeEvento.isEmpty && _incassoTotale == 0) return null;

    Map<String, int> prodottiVendutiMaiuscolo = {};
    _prodottiVenduti.forEach((k, v) => prodottiVendutiMaiuscolo[k.toUpperCase()] = v);

    Map<String, double> listinoMaiuscolo = {};
    for (var p in _prodottiGlobali) {
      listinoMaiuscolo[p.nome.toUpperCase()] = p.prezzo;
    }

    return EventoArchiviato(
      id: 'ATTIVO_CORRENTE',
      nomeEvento: _nomeEvento.isEmpty ? 'IN CORSO' : _nomeEvento,
      dataChiusura: 'Evento in corso (Dati Live)',
      incassoTotale: _incassoTotale,
      incassoContanti: _incassoContanti,
      incassoCarta: _incassoCarta,
      numeroScontriniEmessi: _numeroScontrini,
      prodottiVenduti: prodottiVendutiMaiuscolo,
      prezziProdotti: listinoMaiuscolo,
      transazioni: List.from(_transazioniAttive),
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
        numeroScontriniEmmessi: _numeroScontrini,
      ),
      StatisticheScreen(
        nomeEvento: _nomeEvento,
        incassoTotale: _incassoTotale,
        incassoContanti: _incassoContanti,
        incassoCarta: _incassoCarta,
        numeroScontrini: _numeroScontrini,
        prodottiVenduti: _prodottiVenduti,
        listinoPrezzi: { for (var p in _prodottiGlobali) p.nome.toUpperCase(): p.prezzo },
        onAggiorna: () => setState(() {}),
        onStampaChiusura: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Scontrino di chiusura stampato con successo!')),
          );
        },
        onArchiviaEazzera: (bool azzeraListino, bool azzeraIncassi) => _archiviaEvento(azzeraListino, azzeraIncassi),
      ),
      StoricoScreen(
        eventiPassati: _eventiPassati,
        eventoAttivoCorrente: _eventoAttivoVirtuale,
        listinoPrezziAttuale: { for (var p in _prodottiGlobali) p.nome.toUpperCase(): p.prezzo },
        onAggiorna: () => setState(() {}),
        onSalvaStorico: _salvaStorico,
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
        physics: const BouncingScrollPhysics(),
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
        animationCurve: Curves.easeOutQuint,
        animationDuration: const Duration(milliseconds: 400),
        index: _indiceSelezionato,
        onTap: (int index) {
          setState(() {
            _indiceSelezionato = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutQuint,
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

  void _mostraInfoDialog(BuildContext context, String titolo, String contenuto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titolo, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Text(contenuto, style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87)),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 24.0, left: 16.0, right: 16.0, bottom: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 260,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
            const SizedBox(height: 20),
            const Text(
              'CASSA-V19',
              style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.indigo, letterSpacing: 2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
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
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: nomeEvento.isEmpty ? Colors.red.shade800 : Colors.green.shade900
                ),
              ),
            ),
            const SizedBox(height: 24),
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
                      decoration: const InputDecoration(border: OutlineInputBorder()),
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
            const SizedBox(height: 50),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: () => _mostraInfoDialog(
                    context,
                    '📖 Manuale d\'Uso',
                    '''Benvenuto in CASSA-V19! Ecco come sfruttare al massimo tutte le potenzialità della tua cassa:

🏠 1. HOME E CREAZIONE EVENTO
Prima di iniziare a vendere, devi creare un evento (es. "Festa della Birra"). Tocca "Crea / Modifica Evento". Se non c'è un evento attivo, il sistema bloccherà le vendite per evitare scontrini errati.

📋 2. GESTIONE LISTINO E ICONE AUTOMATICHE
All'avvio il listino è vuoto per lasciarti massima libertà.
• Riconoscimento intelligente: Quando crei un nuovo prodotto, scrivi semplicemente il nome (es. "Birra", "Pizza", "Panino"). Per alcuni prodotti il sistema capirà automaticamente se si tratta di Cibo (colore arancione) o Bevanda (colore blu) assegnando un icona personalizzata.
• Foto personalizzate: Puoi anche scattare una foto al prodotto o sceglierla dalla galleria cliccando sull'icona della fotocamera.

🛒 3. CASSA E VENDITA
Il cuore dell'applicazione, progettato per essere velocissimo:
• Filtri in alto: Scorri rapidamente tra Tutti i prodotti, Bevande, Cibo o apri il Tastierino numerico.
• Aggiunta Multipla (Il menu Qt): Vuoi vendere 5 birre? Tocca per 5 volte l'icona della birra della birra o seleziona "Qt: 5" dal menu in alto e poi tocca la birra. Al carrello verranno aggiunte 5 birre in un solo colpo e il menu tornerà magicamente a "Qt: 1" pronto per il prossimo cliente.
• Importo Libero e Tastierino: Digita un prezzo al volo e aggiungilo al carrello. Se usi il selettore (es. Qt: 3) e digiti "15€", il sistema calcolerà in automatico che costano 5€ l'una.
• Gestione Carrello: Rimuovi una singola unità premendo il tastino rosso "-" a destra del prodotto, oppure premi "Svuota Tutto" in basso se il cliente cambia idea.

🖨️ 4. STAMPANTE TERMICA E ANTEPRIMA
Tocca l'icona della stampante in alto a destra per collegarti via USB, Bluetooth o Rete Wi-Fi/LAN.
• Ticket Singoli: La cassa stamperà automaticamente un ticket separato per ogni singola consumazione con tanto di riga tratteggiata, ideale per dividerli tra banco cibo e banco bevande.
• Numerazione Progressiva: L'ordine scontrini (es. #0001, #0002) è globale e non si azzera mai durante la serata.
• Anteprima a Schermo: Se clicchi su "Simula a Schermo", l'app ti farà vedere esattamente come uscirà lo scontrino cartaceo.

📊 5. STATISTICHE E CHIUSURA
Tieni d'occhio incasso, scontrini emessi e i prodotti più venduti.
• A fine serata, stampa lo "Scontrino di Chiusura".
• Dopodiché premi "Archivia Evento". Il sistema ti chiederà se vuoi svuotare completamente il listino o se vuoi tenerlo per la serata successiva.

🕒 6. STORICO
Qui vengono salvati per sempre tutti i tuoi eventi passati. Puoi consultarli in ogni momento o eliminare quelli troppo vecchi.''',
                  ),
                  child: const Text('Manuale d\'uso', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.w600)),
                ),
                TextButton(
                  onPressed: () => _mostraInfoDialog(
                    context,
                    'ℹ️ Chi Siamo',
                    'CASSA-V19 è il sistema POS intelligente, leggero e affidabile, progettato per offrire una gestione rapida, intuitiva e professionale delle vendite in occasione di eventi, sagre e manifestazioni.',
                  ),
                  child: const Text('Chi siamo', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.w600)),
                ),
                TextButton(
                  onPressed: () => _mostraInfoDialog(
                    context,
                    '📞 Contatti',
                    'Hai bisogno di assistenza o supporto tecnico?\n\n'
                        'Telefono: 370 101 5598\n'
                        'Email: supporto.cassav19@gmail.com',
                  ),
                  child: const Text('Contatti', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.w600)),
                ),
                TextButton(
                  onPressed: () => _mostraInfoDialog(
                    context,
                    '📄 Termini di Servizio',
                    'Utilizzando l\'applicazione CASSA-V19, l\'utente accetta di gestire i dati di vendita e contabili sotto la propria esclusiva responsabilità. Il software viene fornito come strumento di supporto per la gestione degli ordini.',
                  ),
                  child: const Text('Termini di servizio', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.w600)),
                ),
                TextButton(
                  onPressed: () => _mostraInfoDialog(
                    context,
                    '🔒 Privacy Policy',
                    'CASSA-V19 tutela la tua privacy. Tutti i dati relativi agli eventi, al listino prodotti, allo storico e agli incassi vengono memorizzati esclusivamente in locale sul tuo dispositivo tramite la memoria interna. Nessun dato personale o finanziario viene trasmesso a server esterni.',
                  ),
                  child: const Text('Privacy Policy', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}