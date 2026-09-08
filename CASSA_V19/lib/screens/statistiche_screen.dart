import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../printer_globals.dart'; // Memoria globale della stampante

class StatisticheScreen extends StatefulWidget {
  final String nomeEvento;
  final double incassoTotale;
  final int numeroScontrini;
  final Map<String, int> prodottiVenduti;
  final VoidCallback onAggiorna;
  final VoidCallback onStampaChiusura;
  final Function(bool) onArchiviaEazzera;

  const StatisticheScreen({
    super.key,
    required this.nomeEvento,
    required this.incassoTotale,
    required this.numeroScontrini,
    required this.prodottiVenduti,
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
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black87, width: 2)),
              child: Column(
                children: [
                  Image.asset('assets/images/logo_scontrino.png', height: 80),
                  const SizedBox(height: 6),
                  Text(widget.nomeEvento.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace'), textAlign: TextAlign.center),
                  const Text('SCONTRINO DI CHIUSURA', style: TextStyle(fontSize: 14, fontFamily: 'monospace')),
                  Text(DateTime.now().toString().substring(0, 16), style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey)),
                  const Divider(color: Colors.black87, thickness: 1.5),
                  const SizedBox(height: 10),

                  ...widget.prodottiVenduti.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key.toUpperCase(), style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
                        Text('Qt: ${e.value}', style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )),

                  const SizedBox(height: 10),
                  const Divider(color: Colors.black87, thickness: 1.5),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTALE INCASSO:', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${widget.incassoTotale.toStringAsFixed(2)} €', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('SCONTRINI EMESSI:', style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
                      Text('${widget.numeroScontrini}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('- EVENTO CONCLUSO -', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.grey)),
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
      bytes.addAll(generator.imageRaster(logoImage, align: PosAlign.center));
      bytes.addAll(generator.feed(1));
    }

    bytes.addAll(generator.text(widget.nomeEvento.toUpperCase(), styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2)));
    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.text('SCONTRINO DI CHIUSURA', styles: const PosStyles(align: PosAlign.center, bold: true)));
    bytes.addAll(generator.text(DateTime.now().toString().substring(0, 16), styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(generator.hr());
    bytes.addAll(generator.feed(1));

    widget.prodottiVenduti.forEach((nome, quantita) {
      String nomeUpper = nome.toUpperCase();
      if (nomeUpper.length > 28) {
        nomeUpper = nomeUpper.substring(0, 28);
      }

      // FORZATURA A 4 CARATTERI: il numero avrà sempre la stessa larghezza
      String qtStr = 'Qt: ${quantita.toString().padLeft(4)}';

      int spazi = 42 - nomeUpper.length - qtStr.length;
      if (spazi < 1) spazi = 1;
      String riga = nomeUpper + (' ' * spazi) + qtStr;
      bytes.addAll(generator.text(riga, styles: const PosStyles(fontType: PosFontType.fontA)));
    });

    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.hr());

    String etichettaTotale = 'TOTALE INCASSO:';
    String valoreTotale = '${widget.incassoTotale.toStringAsFixed(2)} EUR';
    int spaziTotale = 42 - etichettaTotale.length - valoreTotale.length;
    if (spaziTotale < 1) spaziTotale = 1;
    String rigaTotale = etichettaTotale + (' ' * spaziTotale) + valoreTotale;
    bytes.addAll(generator.text(rigaTotale, styles: const PosStyles(fontType: PosFontType.fontA, bold: true)));

    String etichettaEmessi = 'SCONTRINI EMESSI:';
    String valoreEmessi = '${widget.numeroScontrini}';
    int spaziEmessi = 42 - etichettaEmessi.length - valoreEmessi.length;
    if (spaziEmessi < 1) spaziEmessi = 1;
    String rigaEmessi = etichettaEmessi + (' ' * spaziEmessi) + valoreEmessi;
    bytes.addAll(generator.text(rigaEmessi, styles: const PosStyles(fontType: PosFontType.fontA)));

    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.text('- EVENTO CONCLUSO -', styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());

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
            const Text('Prodotti Venduti', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),

            Expanded(
              child: widget.prodottiVenduti.isEmpty
                  ? const Center(child: Text('Nessun prodotto venduto in questo evento.', style: TextStyle(fontSize: 16, color: Colors.grey)))
                  : ListView.builder(
                itemCount: widget.prodottiVenduti.length,
                itemBuilder: (context, index) {
                  final nomeProdotto = widget.prodottiVenduti.keys.elementAt(index);
                  final quantita = widget.prodottiVenduti[nomeProdotto]!;

                  return Card(
                    color: Colors.white,
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      title: Text(nomeProdotto, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      trailing: Text('Quantità: $quantita', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
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
                    onPressed: () {
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
                      bool azzeraListino = false;
                      showDialog(
                          context: context,
                          builder: (context) {
                            return StatefulBuilder(
                              builder: (context, setStateDialog) {
                                return AlertDialog(
                                  title: const Text('Archivia e Azzera Evento'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Vuoi archiviare l\'evento nello storico e azzerare incassi e contatori?'),
                                      const SizedBox(height: 16),
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
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        widget.onArchiviaEazzera(azzeraListino);
                                      },
                                      child: const Text('Conferma Archiviazione'),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                      );
                    },
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
                      onPressed: () {
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
                        bool azzeraListino = false;
                        showDialog(
                            context: context,
                            builder: (context) {
                              return StatefulBuilder(
                                builder: (context, setStateDialog) {
                                  return AlertDialog(
                                    title: const Text('Archivia e Azzera Evento'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('Vuoi archiviare l\'evento nello storico e azzerare incassi e contatori?'),
                                        const SizedBox(height: 16),
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
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                        onPressed: () {
                                          Navigator.pop(context);
                                          widget.onArchiviaEazzera(azzeraListino);
                                        },
                                        child: const Text('Conferma Archiviazione'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                        );
                      },
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