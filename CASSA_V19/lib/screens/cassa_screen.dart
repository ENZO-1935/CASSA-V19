import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/prodotto.dart';

// Nuove librerie per la stampante termica
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

class CassaScreen extends StatefulWidget {
  final List<Prodotto> prodotti;
  final String nomeEvento;
  final Function(Map<Prodotto, int>, double) onStampaScontrino;

  const CassaScreen({
    super.key,
    required this.prodotti,
    required this.nomeEvento,
    required this.onStampaScontrino,
  });

  @override
  State<CassaScreen> createState() => _CassaScreenState();
}

class _CassaScreenState extends State<CassaScreen> {
  final Map<Prodotto, int> _carrello = {};
  int _contatoreOrdineLocale = 1;

  int _tabSelezionato = 0;
  String _valoreTastierino = '0';

  String? _idProdottoCustomSelezionato;

  // Variabili per la gestione della stampante USB
  var printerManager = PrinterManager.instance;
  PrinterDevice? _stampanteSelezionata;

  void _aggiungiAlCarrello(Prodotto p) {
    setState(() {
      if (_carrello.containsKey(p)) {
        _carrello[p] = _carrello[p]! + 1;
      } else {
        _carrello[p] = 1;
      }
    });
  }

  void _rimuoviDalCarrello(Prodotto p) {
    setState(() {
      if (_carrello.containsKey(p)) {
        if (_carrello[p]! > 1) {
          _carrello[p] = _carrello[p]! - 1;
        } else {
          _carrello.remove(p);
        }
      }
    });
  }

  void _svuotaCarrello() {
    setState(() {
      _carrello.clear();
      _valoreTastierino = '0';
      _idProdottoCustomSelezionato = null;
    });
  }

  double get _totaleIncasso {
    double totale = 0;
    _carrello.forEach((prodotto, quantita) {
      totale += (prodotto.prezzo * quantita);
    });
    return totale;
  }

  void _premiTasto(String tasto) {
    setState(() {
      if (tasto == 'C') {
        _valoreTastierino = '0';
      } else if (tasto == '.') {
        if (!_valoreTastierino.contains('.')) {
          _valoreTastierino += '.';
        }
      } else {
        if (_valoreTastierino == '0') {
          _valoreTastierino = tasto;
        } else {
          if (_valoreTastierino.length < 8) {
            _valoreTastierino += tasto;
          }
        }
      }
    });
  }

  void _aggiungiImportoLibero() {
    double prezzo = double.tryParse(_valoreTastierino) ?? 0.0;
    if (prezzo > 0) {

      Prodotto? prodottoBase;
      if (_idProdottoCustomSelezionato != null) {
        try {
          prodottoBase = widget.prodotti.firstWhere((p) => p.id == _idProdottoCustomSelezionato);
        } catch (_) {}
      }

      Prodotto pCustom = Prodotto(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        nome: prodottoBase?.nome ?? 'Importo Libero',
        prezzo: prezzo,
        tipologia: prodottoBase?.tipologia ?? 'varie',
        immagineBase64: prodottoBase?.immagineBase64,
      );

      _aggiungiAlCarrello(pCustom);

      setState(() {
        _valoreTastierino = '0';
        _idProdottoCustomSelezionato = null;
      });
    }
  }

