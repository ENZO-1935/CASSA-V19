import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../printer_globals.dart'; // Memoria globale della stampante

class StatisticheScreen extends StatefulWidget {
  final String nomeEvento;
  final double incassoTotale;
  final double incassoContanti;
  final double incassoCarta;
  final int numeroScontrini;
  final Map<String, int> prodottiVenduti;
  final Map<String, double> listinoPrezzi;
  final VoidCallback onAggiorna;
  final VoidCallback onStampaChiusura;
  final Function(bool, bool) onArchiviaEazzera;

  const StatisticheScreen({
    super.key,
    required this.nomeEvento,
    required this.incassoTotale,
    required this.incassoContanti,
    required this.incassoCarta,
    required this.numeroScontrini,
    required this.prodottiVenduti,
    this.listinoPrezzi = const {},
    required this.onAggiorna,
    required this.onStampaChiusura,
    required this.onArchiviaEazzera,
  });

  @override
  State<StatisticheScreen> createState() => _StatisticheScreenState();
}

class _StatisticheScreenState extends State<StatisticheScreen> {
  var printerManager = PrinterManager.instance;

  void _mostraAnteprimaChiusura() {
    if (widget.nomeEvento.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nessun evento attivo.'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade200,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('🖨️ ANTEPRIMA CHIUSURA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black87, width: 2)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/images/logo_scontrino.png', height: 80),
                  const SizedBox(height: 10),
                  Text(
                    widget.nomeEvento.toUpperCase(),
                    style: TextStyle(
                        fontSize: widget.nomeEvento.length > 21 ? 14 : 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace'
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  ),
                  const Text('SCONTRINO DI CHIUSURA', style: TextStyle(fontSize: 14, fontFamily: 'monospace'), textAlign: TextAlign.center, maxLines: 1),
                  Text(DateTime.now().toString().substring(0, 16), style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.grey), textAlign: TextAlign.center, maxLines: 1),

                  const SizedBox(height: 12),
                  const Text('==========================================', style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1),

                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('QT   ', style: TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold)),
                      Expanded(child: Text('PRODOTTO', style: TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold))),
                      Text('  TOTALE', style: TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Text('==========================================', style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1),
                  const SizedBox(height: 4),

                  ...() {
                    int idx = 0;
                    int tot = widget.prodottiVenduti.length;
                    return widget.prodottiVenduti.entries.map((e) {
                      bool isLast = (idx == tot - 1);
                      idx++;
                      double pUnitario = widget.listinoPrezzi[e.key] ?? 0.0;
                      double totProdotto = e.value * pUnitario;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              children: [
                                Text('${e.value.toString().padLeft(4)} ', style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
                                Expanded(child: Text(e.key.toUpperCase(), style: const TextStyle(fontFamily: 'monospace', fontSize: 13), overflow: TextOverflow.ellipsis)),
                                Text(totProdotto.toStringAsFixed(2), style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
                              ],
                            ),
                          ),
                          if (!isLast)
                            const Text('------------------------------------------', style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black54), textAlign: TextAlign.center, maxLines: 1),
                        ],
                      );
                    }).toList();
                  }(),

                  const SizedBox(height: 4),
                  const Text('==========================================', style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1),

                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('SCONTRINI EMESSI:', style: TextStyle(fontFamily: 'monospace', fontSize: 13)),
                      Text('${widget.numeroScontrini}', style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Text('==========================================', style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1),
                  const SizedBox(height: 16),

                  const Text('TOTALE INCASSO', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
                  Text('${widget.incassoTotale.toStringAsFixed(2)} €', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 24), textAlign: TextAlign.center),

                  const SizedBox(height: 12),
                  Text('di cui Contanti: ${widget.incassoContanti.toStringAsFixed(2)} €', style: const TextStyle(fontFamily: 'monospace', fontSize: 13), textAlign: TextAlign.center),
                  Text('di cui Carta: ${widget.incassoCarta.toStringAsFixed(2)} €', style: const TextStyle(fontFamily: 'monospace', fontSize: 13), textAlign: TextAlign.center),

                  const SizedBox(height: 24),
                  const Text('- EVENTO CONCLUSO -', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              widget.onStampaChiusura();
            },
            child: const Text('Completa Simulazione'),
          ),
        ],
      ),
    );
  }

  Future<List<int>> _generaByteChiusura() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    bytes.addAll(List<int>.from(generator.reset()));
    bytes.addAll([27, 97, 1]);

    img.Image? logoImage;
    try {
      final ByteData data = await rootBundle.load('assets/images/logo_scontrino.png');
      final Uint8List imgBytes = data.buffer.asUint8List();
      final decodedImage = img.decodeImage(imgBytes);
      if (decodedImage != null) {
        var resized = img.copyResize(decodedImage, width: 512);
        logoImage = img.grayscale(resized);
      }
    } catch (e) {
      debugPrint("Errore logo: $e");
    }

    if (logoImage != null) {
      bytes.addAll(List<int>.from(generator.imageRaster(logoImage, align: PosAlign.center)));
      bytes.addAll(List<int>.from(generator.feed(1)));
    }

    String nomeEventoStampa = widget.nomeEvento.toUpperCase();
    if (nomeEventoStampa.length > 42) nomeEventoStampa = nomeEventoStampa.substring(0, 42);

    if (nomeEventoStampa.length > 21) {
      // Font stretto e alto (altezza x2, larghezza x1) per non andare mai a capo
      bytes.addAll(List<int>.from(generator.text(nomeEventoStampa, styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size1))));
    } else {
      // Font Gigante (altezza x2, larghezza x2) se è corto
      bytes.addAll(List<int>.from(generator.text(nomeEventoStampa, styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2))));
    }

    bytes.addAll(List<int>.from(generator.feed(1)));
    bytes.addAll(List<int>.from(generator.text('SCONTRINO DI CHIUSURA', styles: const PosStyles(align: PosAlign.center, bold: true))));
    bytes.addAll(List<int>.from(generator.text(DateTime.now().toString().substring(0, 16), styles: const PosStyles(align: PosAlign.center))));

    bytes.addAll(List<int>.from(generator.feed(1)));
    bytes.addAll(List<int>.from(generator.text('==========================================', styles: const PosStyles(align: PosAlign.center))));

    bytes.addAll(List<int>.from(generator.text('QT   PRODOTTO                       TOTALE', styles: const PosStyles(fontType: PosFontType.fontA, bold: true))));
    bytes.addAll(List<int>.from(generator.text('==========================================', styles: const PosStyles(align: PosAlign.center))));

    int count = 0;
    int totale = widget.prodottiVenduti.length;

    widget.prodottiVenduti.forEach((nome, quantita) {
      bool isLast = (count == totale - 1);
      count++;

      String nomeUpper = nome.toUpperCase();
      double prezzoUnitario = widget.listinoPrezzi[nome] ?? 0.0;
      double incassoProdotto = quantita * prezzoUnitario;
      String prezzoStr = incassoProdotto.toStringAsFixed(2);

      String qtColonna = '${quantita.toString().padLeft(4)} ';
      int maxSpazioNome = 42 - qtColonna.length - prezzoStr.length - 1;

      if (nomeUpper.length > maxSpazioNome) {
        nomeUpper = nomeUpper.substring(0, maxSpazioNome);
      }

      int spaziVuoti = 42 - qtColonna.length - nomeUpper.length - prezzoStr.length;
      if (spaziVuoti < 1) spaziVuoti = 1;

      String riga = qtColonna + nomeUpper + (' ' * spaziVuoti) + prezzoStr;

      bytes.addAll(List<int>.from(generator.text(riga, styles: const PosStyles(fontType: PosFontType.fontA))));

      if (!isLast) {
        bytes.addAll(List<int>.from(generator.text('------------------------------------------', styles: const PosStyles(align: PosAlign.center))));
      }
    });

    bytes.addAll(List<int>.from(generator.text('==========================================', styles: const PosStyles(align: PosAlign.center))));

    String etichettaEmessi = 'SCONTRINI EMESSI:';
    String valoreEmessi = '${widget.numeroScontrini}';
    int spaziEmessi = 42 - etichettaEmessi.length - valoreEmessi.length;
    String rigaEmessi = etichettaEmessi + (' ' * spaziEmessi) + valoreEmessi;
    bytes.addAll(List<int>.from(generator.text(rigaEmessi, styles: const PosStyles(fontType: PosFontType.fontA))));

    bytes.addAll(List<int>.from(generator.text('==========================================', styles: const PosStyles(align: PosAlign.center))));
    bytes.addAll(List<int>.from(generator.feed(1)));

    bytes.addAll(List<int>.from(generator.text('TOTALE INCASSO', styles: const PosStyles(align: PosAlign.center, bold: true))));
    bytes.addAll(List<int>.from(generator.text('${widget.incassoTotale.toStringAsFixed(2)} EUR', styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2))));

    bytes.addAll(List<int>.from(generator.feed(1)));
    bytes.addAll(List<int>.from(generator.text('di cui Contanti: ${widget.incassoContanti.toStringAsFixed(2)} EUR', styles: const PosStyles(align: PosAlign.center))));
    bytes.addAll(List<int>.from(generator.text('di cui Carta: ${widget.incassoCarta.toStringAsFixed(2)} EUR', styles: const PosStyles(align: PosAlign.center))));

    bytes.addAll(List<int>.from(generator.feed(2)));
    bytes.addAll(List<int>.from(generator.text('- EVENTO CONCLUSO -', styles: const PosStyles(align: PosAlign.center))));
    bytes.addAll(List<int>.from(generator.feed(2)));
    bytes.addAll(List<int>.from(generator.cut()));

    return bytes;
  }

  void _gestisciStampaFisica() async {
    if (widget.nomeEvento.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Nessun evento attivo per stampare la chiusura.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          )
      );
      return;
    }

    if (stampanteGlobale == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Nessuna stampante configurata. Vai prima nella schermata Cassa a collegarla.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          )
      );
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
      final bytes = await _generaByteChiusura();
      printerManager.send(type: connessioneGlobale, bytes: bytes);

      widget.onStampaChiusura();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore di stampa: $e', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          )
      );
    }
  }

  void _mostraDialogoArchiviazione() {
    if (widget.nomeEvento.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Non c\'è nessun evento attivo da archiviare.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          )
      );
      return;
    }

    bool azzeraIncassi = true;
    bool azzeraListino = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Archivia Evento'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Vuoi salvare una copia di questo evento nello storico?'),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Azzera incassi e chiudi evento attivo', style: TextStyle(fontWeight: FontWeight.bold)),
                    value: azzeraIncassi,
                    activeColor: Colors.indigo,
                    onChanged: (bool? value) {
                      setStateDialog(() {
                        azzeraIncassi = value ?? true;
                      });
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Azzera anche il listino prodotti', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    value: azzeraListino,
                    activeColor: Colors.red,
                    onChanged: (bool? value) {
                      setStateDialog(() {
                        azzeraListino = value ?? false;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onArchiviaEazzera(azzeraListino, azzeraIncassi);
                  },
                  child: const Text('Conferma Archiviazione'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Statistiche e Chiusura Evento', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.grey.shade100,
        surfaceTintColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.indigo.shade50,
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Incasso Totale Evento', style: TextStyle(fontSize: isMobile ? 13 : 16, color: Colors.indigo, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text('${widget.incassoTotale.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo)),
                          ),
                          const Divider(),
                          Text('💵 Contanti: ${widget.incassoContanti.toStringAsFixed(2)} €', style: TextStyle(fontSize: isMobile ? 12 : 14, color: Colors.indigo.shade800, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('💳 Carta: ${widget.incassoCarta.toStringAsFixed(2)} €', style: TextStyle(fontSize: isMobile ? 12 : 14, color: Colors.indigo.shade800, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    color: Colors.orange.shade50,
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Scontrini Emessi', style: TextStyle(fontSize: isMobile ? 13 : 16, color: Colors.orange, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text('${widget.numeroScontrini}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.orange)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Prodotti Venduti', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                TextButton.icon(
                  onPressed: _mostraAnteprimaChiusura,
                  icon: const Icon(Icons.receipt_long, color: Colors.indigo),
                  label: const Text('Anteprima Scontrino', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 4),

            Expanded(
              child: widget.prodottiVenduti.isEmpty
                  ? const Center(child: Text('Nessun prodotto venduto in questo evento.', style: TextStyle(fontSize: 16, color: Colors.grey)))
                  : ListView.builder(
                itemCount: widget.prodottiVenduti.length,
                itemBuilder: (context, index) {
                  final nomeProdotto = widget.prodottiVenduti.keys.elementAt(index);
                  final quantita = widget.prodottiVenduti[nomeProdotto]!;
                  final pUnitario = widget.listinoPrezzi[nomeProdotto] ?? 0.0;
                  final incasso = quantita * pUnitario;

                  return Card(
                    color: Colors.white,
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      title: Text(nomeProdotto, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: Text('Incasso generato: €${incasso.toStringAsFixed(2)}', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                      trailing: Text('Qt: $quantita', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: widget.onAggiorna,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Aggiorna', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: _gestisciStampaFisica,
                    icon: const Icon(Icons.print),
                    label: const Text('Stampa Chiusura', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: _mostraDialogoArchiviazione,
                    icon: const Icon(Icons.archive),
                    label: const Text('Archivia e Azzera', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                      onPressed: widget.onAggiorna,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Aggiorna', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                      onPressed: _gestisciStampaFisica,
                      icon: const Icon(Icons.print),
                      label: const Text('Stampa Chiusura', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                      onPressed: _mostraDialogoArchiviazione,
                      icon: const Icon(Icons.archive),
                      label: const Text('Archivia e Azzera', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}