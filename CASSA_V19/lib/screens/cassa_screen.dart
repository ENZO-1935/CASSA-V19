import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/prodotto.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

// Nuove librerie per la stampante termica
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../printer_globals.dart'; // <-- Memoria globale della stampante

class CassaScreen extends StatefulWidget {
  final List<Prodotto> prodotti;
  final String nomeEvento;
  final Function(Map<Prodotto, int>, double) onStampaScontrino;
  final int numeroScontriniEmmessi;

  const CassaScreen({
    super.key,
    required this.prodotti,
    required this.nomeEvento,
    required this.onStampaScontrino,
    required this.numeroScontriniEmmessi,
  });

  @override
  State<CassaScreen> createState() => _CassaScreenState();
}

class _CassaScreenState extends State<CassaScreen> {
  final Map<Prodotto, int> _carrello = {};

  int _tabSelezionato = 0;
  String _valoreTastierino = '0';
  String? _idProdottoCustomSelezionato;

  int _quantitaSelezionata = 1;

  var printerManager = PrinterManager.instance;

  int get _ordineCorrente => widget.numeroScontriniEmmessi + 1;

  void _aggiungiAlCarrello(Prodotto p, {int quantitaAggiuntiva = 1}) {
    setState(() {
      if (_carrello.containsKey(p)) {
        _carrello[p] = _carrello[p]! + quantitaAggiuntiva;
      } else {
        _carrello[p] = quantitaAggiuntiva;
      }
      _quantitaSelezionata = 1;
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
      _quantitaSelezionata = 1;
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
    double prezzoTotaleInserito = double.tryParse(_valoreTastierino) ?? 0.0;
    if (prezzoTotaleInserito > 0) {
      Prodotto? prodottoBase;
      if (_idProdottoCustomSelezionato != null) {
        try {
          prodottoBase = widget.prodotti.firstWhere((p) => p.id == _idProdottoCustomSelezionato);
        } catch (_) {}
      }

      double prezzoUnitario = prezzoTotaleInserito / _quantitaSelezionata;

      Prodotto pCustom = Prodotto(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        nome: prodottoBase?.nome ?? 'Importo Libero',
        prezzo: prezzoUnitario,
        tipologia: prodottoBase?.tipologia ?? 'varie',
        immagineBase64: prodottoBase?.immagineBase64,
      );

      _aggiungiAlCarrello(pCustom, quantitaAggiuntiva: _quantitaSelezionata);

      setState(() {
        _valoreTastierino = '0';
        _idProdottoCustomSelezionato = null;
      });
    }
  }

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
                  const Text('CASSA_V19', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(widget.nomeEvento.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace'), textAlign: TextAlign.center),
                  Text('Ordine #${_ordineCorrente.toString().padLeft(4, '0')}', style: const TextStyle(fontSize: 14, fontFamily: 'monospace')),
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
              widget.onStampaScontrino(carrelloVenduto, totale);
              _svuotaCarrello();
            },
            child: const Text('Completa Ordine Simulato'),
          ),
        ],
      ),
    );
  }

  void _mostraDialogoStampante() {
    bool staCercando = true;
    List<PrinterDevice> dispositiviTrovati = [];

    void scansiona(StateSetter updateModal) {
      updateModal(() { staCercando = true; dispositiviTrovati.clear(); });

      printerManager.discovery(type: connessioneGlobale, isBle: false).listen((device) {
        if (!dispositiviTrovati.any((d) => d.name == device.name && d.address == device.address)) {
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
              title: const Text('🖨️ Connetti Stampante', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: SizedBox(
                width: 350, height: 350,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<PrinterType>(
                          value: connessioneGlobale,
                          isExpanded: true,
                          icon: const Icon(Icons.settings_input_component, color: Colors.indigo),
                          items: const [
                            DropdownMenuItem(value: PrinterType.usb, child: Text('Ricerca tramite cavo USB')),
                            DropdownMenuItem(value: PrinterType.bluetooth, child: Text('Ricerca tramite Bluetooth')),
                            DropdownMenuItem(value: PrinterType.network, child: Text('Ricerca tramite Rete (LAN/Wi-Fi)')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => connessioneGlobale = val);
                              setStateModal(() => connessioneGlobale = val);
                              scansiona(setStateModal);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: staCercando && dispositiviTrovati.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : dispositiviTrovati.isEmpty
                          ? Center(child: Text('Nessun dispositivo trovato in modalità ${connessioneGlobale.name}.', textAlign: TextAlign.center))
                          : ListView.builder(
                        itemCount: dispositiviTrovati.length,
                        itemBuilder: (context, index) {
                          final d = dispositiviTrovati[index];
                          final isSelezionata = stampanteGlobale?.name == d.name;
                          return ListTile(
                            leading: Icon(
                                connessioneGlobale == PrinterType.usb ? Icons.usb : connessioneGlobale == PrinterType.bluetooth ? Icons.bluetooth : Icons.wifi,
                                color: isSelezionata ? Colors.indigo : Colors.grey
                            ),
                            title: Text(d.name ?? 'Dispositivo Sconosciuto', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(d.address ?? 'ID: ${d.productId ?? "-"}'),
                            tileColor: isSelezionata ? Colors.indigo.shade50 : null,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            onTap: () {
                              setState(() => stampanteGlobale = d);
                              Navigator.pop(context);
                              if (_carrello.isNotEmpty) _gestisciStampaScontrino();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
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

  Future<List<int>> _generaByteScontrino(Map<Prodotto, int> carrelloVenduto) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    int totaleTicket = 0;
    carrelloVenduto.forEach((p, q) => totaleTicket += q);
    int ticketCorrente = 1;

    carrelloVenduto.forEach((prodotto, quantita) {
      for (int i = 0; i < quantita; i++) {
        bytes.addAll(generator.text('CASSA_V19', styles: const PosStyles(align: PosAlign.center, bold: false, fontType: PosFontType.fontB)));
        bytes.addAll(generator.feed(1));

        bytes.addAll(generator.text(widget.nomeEvento.toUpperCase(), styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2)));
        bytes.addAll(generator.feed(1));
        bytes.addAll(generator.text('Ordine #${_ordineCorrente.toString().padLeft(4, '0')}', styles: const PosStyles(align: PosAlign.center, bold: true)));
        bytes.addAll(generator.hr());
        bytes.addAll(generator.feed(1));
        bytes.addAll(generator.text('1x ${prodotto.nome.toUpperCase()}', styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2)));
        bytes.addAll(generator.feed(1));
        bytes.addAll(generator.hr());
        bytes.addAll(generator.text('${prodotto.prezzo.toStringAsFixed(2)} EUR   -   Ticket $ticketCorrente di $totaleTicket', styles: const PosStyles(align: PosAlign.center)));
        bytes.addAll(generator.text(DateTime.now().toString().substring(0, 16), styles: const PosStyles(align: PosAlign.center)));
        bytes.addAll(generator.feed(2));
        bytes.addAll(generator.cut());

        ticketCorrente++;
      }
    });
    return bytes;
  }

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

    if (stampanteGlobale == null) {
      _mostraDialogoStampante();
      return;
    }

    try {
      dynamic printerInput;
      if (connessioneGlobale == PrinterType.usb) {
        printerInput = UsbPrinterInput(name: stampanteGlobale!.name, productId: stampanteGlobale!.productId, vendorId: stampanteGlobale!.vendorId);
      } else if (connessioneGlobale == PrinterType.bluetooth) {
        printerInput = BluetoothPrinterInput(name: stampanteGlobale!.name, address: stampanteGlobale!.address!, isBle: false);
      } else if (connessioneGlobale == PrinterType.network) {
        printerInput = TcpPrinterInput(ipAddress: stampanteGlobale!.address!);
      }

      printerManager.connect(type: connessioneGlobale, model: printerInput);
      final bytes = await _generaByteScontrino(Map.from(_carrello));
      printerManager.send(type: connessioneGlobale, bytes: bytes);

      double totale = _totaleIncasso;
      widget.onStampaScontrino(Map.from(_carrello), totale);
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
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: Icon(
                stampanteGlobale == null ? Icons.print_disabled : Icons.print,
                color: stampanteGlobale == null ? Colors.red : Colors.green,
                size: 28,
              ),
              tooltip: 'Configura Stampante',
              onPressed: _mostraDialogoStampante,
            ),
          )
        ],
      ),
      // LAYOUT BUILDER: Rende l'app perfetta su schermi grandi e piccoli!
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Se la larghezza è inferiore a 800px, passiamo alla modalità smartphone (colonna verticale)
          bool isMobile = constraints.maxWidth < 800;

          // --- PANNELLO SINISTRO: PRODOTTI E TASTIERINO ---
          Widget pannelloProdotti = Padding(
            padding: EdgeInsets.fromLTRB(12.0, 12.0, 12.0, isMobile ? 6.0 : 12.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: SizedBox(
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
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: _quantitaSelezionata > 1 ? Colors.orange.shade100 : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _quantitaSelezionata > 1 ? Colors.orange.shade800 : Colors.grey.shade300, width: 2),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _quantitaSelezionata,
                          icon: Icon(Icons.arrow_drop_down, color: _quantitaSelezionata > 1 ? Colors.orange.shade800 : Colors.indigo),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _quantitaSelezionata > 1 ? Colors.orange.shade900 : Colors.indigo.shade900),
                          items: List.generate(10, (index) => index + 1).map((q) {
                            return DropdownMenuItem<int>(
                              value: q,
                              child: Text('Qt: $q', style: const TextStyle(fontWeight: FontWeight.bold)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _quantitaSelezionata = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: _tabSelezionato == 3
                      ? Center(
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
                        // MODIFICA ANTI-OVERFLOW: Il tastierino ora può scorrere se lo schermo è minuscolo
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                                          setState(() => _idProdottoCustomSelezionato = val);
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

                              // Griglia dei numeri
                              GridView.count(
                                shrinkWrap: true, // Fondamentale dentro il SingleChildScrollView
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 3,
                                childAspectRatio: isMobile ? 2.2 : 1.9, // Sui telefoni i tasti sono leggermente più schiacciati
                                mainAxisSpacing: 5,
                                crossAxisSpacing: 5,
                                children: [
                                  _buildTastoTastierino('7'), _buildTastoTastierino('8'), _buildTastoTastierino('9'),
                                  _buildTastoTastierino('4'), _buildTastoTastierino('5'), _buildTastoTastierino('6'),
                                  _buildTastoTastierino('1'), _buildTastoTastierino('2'), _buildTastoTastierino('3'),
                                  _buildTastoTastierino('C', coloreSfondo: Colors.red.shade50, coloreTesto: Colors.red.shade700),
                                  _buildTastoTastierino('0'),
                                  _buildTastoTastierino('.'),
                                ],
                              ),
                              const SizedBox(height: 8),
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
                                  label: Text('AGGIUNGI ($_quantitaSelezionata PZ)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                      : GridView.builder(
                    // Sui telefoni mostra 2 colonne per far entrare bene i nomi, sui tablet 3 colonne
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isMobile ? 2 : 3,
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
                        onPressed: () => _aggiungiAlCarrello(p, quantitaAggiuntiva: _quantitaSelezionata),
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
          );

          // --- PANNELLO DESTRO: CARRELLO ---
          Widget pannelloCarrello = Container(
            margin: EdgeInsets.only(
                left: isMobile ? 12 : 0,
                right: 12,
                top: isMobile ? 0 : 12,
                bottom: 12
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(-2, 3),
                ),
              ],
            ),
            padding: EdgeInsets.all(isMobile ? 12.0 : 16.0), // Padding ridotto sui telefoni
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
                          dense: isMobile, // Liste più compatte sui telefoni
                          title: Text('${quantita}x ${prodotto.nome} - ${prezzoTotale.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          trailing: IconButton(icon: const Icon(Icons.remove_circle, color: Colors.deepOrange), onPressed: () => _rimuoviDalCarrello(prodotto)),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(thickness: 2),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 8.0 : 16.0),
                  child: Text('Totale: ${_totaleIncasso.toStringAsFixed(2)} €', style: TextStyle(fontSize: isMobile ? 24 : 28, fontWeight: FontWeight.bold, color: Colors.indigo)),
                ),

                // MODIFICA ANTI-OVERFLOW: Pulsanti Affiancati su Smartphone, Impilati su Tablet
                if (isMobile)
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 45,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, padding: EdgeInsets.zero),
                            onPressed: _svuotaCarrello,
                            child: const Text('Svuota', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 45,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, padding: EdgeInsets.zero),
                            onPressed: _gestisciStampaScontrino,
                            child: const Text('Stampa', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
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
              ],
            ),
          );

          // LOGICA FINALE:
          if (isMobile) {
            // Modalità Telefono: Prodotti sopra, Carrello sotto
            return Column(
              children: [
                Expanded(flex: 3, child: pannelloProdotti),
                Expanded(flex: 2, child: pannelloCarrello),
              ],
            );
          } else {
            // Modalità Tablet: Prodotti a sinistra, Carrello a destra
            return Row(
              children: [
                Expanded(flex: 3, child: pannelloProdotti),
                Expanded(flex: 2, child: pannelloCarrello),
              ],
            );
          }
        },
      ),
    );
  }
}