  // REINSERITA: Generazione grafica dei ticket per simulazione
  List<Widget> _generaTicketSingoli(Map<Prodotto, int> carrelloVenduto, String dataOra) {
    List<Widget> listaTicket = [];
    int totaleTicket = 0;
    carrelloVenduto.forEach((p, q) => totaleTicket += q);
    int ticketCorrente = 1;

    carrelloVenduto.forEach((prodotto, quantita) {
      for (int i = 0; i < quantita; i++) {
        listaTicket.add(
            Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black87, width: 2)),
              child: Column(
                children: [
                  Image.asset('assets/images/logo.png', height: 40), const SizedBox(height: 6),
                  Text(widget.nomeEvento.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace'), textAlign: TextAlign.center),
                  Text('Ordine #${_contatoreOrdineLocale.toString().padLeft(3, '0')}', style: const TextStyle(fontSize: 14, fontFamily: 'monospace')),
                  const Divider(color: Colors.black87, thickness: 1.5), const SizedBox(height: 10),
                  Text('1x ${prodotto.nome.toUpperCase()}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'monospace', height: 1.1)),
                  const SizedBox(height: 10), const Divider(color: Colors.black87, thickness: 1.5),
                  Text('${prodotto.prezzo.toStringAsFixed(2)} €   -   Ticket $ticketCorrente di $totaleTicket', style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                  Text(dataOra, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey)),
                ],
              ),
            )
        );
        if (ticketCorrente < totaleTicket) {
          listaTicket.add(const Padding(padding: EdgeInsets.symmetric(vertical: 12.0), child: Text('- - - - - ✂️ - - - - -', style: TextStyle(color: Colors.grey, fontSize: 18, letterSpacing: 2), textAlign: TextAlign.center)));
        }
        ticketCorrente++;
      }
    });
    return listaTicket;
  }

  // REINSERITA: Mostra l'anteprima a schermo
  void _mostraAnteprimaScontrino(Map<Prodotto, int> carrelloVenduto, double totale) {
    String dataOraStr = DateTime.now().toString().substring(0, 16);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade200, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Column(
          children: [
            const Text('🖨️ SIMULAZIONE TICKET', style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold)),
            Text('Totale pagato: ${totale.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 16, color: Colors.indigo, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 320, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: _generaTicketSingoli(carrelloVenduto, dataOraStr))),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              widget.onStampaScontrino(carrelloVenduto, totale); // Registra le statistiche
              setState(() => _contatoreOrdineLocale++);
              _svuotaCarrello();
            },
            child: const Text('Completa Ordine Simulato'),
          ),
        ],
      ),
    );
  }

  // DIALOGO DI RICERCA STAMPANTE USB AGGIORNATO CON TASTO SIMULA
  void _mostraDialogoStampanteUSB() {
    bool staCercando = true;
    List<PrinterDevice> dispositiviTrovati = [];

    void scansiona(StateSetter updateModal) {
      updateModal(() { staCercando = true; dispositiviTrovati.clear(); });

      printerManager.discovery(type: PrinterType.usb, isBle: false).listen((device) {
        if (!dispositiviTrovati.any((d) => d.vendorId == device.vendorId && d.productId == device.productId)) {
          updateModal(() => dispositiviTrovati.add(device));
        }
      }).onDone(() {
        updateModal(() => staCercando = false);
      });
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            if (staCercando && dispositiviTrovati.isEmpty) { scansiona(setStateModal); }

            return AlertDialog(
              title: const Text('🖨️ Configurazione Stampante USB', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: SizedBox(
                width: 320, height: 300,
                child: staCercando && dispositiviTrovati.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : dispositiviTrovati.isEmpty
                    ? const Center(child: Text('Nessuna stampante trovata.\n\nAssicurati di aver collegato il cavo OTG al tablet, che la stampante sia accesa e di autorizzare il dispositivo.', textAlign: TextAlign.center))
                    : ListView.builder(
                  itemCount: dispositiviTrovati.length,
                  itemBuilder: (context, index) {
                    final d = dispositiviTrovati[index];
                    final isSelezionata = _stampanteSelezionata?.vendorId == d.vendorId && _stampanteSelezionata?.productId == d.productId;
                    return ListTile(
                      leading: Icon(Icons.print, color: isSelezionata ? Colors.indigo : Colors.grey),
                      title: Text(d.name ?? 'Epson TM Series (USB)', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('ID Prodotto: ${d.productId}'),
                      tileColor: isSelezionata ? Colors.indigo.shade50 : null,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      onTap: () {
                        setState(() => _stampanteSelezionata = d);
                        Navigator.pop(context);
                        if (_carrello.isNotEmpty) _gestisciStampaScontrino();
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
                // TASTO DI EMERGENZA / TEST: SIMULA A SCHERMO
                if (_carrello.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _mostraAnteprimaScontrino(Map.from(_carrello), _totaleIncasso);
                    },
                    child: const Text('Simula a Schermo', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  ),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                    onPressed: staCercando ? null : () => scansiona(setStateModal),
                    child: const Text('Cerca Ancora')
                ),
              ],
            );
          },
        );
      },
    );
  }

  // GENERAZIONE DEI BYTE ESC/POS PER LA STAMPANTE (Hardware Reale)
  Future<List<int>> _generaByteScontrino(Map<Prodotto, int> carrelloVenduto) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile); // Configurazione rotolo Epson 80mm
    List<int> bytes = [];

    int totaleTicket = 0;
    carrelloVenduto.forEach((p, q) => totaleTicket += q);
    int ticketCorrente = 1;

    carrelloVenduto.forEach((prodotto, quantita) {
      for (int i = 0; i < quantita; i++) {
        // Intestazione
        bytes += generator.text(widget.nomeEvento.toUpperCase(), styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
        bytes += generator.feed(1);
        bytes += generator.text('Ordine #${_contatoreOrdineLocale.toString().padLeft(3, '0')}', styles: const PosStyles(align: PosAlign.center, bold: true));
        bytes += generator.hr();
        bytes += generator.feed(1);

        // Prodotto
        bytes += generator.text('1x ${prodotto.nome.toUpperCase()}', styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
        bytes += generator.feed(1);

        // Piè di pagina
        bytes += generator.hr();
        bytes += generator.text('${prodotto.prezzo.toStringAsFixed(2)} EUR   -   Ticket $ticketCorrente di $totaleTicket', styles: const PosStyles(align: PosAlign.center));
        bytes += generator.text(DateTime.now().toString().substring(0, 16), styles: const PosStyles(align: PosAlign.center));

        bytes += generator.feed(2); // Spazio extra prima del taglio
        bytes += generator.cut(); // Comando taglio carta Epson

        ticketCorrente++;
      }
    });

    return bytes;
  }

  // FLUSSO DI COMUNICAZIONE HARDWARE
  void _gestisciStampaScontrino() async {
    if (widget.nomeEvento.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(children: const [Icon(Icons.warning, color: Colors.red), SizedBox(width: 10), Text('Errore Cassa')]),
          content: const Text('Devi prima CREARE UN EVENTO nella schermata Home (l\'icona della casetta) per poter iniziare a vendere e stampare gli scontrini.'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context),
              child: const Text('Ho capito'),
            ),
          ],
        ),
      );
      return;
    }

    if (_carrello.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Il carrello è vuoto!')));
      return;
    }

    // Se la stampante fisica non è selezionata, apri il menu di ricerca (dove ci sarà il tasto Simula a Schermo)
    if (_stampanteSelezionata == null) {
      _mostraDialogoStampanteUSB();
      return;
    }

    // Altrimenti, invia direttamente l'ordine alla stampante fisica
    try {
      printerManager.connect(
          type: PrinterType.usb,
          model: UsbPrinterInput(
              name: _stampanteSelezionata!.name,
              productId: _stampanteSelezionata!.productId,
              vendorId: _stampanteSelezionata!.vendorId
          )
      );

      final bytes = await _generaByteScontrino(Map.from(_carrello));
      printerManager.send(type: PrinterType.usb, bytes: bytes);

      double totale = _totaleIncasso;
      widget.onStampaScontrino(Map.from(_carrello), totale);

      setState(() => _contatoreOrdineLocale++);
      _svuotaCarrello();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore di stampa: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _buildTopTab(int index, IconData icona) {
    bool attivo = _tabSelezionato == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabSelezionato = index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: attivo ? Colors.indigo : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: attivo ? Colors.indigo : Colors.grey.shade300, width: 2),
            boxShadow: attivo ? [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))] : [],
          ),
          child: Center(
            child: Icon(icona, color: attivo ? Colors.white : Colors.indigo.shade300, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildTastoTastierino(String testo, {Color? coloreSfondo, Color? coloreTesto}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: coloreSfondo ?? Colors.white,
        foregroundColor: coloreTesto ?? Colors.indigo.shade900,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.zero,
      ),
      onPressed: () => _premiTasto(testo),
      child: Text(testo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Prodotto> prodottiMostrati = [];
    if (_tabSelezionato == 0) {
      prodottiMostrati = widget.prodotti;
    } else if (_tabSelezionato == 1) {
      prodottiMostrati = widget.prodotti.where((p) => p.tipologia == 'bevanda').toList();
    } else if (_tabSelezionato == 2) {
      prodottiMostrati = widget.prodotti.where((p) => p.tipologia == 'cibo').toList();
    }

    if (_idProdottoCustomSelezionato != null && !widget.prodotti.any((p) => p.id == _idProdottoCustomSelezionato)) {
      _idProdottoCustomSelezionato = null;
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Cassa - Modalità Vendita', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.grey.shade100,
        surfaceTintColor: Colors.transparent,
        actions: [
          // Icona in alto a destra per connettere la stampante USB
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: Icon(
                _stampanteSelezionata == null ? Icons.print_disabled : Icons.print,
                color: _stampanteSelezionata == null ? Colors.red : Colors.green,
                size: 28,
              ),
              tooltip: 'Configura Stampante USB',
              onPressed: _mostraDialogoStampanteUSB,
            ),
          )
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  SizedBox(
                    height: 40,
                    child: Row(
                      children: [
                        _buildTopTab(0, Icons.grid_view),
                        _buildTopTab(1, Icons.local_drink),
                        _buildTopTab(2, Icons.restaurant_menu),
                        _buildTopTab(3, Icons.dialpad),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  Expanded(
                    child: _tabSelezionato == 3
                        ? // TASTIERINO CON SCHERMO COMPATTO 2-IN-1
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // SCHERMO 2-IN-1: TENDINA PRODOTTO + IMPORTO UNITI
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    DropdownButtonHideUnderline(
                                      child: DropdownButton<String?>(
                                        isDense: true,
                                        isExpanded: true,
                                        value: _idProdottoCustomSelezionato,
                                        hint: const Text('Seleziona prodotto (o Importo Libero)', style: TextStyle(fontSize: 11, color: Colors.indigo, fontWeight: FontWeight.bold)),
                                        icon: const Icon(Icons.arrow_drop_down, color: Colors.indigo, size: 18),
                                        items: [
                                          const DropdownMenuItem<String?>(
                                            value: null,
                                            child: Text('Nessun prodotto (Importo Libero)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)),
                                          ),
                                          ...widget.prodotti.map((p) => DropdownMenuItem<String?>(
                                            value: p.id,
                                            child: Text('${p.nome} (${p.prezzo.toStringAsFixed(2)} €)', style: const TextStyle(fontSize: 11)),
                                          )).toList(),
                                        ],
                                        onChanged: (val) {
                                          setState(() {
                                            _idProdottoCustomSelezionato = val;
                                          });
                                        },
                                      ),
                                    ),
                                    const Divider(height: 6, thickness: 1),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        '$_valoreTastierino €',
                                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo, fontFamily: 'monospace'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),

                              // GRIGLIA TASTI
                              SizedBox(
                                height: 250,
                                child: GridView.count(
                                  crossAxisCount: 3,
                                  childAspectRatio: 1.9,
                                  mainAxisSpacing: 5,
                                  crossAxisSpacing: 5,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    _buildTastoTastierino('7'), _buildTastoTastierino('8'), _buildTastoTastierino('9'),
                                    _buildTastoTastierino('4'), _buildTastoTastierino('5'), _buildTastoTastierino('6'),
                                    _buildTastoTastierino('1'), _buildTastoTastierino('2'), _buildTastoTastierino('3'),
                                    _buildTastoTastierino('C', coloreSfondo: Colors.red.shade50, coloreTesto: Colors.red.shade700),
                                    _buildTastoTastierino('0'),
                                    _buildTastoTastierino('.'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),

                              // PULSANTE AGGIUNGI AL CARRELLO
                              SizedBox(
                                height: 40,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal.shade600,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    elevation: 1,
                                  ),
                                  onPressed: _aggiungiImportoLibero,
                                  icon: const Icon(Icons.add_shopping_cart, size: 16),
                                  label: const Text('AGGIUNGI AL CARRELLO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    )
                        : // GRIGLIA PRODOTTI NORMALE
                    GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10
                      ),
                      itemCount: prodottiMostrati.length,
                      itemBuilder: (context, index) {
                        final p = prodottiMostrati[index];
                        final isCibo = p.tipologia == 'cibo';

                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: isCibo ? Colors.orange.shade800 : Colors.blue.shade800,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: isCibo ? Colors.orange.shade200 : Colors.blue.shade200, width: 2),
                            ),
                            padding: const EdgeInsets.all(6),
                          ),
                          onPressed: () => _aggiungiAlCarrello(p),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: isCibo ? Colors.orange.shade100 : Colors.blue.shade100,
                                backgroundImage: p.immagineBase64 != null
                                    ? MemoryImage(base64Decode(p.immagineBase64!))
                                    : null,
                                child: p.immagineBase64 == null
                                    ? Icon(p.icona, color: isCibo ? Colors.orange.shade800 : Colors.blue.shade800, size: 28)
                                    : null,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                  p.nome,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)
                              ),
                              const SizedBox(height: 2),
                              Text(
                                  '${p.prezzo.toStringAsFixed(2)} €',
                                  style: TextStyle(fontSize: 14, color: isCibo ? Colors.orange.shade700 : Colors.blue.shade700, fontWeight: FontWeight.bold)
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _carrello.length,
                      itemBuilder: (context, index) {
                        final prodotto = _carrello.keys.elementAt(index);
                        final quantita = _carrello[prodotto]!;
                        final prezzoTotale = prodotto.prezzo * quantita;

                        return Card(
                          color: Colors.grey.shade50,
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text('${quantita}x ${prodotto.nome} - ${prezzoTotale.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            trailing: IconButton(icon: const Icon(Icons.remove_circle, color: Colors.deepOrange), onPressed: () => _rimuoviDalCarrello(prodotto)),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(thickness: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text('Totale: ${_totaleIncasso.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  ),
                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
                      onPressed: _svuotaCarrello,
                      child: const Text('Svuota Tutto', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                      onPressed: _gestisciStampaScontrino,
                      child: const Text('Stampa Scontrino', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}