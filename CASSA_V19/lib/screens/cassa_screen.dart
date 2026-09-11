import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
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
  final Function(Map<Prodotto, int>, double, String) onStampaScontrino;
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

  // Tipi corretti nativi della libreria POS
  StreamSubscription<USBStatus>? _usbSubscription;
  StreamSubscription<BTStatus>? _btSubscription;

  int get _ordineCorrente => widget.numeroScontriniEmmessi + 1;

  @override
  void initState() {
    super.initState();

    // --- LISTENER IN TEMPO REALE PER USB E BLUETOOTH ---
    _usbSubscription = printerManager.stateUSB.listen((status) {
      if (status == USBStatus.none || status.index == 0) {
        _disconnettiStampanteForzatamente();
      }
    });

    _btSubscription = printerManager.stateBluetooth.listen((status) {
      if (status == BTStatus.none) {
        _disconnettiStampanteForzatamente();
      }
    });
  }

  @override
  void dispose() {
    _usbSubscription?.cancel();
    _btSubscription?.cancel();
    super.dispose();
  }

  // Funzione che sgancia la stampante, blocca tutto e avvisa l'utente
  void _disconnettiStampanteForzatamente([String messaggioExtra = ""]) {
    if (mounted && stampanteGlobale != null) {
      setState(() {
        stampanteGlobale = null; // <-- FA DIVENTARE L'ICONA ROSSA
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '⚠️ STAMPANTE SCOLLEGATA!\n${messaggioExtra.isNotEmpty ? messaggioExtra : "Cavo USB rimosso o connessione persa."}\n\nLA VENDITA È STATA ANNULLATA!',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, height: 1.4, color: Colors.white)
            ),
            backgroundColor: Colors.red.shade800,
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
          )
      );
    }
  }

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
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black87, width: 2)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                      'assets/images/logo_falo.jpg',
                      height: 40,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Text('CASSA_V19', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
                  ),
                  const SizedBox(height: 2),
                  // Font largo e grande come prima
                  Text(widget.nomeEvento.toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'monospace'), textAlign: TextAlign.center),
                  const SizedBox(height: 2),
                  Text('Ordine #${_ordineCorrente.toString().padLeft(4, '0')}', style: const TextStyle(fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const Divider(color: Colors.black54, thickness: 1.5, height: 4, indent: 8, endIndent: 8),
                  const SizedBox(height: 2),
                  // Font largo e grande per il prodotto
                  Text('1x ${prodotto.nome.toUpperCase()}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'monospace', height: 1.1)),
                  const SizedBox(height: 2),
                  const Divider(color: Colors.black54, thickness: 1.5, height: 4, indent: 8, endIndent: 8),

                  // QUI LA MODIFICA NELL'ANTEPRIMA: Data e Ticket assieme, no prezzo
                  Text('$dataOra   -   Ticket $ticketCorrente di $totaleTicket', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 2),
                  const Text('CASSA_V19', style: TextStyle(fontSize: 9, fontFamily: 'monospace', color: Colors.grey), textAlign: TextAlign.center),
                ],
              ),
            )
        );
        if (ticketCorrente < totaleTicket) {
          listaTicket.add(const Padding(padding: EdgeInsets.symmetric(vertical: 4.0), child: Text('- - - - - ✂️ - - - - -', style: TextStyle(color: Colors.grey, fontSize: 16, letterSpacing: 2), textAlign: TextAlign.center)));
        }
        ticketCorrente++;
      }
    });
    return listaTicket;
  }

  void _mostraAnteprimaScontrino(Map<Prodotto, int> carrelloVenduto, double totale, String metodoPagamento) {
    String dataOraStr = DateTime.now().toString().substring(0, 16);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade200, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Column(
          children: [
            const Text('🖨️ SIMULAZIONE TICKET', style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold)),
            Text('Totale pagato: ${totale.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 16, color: Colors.indigo, fontWeight: FontWeight.bold)),
            Text('Pagamento in: $metodoPagamento', style: const TextStyle(fontSize: 12, color: Colors.black54)),
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
              widget.onStampaScontrino(carrelloVenduto, totale, metodoPagamento);
              _svuotaCarrello();
            },
            child: const Text('Completa Ordine Simulato'),
          ),
        ],
      ),
    );
  }

  void _gestisciAzioneDopoPagamento(String metodoPagamento) {
    if (stampanteGlobale != null) {
      _eseguiStampaFisica(metodoPagamento);
    } else {
      _mostraDialogoStampante(metodoPreselezionato: metodoPagamento);
    }
  }

  // MODIFICA ANTI-BLOCCO ANDROID INSERITA QUI
  void _mostraDialogoStampante({String? metodoPreselezionato}) {
    bool staCercando = true;
    bool scansioneAvviata = false;
    List<PrinterDevice> dispositiviTrovati = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {

            void scansiona() {
              setStateModal(() { staCercando = true; dispositiviTrovati.clear(); });

              printerManager.discovery(type: connessioneGlobale, isBle: false).listen((device) {
                // --- FILTRO ANTI FANTASMI (Ignora stampanti virtuali di Windows) ---
                String nomeDispositivo = device.name?.toLowerCase() ?? '';
                if (nomeDispositivo.contains('pdf') ||
                    nomeDispositivo.contains('fax') ||
                    nomeDispositivo.contains('onenote') ||
                    nomeDispositivo.contains('xps') ||
                    nomeDispositivo.contains('microsoft') ||
                    nomeDispositivo.contains('samsung') ||
                    nomeDispositivo.contains('hp ') ||
                    nomeDispositivo.contains('brother') ||
                    nomeDispositivo.contains('canon')) {
                  return; // Salta questo dispositivo e non mostrarlo
                }

                if (!dispositiviTrovati.any((d) => d.name == device.name && d.address == device.address)) {
                  setStateModal(() => dispositiviTrovati.add(device));
                }
              }).onDone(() {
                if (mounted) {
                  setStateModal(() => staCercando = false);
                }
              });
            }

            if (!scansioneAvviata) {
              scansioneAvviata = true;
              Future.microtask(() => scansiona());
            }

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
                              scansiona();
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
                          ? Center(child: Text('Nessuna stampante fisica trovata in modalità ${connessioneGlobale.name}.', textAlign: TextAlign.center))
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
                              if (_carrello.isNotEmpty) {
                                if (metodoPreselezionato != null) {
                                  _eseguiStampaFisica(metodoPreselezionato);
                                } else {
                                  _mostraDialogoPagamento();
                                }
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (stampanteGlobale != null) // TASTO ROSSO PER SCOLLEGARE FORZATAMENTE LA STAMPANTE
                  TextButton(
                    onPressed: () {
                      _disconnettiStampanteForzatamente("Stampante scollegata manualmente.");
                      printerManager.disconnect(type: connessioneGlobale);
                      Navigator.pop(context);
                    },
                    child: const Text('Scollega Stampante', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                const Spacer(),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
                if (_carrello.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      String metodoSicuro = metodoPreselezionato ?? 'CONTANTI';
                      _mostraAnteprimaScontrino(Map.from(_carrello), _totaleIncasso, metodoSicuro);
                    },
                    child: const Text('Simula a Schermo', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  ),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                    onPressed: staCercando ? null : () => scansiona(),
                    child: const Icon(Icons.refresh)
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _mostraDialogoPagamento() {
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

    bool isContanti = false;
    String importoInserito = '';

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setStateModal) {
                if (!isContanti) {
                  return AlertDialog(
                    title: const Text('METODO DI PAGAMENTO', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                    content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Totale: ${_totaleIncasso.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade700,
                                        foregroundColor: Colors.white,
                                        // Padding orizzontale ridotto per fare spazio
                                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                                      ),
                                      icon: const Icon(Icons.credit_card, size: 28),
                                      label: const FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text('CARTA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _gestisciAzioneDopoPagamento('CARTA');
                                      }
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade700,
                                      foregroundColor: Colors.white,
                                      // Padding orizzontale ridotto per fare spazio
                                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                                    ),
                                    icon: const Icon(Icons.payments, size: 28),
                                    label: const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text('CONTANTI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    ),
                                    onPressed: () => setStateModal(() => isContanti = true),
                                  ),
                                ),
                              ]
                          )
                        ]
                    ),
                    actions: [ TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla', style: TextStyle(color: Colors.grey))) ],
                  );
                } else {
                  // Calcolo logico del resto
                  double importoRicevuto = importoInserito.isEmpty
                      ? _totaleIncasso
                      : (double.tryParse(importoInserito) ?? _totaleIncasso);

                  double resto = importoRicevuto - _totaleIncasso;
                  bool isImportoValido = importoInserito.isEmpty || importoRicevuto >= _totaleIncasso;

                  void premiTastoResto(String tasto) {
                    setStateModal(() {
                      if (tasto == 'C') {
                        importoInserito = '';
                      } else if (tasto == '.') {
                        if (!importoInserito.contains('.')) importoInserito += '.';
                      } else {
                        if (importoInserito.length < 6) { // Limite sicurezza
                          importoInserito += tasto;
                        }
                      }
                    });
                  }

                  Widget buildTasto(String t, {Color? bg, Color? fg}) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bg ?? Colors.grey.shade200,
                        foregroundColor: fg ?? Colors.black87,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 1,
                      ),
                      onPressed: () => premiTastoResto(t),
                      child: Text(t, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    );
                  }

                  return AlertDialog(
                      title: const Text('CALCOLO RESTO', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                      content: SizedBox(
                        width: 320,
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Totale da pagare: ${_totaleIncasso.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),

                              // Display dell'importo inserito
                              Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.indigo.shade300, width: 2),
                                      borderRadius: BorderRadius.circular(8)
                                  ),
                                  child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Ricevuto:', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
                                        Text(
                                            importoInserito.isEmpty ? '${_totaleIncasso.toStringAsFixed(2)} € (Esatto)' : '$importoInserito €',
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: importoInserito.isEmpty ? Colors.green.shade700 : Colors.black87
                                            )
                                        ),
                                      ]
                                  )
                              ),
                              const SizedBox(height: 12),

                              // Display del Resto da dare
                              Container(
                                padding: const EdgeInsets.all(12), width: double.infinity,
                                decoration: BoxDecoration(
                                    color: isImportoValido ? Colors.green.shade50 : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isImportoValido ? Colors.green.shade300 : Colors.red.shade300, width: 2)
                                ),
                                child: Text(
                                    isImportoValido
                                        ? 'RESTO: ${resto <= 0 ? "0.00" : resto.toStringAsFixed(2)} €'
                                        : 'IMPORTO INSUFFICIENTE',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 22,
                                        color: isImportoValido ? Colors.green.shade800 : Colors.red.shade800,
                                        fontWeight: FontWeight.bold
                                    )
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Tastierino Numerico Compatto
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 3,
                                childAspectRatio: 2.0, // Tasti un po' più larghi che alti
                                mainAxisSpacing: 6,
                                crossAxisSpacing: 6,
                                children: [
                                  buildTasto('7'), buildTasto('8'), buildTasto('9'),
                                  buildTasto('4'), buildTasto('5'), buildTasto('6'),
                                  buildTasto('1'), buildTasto('2'), buildTasto('3'),
                                  buildTasto('C', bg: Colors.red.shade50, fg: Colors.red.shade700),
                                  buildTasto('0'),
                                  buildTasto('.', bg: Colors.grey.shade300),
                                ],
                              ),
                            ]
                        ),
                      ),
                      actions: [
                        TextButton(
                            onPressed: () => setStateModal(() {
                              isContanti = false;
                              importoInserito = '';
                            }),
                            child: const Text('Indietro', style: TextStyle(color: Colors.grey))
                        ),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: isImportoValido ? Colors.green.shade700 : Colors.grey,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
                            ),
                            onPressed: isImportoValido ? () {
                              Navigator.pop(context);
                              _gestisciAzioneDopoPagamento('CONTANTI');
                            } : null,
                            child: const Text('Conferma Pagamento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                        )
                      ]
                  );
                }
              }
          );
        }
    );
  }

  Future<List<int>> _generaByteScontrino(Map<Prodotto, int> carrelloVenduto) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    img.Image? logoFalo;
    try {
      final ByteData data = await rootBundle.load('assets/images/logo_falo.jpg');
      final Uint8List imgBytes = data.buffer.asUint8List();
      final decodedImage = img.decodeImage(imgBytes);
      if (decodedImage != null) {
        var resized = img.copyResize(decodedImage, width: 200);
        logoFalo = img.grayscale(resized);
      }
    } catch (e) {
      debugPrint("Errore immagine: $e");
    }

    // --- RESET HARDWARE E FORZATURA CENTRATURA FISSA ---
    bytes.addAll(generator.reset());
    bytes.addAll([27, 97, 1]); // Comando ESC/POS hardware: Centrato fisso

    int totaleTicket = 0;
    carrelloVenduto.forEach((p, q) => totaleTicket += q);
    int ticketCorrente = 1;

    carrelloVenduto.forEach((prodotto, quantita) {
      for (int i = 0; i < quantita; i++) {

        if (logoFalo != null) {
          bytes.addAll(generator.imageRaster(logoFalo, align: PosAlign.center));
        } else {
          bytes.addAll(generator.text('CASSA_V19', styles: const PosStyles(align: PosAlign.center, bold: false, fontType: PosFontType.fontB)));
        }

        bytes.addAll(generator.feed(1));

        bytes.addAll(generator.text(widget.nomeEvento.toUpperCase(), styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2, fontType: PosFontType.fontB)));

        bytes.addAll(generator.feed(1));
        bytes.addAll(generator.text('Ordine #${_ordineCorrente.toString().padLeft(4, '0')}', styles: const PosStyles(align: PosAlign.center, bold: true, fontType: PosFontType.fontB)));

        bytes.addAll(generator.text('_______________________________________________________', styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB)));
        bytes.addAll(generator.feed(1));

        bytes.addAll(generator.text('1x ${prodotto.nome.toUpperCase()}', styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2, fontType: PosFontType.fontB)));

        bytes.addAll(generator.feed(1));
        bytes.addAll(generator.text('_______________________________________________________', styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB)));

        // QUI LA MODIFICA ALLA STAMPA REALE: Data e Ticket assieme, no prezzo
        String dataOraStr = DateTime.now().toString().substring(0, 16);
        bytes.addAll(generator.text('$dataOraStr   -   Ticket $ticketCorrente di $totaleTicket', styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB)));
        bytes.addAll(generator.text('CASSA_V19', styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB)));

        bytes.addAll(generator.feed(1));
        bytes.addAll(generator.cut());

        ticketCorrente++;
      }
    });
    return bytes;
  }

  // --- LOGICA DI STAMPA ANTI-WINDOWS SPOOLER ---
  void _eseguiStampaFisica(String metodoPagamento) async {
    try {
      if (stampanteGlobale == null) {
        throw Exception("Nessuna stampante connessa.");
      }

      dynamic printerInput;
      if (connessioneGlobale == PrinterType.usb) {
        printerInput = UsbPrinterInput(name: stampanteGlobale!.name, productId: stampanteGlobale!.productId, vendorId: stampanteGlobale!.vendorId);
      } else if (connessioneGlobale == PrinterType.bluetooth) {
        printerInput = BluetoothPrinterInput(name: stampanteGlobale!.name, address: stampanteGlobale!.address!, isBle: false);
      } else if (connessioneGlobale == PrinterType.network) {
        printerInput = TcpPrinterInput(ipAddress: stampanteGlobale!.address!);
      }

      // CONTROLLO DI SICUREZZA: Connettiamo per vedere se è fisicamente presente
      bool isConnected = await printerManager.connect(type: connessioneGlobale, model: printerInput);

      if (!isConnected) {
        throw Exception("La stampante non risponde. Potrebbe essere spenta o scollegata.");
      }

      // Genero i byte solo dopo essere certo della connessione
      final bytes = await _generaByteScontrino(Map.from(_carrello));

      // Invia alla stampante
      await printerManager.send(type: connessioneGlobale, bytes: bytes);

      // SOLO SE ARRIVA FINO A QUI SENZA ERRORI CATASTROFICI REGISTRA LA VENDITA
      double totale = _totaleIncasso;
      widget.onStampaScontrino(Map.from(_carrello), totale, metodoPagamento);
      _svuotaCarrello();

    } catch (e) {
      // ERRORE: La vendita viene bloccata e il carrello resta intatto.
      _disconnettiStampanteForzatamente(e.toString().replaceAll('Exception: ', ''));
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
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black26,
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
              onPressed: () => _mostraDialogoStampante(),
            ),
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 800;

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
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 3,
                                childAspectRatio: isMobile ? 2.2 : 1.9,
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
            padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
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
                          dense: isMobile,
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
                            onPressed: _mostraDialogoPagamento,
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
                          onPressed: _mostraDialogoPagamento,
                          child: const Text('Stampa Scontrino', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );

          if (isMobile) {
            return Column(
              children: [
                Expanded(flex: 3, child: pannelloProdotti),
                Expanded(flex: 2, child: pannelloCarrello),
              ],
            );
          } else {
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