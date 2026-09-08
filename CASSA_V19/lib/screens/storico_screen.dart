import 'package:flutter/material.dart';
import '../models/evento_archiviato.dart';

class StoricoScreen extends StatefulWidget {
  final List<EventoArchiviato> eventiPassati;
  final VoidCallback onAggiorna;
  final Function(String idEvento) onEliminaEvento;

  const StoricoScreen({
    super.key,
    required this.eventiPassati,
    required this.onAggiorna,
    required this.onEliminaEvento,
  });

  @override
  State<StoricoScreen> createState() => _StoricoScreenState();
}

class _StoricoScreenState extends State<StoricoScreen> {
  String? _idEventoSelezionato;

  void _mostraDettagliEvento(EventoArchiviato evento) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chiusura - ${evento.nomeEvento}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Data Chiusura: ${evento.dataChiusura}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              Text('Incasso Totale: ${evento.incassoTotale.toStringAsFixed(2)} €', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Scontrini Emessi: ${evento.numeroScontriniEmessi}', style: const TextStyle(fontSize: 14)),
              const Divider(thickness: 2),
              const Text('Prodotti Venduti:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView(
                  children: evento.prodottiVenduti.entries.map((entry) {
                    return ListTile(
                      dense: true,
                      title: Text(entry.key),
                      trailing: Text('Qt: ${entry.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    EventoArchiviato? eventoSelezionato;
    if (_idEventoSelezionato != null) {
      try {
        eventoSelezionato = widget.eventiPassati.firstWhere((e) => e.id == _idEventoSelezionato);
      } catch (_) {
        eventoSelezionato = null;
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Storico Eventi Passati', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.grey.shade100,
        surfaceTintColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: widget.eventiPassati.isEmpty
                  ? const Center(child: Text('Nessun evento archiviato nello storico.', style: TextStyle(fontSize: 16, color: Colors.grey)))
                  : ListView.builder(
                itemCount: widget.eventiPassati.length,
                itemBuilder: (context, index) {
                  final evento = widget.eventiPassati[index];
                  final isSelezionato = evento.id == _idEventoSelezionato;

                  return Card(
                    color: isSelezionato ? Colors.indigo.shade50 : Colors.white,
                    elevation: isSelezionato ? 3 : 1,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: isSelezionato ? Colors.indigo : Colors.transparent, width: 2),
                    ),
                    child: ListTile(
                      onTap: () {
                        setState(() {
                          _idEventoSelezionato = evento.id;
                        });
                      },
                      title: Text(evento.nomeEvento.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
                      subtitle: Text('Chiuso il: ${evento.dataChiusura}\nScontrini: ${evento.numeroScontriniEmessi} | Incasso: ${evento.incassoTotale.toStringAsFixed(2)} €'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: eventoSelezionato != null ? Colors.teal.shade600 : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: eventoSelezionato != null ? () => _mostraDettagliEvento(eventoSelezionato!) : null,
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Visualizza Scontrino', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: eventoSelezionato != null ? Colors.red.shade700 : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: eventoSelezionato != null ? () {
                      widget.onEliminaEvento(eventoSelezionato!.id);
                      setState(() {
                        _idEventoSelezionato = null;
                      });
                    } : null,
                    icon: const Icon(Icons.delete),
                    label: const Text('Elimina Evento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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