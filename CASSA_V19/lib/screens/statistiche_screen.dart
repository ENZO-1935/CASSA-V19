import 'package:flutter/material.dart';

class StatisticheScreen extends StatelessWidget {
  final double incassoTotale;
  final int numeroScontrini;
  final Map<String, int> prodottiVenduti; // Nome prodotto -> Quantità
  final VoidCallback onAggiorna;
  final VoidCallback onStampaChiusura;
  final VoidCallback onArchiviaEazzera;

  const StatisticheScreen({
    super.key,
    required this.incassoTotale,
    required this.numeroScontrini,
    required this.prodottiVenduti,
    required this.onAggiorna,
    required this.onStampaChiusura,
    required this.onArchiviaEazzera,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Statistiche e Chiusura Evento', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.grey.shade100,
        surfaceTintColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Riepilogo Incasso e Scontrini
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.indigo.shade50,
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Incasso Totale Evento', style: TextStyle(fontSize: 16, color: Colors.indigo, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('${incassoTotale.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    color: Colors.orange.shade50,
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Scontrini Emessi', style: TextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('$numeroScontrini', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.orange)),
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

            // Tabella / Elenco Prodotti Venduti
            Expanded(
              child: prodottiVenduti.isEmpty
                  ? const Center(child: Text('Nessun prodotto venduto in questo evento.', style: TextStyle(fontSize: 16, color: Colors.grey)))
                  : ListView.builder(
                itemCount: prodottiVenduti.length,
                itemBuilder: (context, index) {
                  final nomeProdotto = prodottiVenduti.keys.elementAt(index);
                  final quantita = prodottiVenduti[nomeProdotto]!;

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

            // Pulsanti Inferiori
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                    onPressed: onAggiorna,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Aggiorna', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                    onPressed: onStampaChiusura,
                    icon: const Icon(Icons.print),
                    label: const Text('Stampa Chiusura', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                    onPressed: () {
                      // Conferma archiviazione
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Archivia e Azzera Evento'),
                          content: const Text('Vuoi archiviare l\'evento nello storico e azzerare incassi, contatore scontrini e listino?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              onPressed: () {
                                Navigator.pop(context);
                                onArchiviaEazzera();
                              },
                              child: const Text('Conferma'),
                            ),
                          ],
                        ),
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