import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../models/evento_archiviato.dart';
import '../models/ordine.dart';
import '../printer_globals.dart';

class StoricoScreen extends StatefulWidget {
  final List<EventoArchiviato> eventiPassati;
  final EventoArchiviato? eventoAttivoCorrente;
  final Map<String, double> listinoPrezziAttuale;
  final VoidCallback onAggiorna;
  final VoidCallback onSalvaStorico;
  final Function(String idEvento) onEliminaEvento;

  const StoricoScreen({
    super.key,
    required this.eventiPassati,
    this.eventoAttivoCorrente,
    required this.listinoPrezziAttuale,
    required this.onAggiorna,
    required this.onSalvaStorico,
    required this.onEliminaEvento,
  });

  @override
  State<StoricoScreen> createState() => _StoricoScreenState();
}

class _StoricoScreenState extends State<StoricoScreen> {
  String? _idEventoSelezionato;

  List<EventoArchiviato> get _tuttiGliEventi {
    List<EventoArchiviato> lista = List.from(widget.eventiPassati.reversed);
    if (widget.eventoAttivoCorrente != null) {
      lista.insert(0, widget.eventoAttivoCorrente!);
    }
    return lista;
  }

  void _apriDettagliFiltri(EventoArchiviato evento) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DettaglioEventoScreen(
          evento: evento,
          isAttivoLive: evento.id == 'ATTIVO_CORRENTE',
          onModificato: widget.onSalvaStorico,
        ),
      ),
    );
  }

  void _apriReportGlobale() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GlobalReportScreen(
          tuttiGliEventi: _tuttiGliEventi,
          listinoPrezziAttuale: widget.listinoPrezziAttuale,
        ),
      ),
    );
  }

  void _confermaEliminazione(EventoArchiviato evento) {
    if (evento.id == 'ATTIVO_CORRENTE') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Non puoi eliminare l\'evento in corso da qui. Usa la schermata Statistiche per azzerarlo.')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text('Elimina Evento', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            ),
          ],
        ),
        content: Text(
          'Sei sicuro di voler eliminare definitivamente l\'evento "${evento.nomeEvento.toUpperCase()}"?\n\nTutti i dati andranno persi.',
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            onPressed: () {
              widget.onEliminaEvento(evento.id);
              setState(() {
                _idEventoSelezionato = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Elimina Definitivamente', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listaEventi = _tuttiGliEventi;
    EventoArchiviato? eventoSelezionato;
    if (_idEventoSelezionato != null) {
      try {
        eventoSelezionato = listaEventi.firstWhere((e) => e.id == _idEventoSelezionato);
      } catch (_) {
        eventoSelezionato = null;
      }
    }

    bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Storico e Dati Live', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.grey.shade100,
        surfaceTintColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 24.0),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: listaEventi.isEmpty ? null : _apriReportGlobale,
                icon: const Icon(Icons.insights, size: 22),
                label: const Text('📊 Report Globale e Filtri Avanzati', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: listaEventi.isEmpty
                  ? const Center(child: Text('Nessun evento presente.', style: TextStyle(fontSize: 16, color: Colors.grey)))
                  : ListView.builder(
                itemCount: listaEventi.length,
                itemBuilder: (context, index) {
                  final evento = listaEventi[index];
                  final isSelezionato = evento.id == _idEventoSelezionato;
                  final isLive = evento.id == 'ATTIVO_CORRENTE';

                  return Card(
                    color: isSelezionato
                        ? (isLive ? Colors.green.shade50 : Colors.indigo.shade50)
                        : Colors.white,
                    elevation: isSelezionato ? 3 : 1,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: isLive ? Colors.green : (isSelezionato ? Colors.indigo : Colors.transparent),
                          width: isLive || isSelezionato ? 2 : 0
                      ),
                    ),
                    child: ListTile(
                      onTap: () {
                        setState(() {
                          _idEventoSelezionato = evento.id;
                        });
                      },
                      title: Row(
                        children: [
                          if (isLive) const Icon(Icons.circle, color: Colors.green, size: 12),
                          if (isLive) const SizedBox(width: 8),
                          Text(evento.nomeEvento.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isLive ? Colors.green.shade700 : Colors.indigo)),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text('${evento.dataChiusura}\nScontrini: ${evento.numeroScontriniEmessi} | Incasso: ${evento.incassoTotale.toStringAsFixed(2)} €'),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                    onPressed: widget.onAggiorna,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Aggiorna Dati', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: eventoSelezionato != null ? Colors.teal.shade600 : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: eventoSelezionato != null ? () => _apriDettagliFiltri(eventoSelezionato!) : null,
                    icon: const Icon(Icons.analytics),
                    label: const Text('Dettagli ed Elenco Scontrini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: eventoSelezionato != null && eventoSelezionato!.id != 'ATTIVO_CORRENTE' ? Colors.red.shade700 : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: eventoSelezionato != null && eventoSelezionato!.id != 'ATTIVO_CORRENTE' ? () => _confermaEliminazione(eventoSelezionato!) : null,
                    icon: const Icon(Icons.delete),
                    label: const Text('Elimina Archiviato', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                      label: const Text('Aggiorna Dati', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: eventoSelezionato != null ? Colors.teal.shade600 : Colors.grey.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: eventoSelezionato != null ? () => _apriDettagliFiltri(eventoSelezionato!) : null,
                      icon: const Icon(Icons.analytics),
                      label: const Text('Dettagli ed Elenco Scontrini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: eventoSelezionato != null && eventoSelezionato!.id != 'ATTIVO_CORRENTE' ? Colors.red.shade700 : Colors.grey.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: eventoSelezionato != null && eventoSelezionato!.id != 'ATTIVO_CORRENTE' ? () => _confermaEliminazione(eventoSelezionato!) : null,
                      icon: const Icon(Icons.delete),
                      label: const Text('Elimina Archiviato', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

// -----------------------------------------------------------------------------
// SCHERMATA DETTAGLI SINGOLO EVENTO
// -----------------------------------------------------------------------------

class DettaglioEventoScreen extends StatefulWidget {
  final EventoArchiviato evento;
  final bool isAttivoLive;
  final VoidCallback onModificato;

  const DettaglioEventoScreen({super.key, required this.evento, this.isAttivoLive = false, required this.onModificato});

  @override
  State<DettaglioEventoScreen> createState() => _DettaglioEventoScreenState();
}

class _DettaglioEventoScreenState extends State<DettaglioEventoScreen> {
  DateTime? _dataInizio;
  DateTime? _dataFine;

  double _incassoMostrato = 0.0;
  double _contantiMostrati = 0.0;
  double _cartaMostrati = 0.0;
  int _scontriniMostrati = 0;
  Map<String, int> _prodottiMostrati = {};

  List<Transazione> _transazioniFiltrate = [];
  bool _mostraElencoScontrini = false;

  bool get _filtroAttivo => _dataInizio != null || _dataFine != null;
  var printerManager = PrinterManager.instance;

  @override
  void initState() {
    super.initState();
    _ricalcolaTotali();
  }

  void _ricalcolaTotali() {
    _transazioniFiltrate.clear();

    if (!_filtroAttivo) {
      setState(() {
        _incassoMostrato = widget.evento.incassoTotale;
        _contantiMostrati = widget.evento.incassoContanti;
        _cartaMostrati = widget.evento.incassoCarta;
        _scontriniMostrati = widget.evento.numeroScontriniEmessi;
        _prodottiMostrati = {};
        widget.evento.prodottiVenduti.forEach((key, val) {
          _prodottiMostrati[key.toUpperCase()] = val;
        });
        _transazioniFiltrate = List.from(widget.evento.transazioni);
        _transazioniFiltrate.sort((a, b) => b.dataOra.compareTo(a.dataOra));
      });
      return;
    }

    double fTot = 0, fCont = 0, fCart = 0;
    int fNum = 0;
    Map<String, int> fProd = {};

    for (var t in widget.evento.transazioni) {
      bool incluso = true;
      if (_dataInizio != null && t.dataOra.isBefore(_dataInizio!)) incluso = false;
      if (_dataFine != null && t.dataOra.isAfter(_dataFine!)) incluso = false;

      if (incluso) {
        _transazioniFiltrate.add(t);
        fTot += t.totale;
        if (t.metodoPagamento == 'CARTA') fCart += t.totale;
        else fCont += t.totale;

        fNum += 1;
        t.prodotti.forEach((key, val) {
          String uKey = key.toUpperCase();
          fProd[uKey] = (fProd[uKey] ?? 0) + val;
        });
      }
    }

    _transazioniFiltrate.sort((a, b) => b.dataOra.compareTo(a.dataOra));

    setState(() {
      _incassoMostrato = fTot;
      _contantiMostrati = fCont;
      _cartaMostrati = fCart;
      _scontriniMostrati = fNum;
      _prodottiMostrati = fProd;
    });
  }

  void _applicaFiltroRapido(int tipo) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (tipo == 0) { // Oggi
      start = DateTime(now.year, now.month, now.day);
    } else if (tipo == 1) { // Ieri
      start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
      end = start.add(const Duration(hours: 23, minutes: 59, seconds: 59));
    } else if (tipo == 2) { // 7 Giorni
      start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    } else if (tipo == 3) { // Questo Mese
      start = DateTime(now.year, now.month, 1);
    } else {
      return;
    }

    setState(() {
      _dataInizio = start;
      _dataFine = end;
    });
    _ricalcolaTotali();
  }

  Future<void> _selezionaDataOra(bool isStart) async {
    final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (d == null) return;

    if (!mounted) return;
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 0, minute: 0));
    if (t == null) return;

    final selected = DateTime(d.year, d.month, d.day, t.hour, t.minute);

    setState(() {
      if (isStart) _dataInizio = selected;
      else _dataFine = selected;
    });
    _ricalcolaTotali();
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '--/--/---- --:--';
    return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }

  void _mostraDettagliSingoloScontrino(Transazione t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Scontrino delle ${_formatDateTime(t.dataOra)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Totale Pagato: ${t.totale.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
            Text('Metodo: ${t.metodoPagamento}', style: const TextStyle(fontSize: 14)),
            const Divider(thickness: 2),
            ...t.prodotti.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text('${e.value}x ${e.key.toUpperCase()}', style: const TextStyle(fontSize: 16)),
            )).toList(),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Chiudi', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Future<List<int>> _generaByteReport() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    bytes.addAll(List<int>.from(generator.reset()));
    bytes.addAll([27, 97, 1]);

    try {
      final ByteData data = await rootBundle.load('assets/images/logo_scontrino.png');
      final Uint8List imgBytes = data.buffer.asUint8List();
      final decodedImage = img.decodeImage(imgBytes);
      if (decodedImage != null) {
        var resized = img.copyResize(decodedImage, width: 512);
        var mono = img.grayscale(resized);
        bytes.addAll(List<int>.from(generator.imageRaster(mono, align: PosAlign.center)));
        bytes.addAll(List<int>.from(generator.feed(1)));
      }
    } catch (e) {
      debugPrint("Errore logo: $e");
    }

    String nomeEventoStampa = widget.evento.nomeEvento.toUpperCase();
    if (nomeEventoStampa.length > 42) nomeEventoStampa = nomeEventoStampa.substring(0, 42);

    if (nomeEventoStampa.length > 21) {
      bytes.addAll(List<int>.from(generator.text(nomeEventoStampa, styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size1))));
    } else {
      bytes.addAll(List<int>.from(generator.text(nomeEventoStampa, styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2))));
    }

    bytes.addAll(List<int>.from(generator.feed(1)));

    String titolo = _filtroAttivo ? 'REPORT PARZIALE (FILTRATO)' : 'COPIA SCONTRINO CHIUSURA';
    bytes.addAll(List<int>.from(generator.text(titolo, styles: const PosStyles(align: PosAlign.center, bold: true))));

    if (_filtroAttivo) {
      bytes.addAll(List<int>.from(generator.text('Da: ${_formatDateTime(_dataInizio)}', styles: const PosStyles(align: PosAlign.center))));
      bytes.addAll(List<int>.from(generator.text('A: ${_formatDateTime(_dataFine)}', styles: const PosStyles(align: PosAlign.center))));
    } else {
      bytes.addAll(List<int>.from(generator.text(widget.evento.dataChiusura, styles: const PosStyles(align: PosAlign.center))));
    }

    bytes.addAll(List<int>.from(generator.feed(1)));
    bytes.addAll(List<int>.from(generator.text('==========================================', styles: const PosStyles(align: PosAlign.center))));

    bytes.addAll(List<int>.from(generator.text('QT   PRODOTTO                       TOTALE', styles: const PosStyles(fontType: PosFontType.fontA, bold: true))));
    bytes.addAll(List<int>.from(generator.text('==========================================', styles: const PosStyles(align: PosAlign.center))));

    int count = 0;
    int totale = _prodottiMostrati.length;

    _prodottiMostrati.forEach((nomeUpper, quantita) {
      bool isLast = (count == totale - 1);
      count++;

      String qtColonna = '${quantita.toString().padLeft(4)} ';
      String prezzoStr = '';

      int maxSpazioNome = 42 - qtColonna.length - prezzoStr.length - 1;
      String nUpp = nomeUpper;
      if (nUpp.length > maxSpazioNome) {
        nUpp = nUpp.substring(0, maxSpazioNome);
      }

      int spaziVuoti = 42 - qtColonna.length - nUpp.length - prezzoStr.length;
      if (spaziVuoti < 1) spaziVuoti = 1;

      String riga = qtColonna + nUpp + (' ' * spaziVuoti) + prezzoStr;

      bytes.addAll(List<int>.from(generator.text(riga, styles: const PosStyles(fontType: PosFontType.fontA))));

      if (!isLast) {
        bytes.addAll(List<int>.from(generator.text('------------------------------------------', styles: const PosStyles(align: PosAlign.center))));
      }
    });

    bytes.addAll(List<int>.from(generator.text('==========================================', styles: const PosStyles(align: PosAlign.center))));

    String etichettaEmessi = 'SCONTRINI EMESSI:';
    String valoreEmessi = '$_scontriniMostrati';
    int spaziEmessi = 42 - etichettaEmessi.length - valoreEmessi.length;
    String rigaEmessi = etichettaEmessi + (' ' * spaziEmessi) + valoreEmessi;
    bytes.addAll(List<int>.from(generator.text(rigaEmessi, styles: const PosStyles(fontType: PosFontType.fontA))));

    bytes.addAll(List<int>.from(generator.text('==========================================', styles: const PosStyles(align: PosAlign.center))));
    bytes.addAll(List<int>.from(generator.feed(1)));

    bytes.addAll(List<int>.from(generator.text('TOTALE INCASSO', styles: const PosStyles(align: PosAlign.center, bold: true))));
    bytes.addAll(List<int>.from(generator.text('${_incassoMostrato.toStringAsFixed(2)} EUR', styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2))));

    bytes.addAll(List<int>.from(generator.feed(1)));
    bytes.addAll(List<int>.from(generator.text('di cui Contanti: ${_contantiMostrati.toStringAsFixed(2)} EUR', styles: const PosStyles(align: PosAlign.center))));
    bytes.addAll(List<int>.from(generator.text('di cui Carta: ${_cartaMostrati.toStringAsFixed(2)} EUR', styles: const PosStyles(align: PosAlign.center))));

    bytes.addAll(List<int>.from(generator.feed(2)));
    bytes.addAll(List<int>.from(generator.text('- REPORT COMPLETO -', styles: const PosStyles(align: PosAlign.center))));
    bytes.addAll(List<int>.from(generator.feed(2)));
    bytes.addAll(List<int>.from(generator.cut()));

    return bytes;
  }

  void _stampaReportParziale() async {
    if (stampanteGlobale == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nessuna stampante configurata. Vai in Cassa per collegarla.'), backgroundColor: Colors.red));
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
      final bytes = await _generaByteReport();
      printerManager.send(type: connessioneGlobale, bytes: bytes);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stampa inviata con successo!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore di stampa: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Dettagli: ${widget.evento.nomeEvento}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.grey.shade100,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // BARRA FILTRI RAPIDI
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ActionChip(label: const Text('Oggi', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.indigo.shade50, onPressed: () => _applicaFiltroRapido(0)),
                  const SizedBox(width: 8),
                  ActionChip(label: const Text('Ieri', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.indigo.shade50, onPressed: () => _applicaFiltroRapido(1)),
                  const SizedBox(width: 8),
                  ActionChip(label: const Text('Ultimi 7 gg', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.indigo.shade50, onPressed: () => _applicaFiltroRapido(2)),
                  const SizedBox(width: 8),
                  ActionChip(label: const Text('Questo Mese', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.indigo.shade50, onPressed: () => _applicaFiltroRapido(3)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // BARRA FILTRI MANUALI
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: isMobile
                    ? Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.filter_alt, color: Colors.indigo),
                        const SizedBox(width: 8),
                        const Text('Filtro Manuale', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                        const Spacer(),
                        if (_filtroAttivo)
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.red),
                            onPressed: () {
                              setState(() { _dataInizio = null; _dataFine = null; });
                              _ricalcolaTotali();
                            },
                          )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _selezionaDataOra(true),
                            child: Text('Da: ${_dataInizio != null ? _formatDateTime(_dataInizio) : "Inizio"}', style: const TextStyle(fontSize: 11)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _selezionaDataOra(false),
                            child: Text('A: ${_dataFine != null ? _formatDateTime(_dataFine) : "Fine"}', style: const TextStyle(fontSize: 11)),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
                    : Row(
                  children: [
                    const Icon(Icons.filter_alt, color: Colors.indigo),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _selezionaDataOra(true),
                        child: Text('Da: ${_dataInizio != null ? _formatDateTime(_dataInizio) : "Inizio"}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _selezionaDataOra(false),
                        child: Text('A: ${_dataFine != null ? _formatDateTime(_dataFine) : "Fine"}'),
                      ),
                    ),
                    if (_filtroAttivo)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        onPressed: () {
                          setState(() { _dataInizio = null; _dataFine = null; });
                          _ricalcolaTotali();
                        },
                      )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // TOTALI
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.indigo.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Incasso', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text('${_incassoMostrato.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo)),
                          ),
                          const Divider(),
                          Text('Contanti: ${_contantiMostrati.toStringAsFixed(2)} €', style: TextStyle(fontSize: 12, color: Colors.indigo.shade800)),
                          Text('Carta: ${_cartaMostrati.toStringAsFixed(2)} €', style: TextStyle(fontSize: 12, color: Colors.indigo.shade800)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    color: Colors.orange.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Scontrini', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                          Text('$_scontriniMostrati', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orange)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // SELETTORE VISTA (Riassunto o Singoli)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_mostraElencoScontrini ? Colors.indigo : Colors.white,
                      foregroundColor: !_mostraElencoScontrini ? Colors.white : Colors.indigo,
                    ),
                    onPressed: () => setState(() => _mostraElencoScontrini = false),
                    child: const Text('Riassunto Prodotti'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _mostraElencoScontrini ? Colors.indigo : Colors.white,
                      foregroundColor: _mostraElencoScontrini ? Colors.white : Colors.indigo,
                    ),
                    onPressed: () => setState(() => _mostraElencoScontrini = true),
                    child: const Text('Elenco Scontrini'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // LISTA (Dipende dal selettore)
            Expanded(
              child: !_mostraElencoScontrini
                  ? (_prodottiMostrati.isEmpty
                  ? const Center(child: Text('Nessun prodotto venduto.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                itemCount: _prodottiMostrati.length,
                itemBuilder: (ctx, i) {
                  String nomeUpper = _prodottiMostrati.keys.elementAt(i);
                  int qta = _prodottiMostrati[nomeUpper]!;
                  return Card(
                    child: ListTile(
                      title: Text(nomeUpper, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text('Qt: $qta', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    ),
                  );
                },
              ))
                  : (_transazioniFiltrate.isEmpty
                  ? const Center(child: Text('Nessuno scontrino salvato.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                itemCount: _transazioniFiltrate.length,
                itemBuilder: (ctx, i) {
                  final t = _transazioniFiltrate[i];
                  return Card(
                    child: ListTile(
                      leading: Icon(t.metodoPagamento == 'CARTA' ? Icons.credit_card : Icons.payments, color: Colors.indigo),
                      title: Text('Scontrino delle ${_formatDateTime(t.dataOra)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${t.metodoPagamento} - Totale: ${t.totale.toStringAsFixed(2)} €'),
                      trailing: const Icon(Icons.search),
                      onTap: () => _mostraDettagliSingoloScontrino(t),
                    ),
                  );
                },
              )),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: _stampaReportParziale,
                icon: const Icon(Icons.print),
                label: Text(_filtroAttivo ? 'Stampa Report Filtrato' : 'Stampa Copia Chiusura', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SCHERMATA REPORT GLOBALE MULTI-EVENTO
// -----------------------------------------------------------------------------

class GlobalReportScreen extends StatefulWidget {
  final List<EventoArchiviato> tuttiGliEventi;
  final Map<String, double> listinoPrezziAttuale;

  const GlobalReportScreen({
    super.key,
    required this.tuttiGliEventi,
    required this.listinoPrezziAttuale,
  });

  @override
  State<GlobalReportScreen> createState() => _GlobalReportScreenState();
}

class _GlobalReportScreenState extends State<GlobalReportScreen> {
  DateTime? _dataInizio;
  DateTime? _dataFine;

  double _incassoMostrato = 0.0;
  double _contantiMostrati = 0.0;
  double _cartaMostrati = 0.0;
  int _scontriniMostrati = 0;
  Map<String, int> _prodottiMostrati = {};

  bool get _filtroAttivo => _dataInizio != null || _dataFine != null;
  var printerManager = PrinterManager.instance;

  @override
  void initState() {
    super.initState();
    _ricalcolaTotaliGlobali();
  }

  void _ricalcolaTotaliGlobali() {
    double fTot = 0, fCont = 0, fCart = 0;
    int fNum = 0;
    Map<String, int> fProd = {};

    // SISTEMA ANTI-DOPPIONI GLOBALE: Usa una mappa per filtrare transazioni identiche
    Map<String, Transazione> transazioniUniche = {};

    // Fallback per vecchissimi eventi (quelli senza transazioni orarie dettagliate)
    double vecchioIncassoFallback = 0;
    double vecchioContantiFallback = 0;
    double vecchioCartaFallback = 0;
    int vecchioScontriniFallback = 0;
    Map<String, int> vecchiProdottiFallback = {};

    for (var evento in widget.tuttiGliEventi) {
      if (evento.transazioni.isNotEmpty) {
        for (var t in evento.transazioni) {
          // L'ISO string (millisecondo esatto) previene che i backup in corso si contino due volte!
          transazioniUniche[t.dataOra.toIso8601String()] = t;
        }
      } else {
        vecchioIncassoFallback += evento.incassoTotale;
        vecchioContantiFallback += evento.incassoContanti;
        vecchioCartaFallback += evento.incassoCarta;
        vecchioScontriniFallback += evento.numeroScontriniEmessi;
        evento.prodottiVenduti.forEach((key, val) {
          String uKey = key.toUpperCase();
          vecchiProdottiFallback[uKey] = (vecchiProdottiFallback[uKey] ?? 0) + val;
        });
      }
    }

    // ORA FILTRA E CALCOLA SOLO SULLE TRANSAZIONI UNICHE
    for (var t in transazioniUniche.values) {
      bool incluso = true;
      if (_dataInizio != null && t.dataOra.isBefore(_dataInizio!)) incluso = false;
      if (_dataFine != null && t.dataOra.isAfter(_dataFine!)) incluso = false;

      if (incluso) {
        fTot += t.totale;
        if (t.metodoPagamento == 'CARTA') fCart += t.totale;
        else fCont += t.totale;

        fNum += 1;
        t.prodotti.forEach((key, val) {
          String uKey = key.toUpperCase();
          fProd[uKey] = (fProd[uKey] ?? 0) + val;
        });
      }
    }

    // Aggiungi il fallback se non ci sono filtri data attivi
    if (!_filtroAttivo) {
      fTot += vecchioIncassoFallback;
      fCont += vecchioContantiFallback;
      fCart += vecchioCartaFallback;
      fNum += vecchioScontriniFallback;
      vecchiProdottiFallback.forEach((k, v) {
        fProd[k] = (fProd[k] ?? 0) + v;
      });
    }

    setState(() {
      _incassoMostrato = fTot;
      _contantiMostrati = fCont;
      _cartaMostrati = fCart;
      _scontriniMostrati = fNum;
      _prodottiMostrati = fProd;
    });
  }

  void _applicaFiltroRapido(int tipo) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (tipo == 0) { // Oggi
      start = DateTime(now.year, now.month, now.day);
    } else if (tipo == 1) { // Ieri
      start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
      end = start.add(const Duration(hours: 23, minutes: 59, seconds: 59));
    } else if (tipo == 2) { // 7 Giorni
      start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    } else if (tipo == 3) { // Questo Mese
      start = DateTime(now.year, now.month, 1);
    } else {
      return;
    }

    setState(() {
      _dataInizio = start;
      _dataFine = end;
    });
    _ricalcolaTotaliGlobali();
  }

  Future<void> _selezionaDataOra(bool isStart) async {
    final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (d == null) return;

    if (!mounted) return;
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 0, minute: 0));
    if (t == null) return;

    final selected = DateTime(d.year, d.month, d.day, t.hour, t.minute);

    setState(() {
      if (isStart) _dataInizio = selected;
      else _dataFine = selected;
    });
    _ricalcolaTotaliGlobali();
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '--/--/---- --:--';
    return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }

  Future<List<int>> _generaByteReportGlobale() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    bytes.addAll(List<int>.from(generator.reset()));
    bytes.addAll([27, 97, 1]);

    try {
      final ByteData data = await rootBundle.load('assets/images/logo_scontrino.png');
      final Uint8List imgBytes = data.buffer.asUint8List();
      final decodedImage = img.decodeImage(imgBytes);
      if (decodedImage != null) {
        var resized = img.copyResize(decodedImage, width: 512);
        var mono = img.grayscale(resized);
        bytes.addAll(List<int>.from(generator.imageRaster(mono, align: PosAlign.center)));
        bytes.addAll(List<int>.from(generator.feed(1)));
      }
    } catch (e) {
      debugPrint("Errore logo: $e");
    }

    bytes.addAll(List<int>.from(generator.text('REPORT GLOBALE', styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2))));
    bytes.addAll(List<int>.from(generator.feed(1)));
    bytes.addAll(List<int>.from(generator.text('MULTI-EVENTO', styles: const PosStyles(align: PosAlign.center, bold: true))));

    if (_filtroAttivo) {
      bytes.addAll(List<int>.from(generator.text('Da: ${_formatDateTime(_dataInizio)}', styles: const PosStyles(align: PosAlign.center))));
      bytes.addAll(List<int>.from(generator.text('A: ${_formatDateTime(_dataFine)}', styles: const PosStyles(align: PosAlign.center))));
    } else {
      bytes.addAll(List<int>.from(generator.text('Tutti gli eventi storici e live', styles: const PosStyles(align: PosAlign.center))));
    }

    bytes.addAll(List<int>.from(generator.feed(1)));
    bytes.addAll(List<int>.from(generator.text('==========================================', styles: const PosStyles(align: PosAlign.center))));

    bytes.addAll(List<int>.from(generator.text('QT   PRODOTTO                       TOTALE', styles: const PosStyles(fontType: PosFontType.fontA, bold: true))));
    bytes.addAll(List<int>.from(generator.text('==========================================', styles: const PosStyles(align: PosAlign.center))));

    int count = 0;
    int totale = _prodottiMostrati.length;

    _prodottiMostrati.forEach((nomeUpper, quantita) {
      bool isLast = (count == totale - 1);
      count++;

      String qtColonna = '${quantita.toString().padLeft(4)} ';
      String prezzoStr = '';

      int maxSpazioNome = 42 - qtColonna.length - prezzoStr.length - 1;

      String nUpp = nomeUpper;
      if (nUpp.length > maxSpazioNome) {
        nUpp = nUpp.substring(0, maxSpazioNome);
      }

      int spaziVuoti = 42 - qtColonna.length - nUpp.length - prezzoStr.length;
      if (spaziVuoti < 1) spaziVuoti = 1;

      String riga = qtColonna + nUpp + (' ' * spaziVuoti) + prezzoStr;

      bytes.addAll(List<int>.from(generator.text(riga, styles: const PosStyles(fontType: PosFontType.fontA))));

      if (!isLast) {
        bytes.addAll(List<int>.from(generator.text('------------------------------------------', styles: const PosStyles(align: PosAlign.center))));
      }
    });

    bytes.addAll(List<int>.from(generator.text('==========================================', styles: const PosStyles(align: PosAlign.center))));

    String etichettaEmessi = 'SCONTRINI EMESSI:';
    String valoreEmessi = '$_scontriniMostrati';
    int spaziEmessi = 42 - etichettaEmessi.length - valoreEmessi.length;
    String rigaEmessi = etichettaEmessi + (' ' * spaziEmessi) + valoreEmessi;
    bytes.addAll(List<int>.from(generator.text(rigaEmessi, styles: const PosStyles(fontType: PosFontType.fontA))));

    bytes.addAll(List<int>.from(generator.text('==========================================', styles: const PosStyles(align: PosAlign.center))));
    bytes.addAll(List<int>.from(generator.feed(1)));

    bytes.addAll(List<int>.from(generator.text('TOTALE GLOBALE', styles: const PosStyles(align: PosAlign.center, bold: true))));
    bytes.addAll(List<int>.from(generator.text('${_incassoMostrato.toStringAsFixed(2)} EUR', styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2))));

    bytes.addAll(List<int>.from(generator.feed(1)));
    bytes.addAll(List<int>.from(generator.text('di cui Contanti: ${_contantiMostrati.toStringAsFixed(2)} EUR', styles: const PosStyles(align: PosAlign.center))));
    bytes.addAll(List<int>.from(generator.text('di cui Carta: ${_cartaMostrati.toStringAsFixed(2)} EUR', styles: const PosStyles(align: PosAlign.center))));

    bytes.addAll(List<int>.from(generator.feed(2)));
    bytes.addAll(List<int>.from(generator.text('- FINE REPORT GLOBALE -', styles: const PosStyles(align: PosAlign.center))));
    bytes.addAll(List<int>.from(generator.feed(2)));
    bytes.addAll(List<int>.from(generator.cut()));

    return bytes;
  }

  void _stampaReportGlobaleFisico() async {
    if (stampanteGlobale == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nessuna stampante configurata. Vai in Cassa per collegarla.'), backgroundColor: Colors.red));
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
      final bytes = await _generaByteReportGlobale();
      printerManager.send(type: connessioneGlobale, bytes: bytes);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report Globale stampato con successo!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore di stampa: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Report Globale Multi-Evento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.grey.shade100,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ActionChip(label: const Text('Oggi', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.indigo.shade50, onPressed: () => _applicaFiltroRapido(0)),
                  const SizedBox(width: 8),
                  ActionChip(label: const Text('Ieri', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.indigo.shade50, onPressed: () => _applicaFiltroRapido(1)),
                  const SizedBox(width: 8),
                  ActionChip(label: const Text('Ultimi 7 gg', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.indigo.shade50, onPressed: () => _applicaFiltroRapido(2)),
                  const SizedBox(width: 8),
                  ActionChip(label: const Text('Questo Mese', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.indigo.shade50, onPressed: () => _applicaFiltroRapido(3)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: isMobile
                    ? Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.date_range, color: Colors.indigo),
                        const SizedBox(width: 8),
                        const Text('Filtro Manuale', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                        const Spacer(),
                        if (_filtroAttivo)
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.red),
                            onPressed: () {
                              setState(() { _dataInizio = null; _dataFine = null; });
                              _ricalcolaTotaliGlobali();
                            },
                          )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _selezionaDataOra(true),
                            child: Text('Da: ${_dataInizio != null ? _formatDateTime(_dataInizio) : "Inizio"}', style: const TextStyle(fontSize: 11)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _selezionaDataOra(false),
                            child: Text('A: ${_dataFine != null ? _formatDateTime(_dataFine) : "Fine"}', style: const TextStyle(fontSize: 11)),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
                    : Row(
                  children: [
                    const Icon(Icons.date_range, color: Colors.indigo),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _selezionaDataOra(true),
                        child: Text('Da: ${_dataInizio != null ? _formatDateTime(_dataInizio) : "Inizio"}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _selezionaDataOra(false),
                        child: Text('A: ${_dataFine != null ? _formatDateTime(_dataFine) : "Fine"}'),
                      ),
                    ),
                    if (_filtroAttivo)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        onPressed: () {
                          setState(() { _dataInizio = null; _dataFine = null; });
                          _ricalcolaTotaliGlobali();
                        },
                      )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.indigo.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Incasso Totale', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text('${_incassoMostrato.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo)),
                          ),
                          const Divider(),
                          Text('Contanti: ${_contantiMostrati.toStringAsFixed(2)} €', style: TextStyle(fontSize: 12, color: Colors.indigo.shade800)),
                          Text('Carta: ${_cartaMostrati.toStringAsFixed(2)} €', style: TextStyle(fontSize: 12, color: Colors.indigo.shade800)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    color: Colors.orange.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Scontrini Totali', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                          Text('$_scontriniMostrati', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orange)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Prodotti Totali Venduti', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _prodottiMostrati.isEmpty
                  ? const Center(child: Text('Nessun dato per questo intervallo di date.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                itemCount: _prodottiMostrati.length,
                itemBuilder: (ctx, i) {
                  String nomeUpper = _prodottiMostrati.keys.elementAt(i);
                  int qta = _prodottiMostrati[nomeUpper]!;
                  return Card(
                    child: ListTile(
                      title: Text(nomeUpper, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text('Qt: $qta', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: _stampaReportGlobaleFisico,
                icon: const Icon(Icons.print),
                label: const Text('Stampa Report Globale', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}