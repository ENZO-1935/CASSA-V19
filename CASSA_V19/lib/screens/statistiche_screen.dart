import 'package:flutter/material.dart';

class StatisticheScreen extends StatelessWidget {
  final String nomeEvento;
  final double incassoTotale;
  final int numeroScontrini;
  final Map<String, int> prodottiVenduti;
  final VoidCallback onAggiorna;
  final VoidCallback onStampaChiusura;
  // Modificato per accettare un valore booleano (vero/falso) sulla scelta del listino
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

  void _mostraScontrinoChiusura(BuildContext context) {
    if (nomeEvento.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nessun evento attivo per stampare la chiusura.')));
      return;
    }

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey.shade200,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text('🖨️ STAMPA SCONTRINO DI CHIUSURA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          content: SizedBox(
              width: 320,
              child: SingleChildScrollView(
                  child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black87, width: 2)),
                      child: Column(
                          children: [
                            Image.asset('assets/images/logo.png', height: 40),
                            const SizedBox(height: 6),
                            Text(nomeEvento.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace'), textAlign: TextAlign.center),
                            const Text('SCONTRINO DI CHIUSURA', style: TextStyle(fontSize: 14, fontFamily: 'monospace')),
                            Text(DateTime.now().toString().substring(0, 16), style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey)),
                            const Divider(color: Colors.black87, thickness: 1.5),
                            const SizedBox(height: 10),

                            ...prodottiVenduti.entries.map((e) => Padding(
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
                                Text('${incassoTotale.toStringAsFixed(2)} €', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('SCONTRINI EMESSI:', style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
                                Text('$numeroScontrini', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text('- EVENTO CONCLUSO -', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.grey)),
                          ]
                      )
                  )
              )
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(context);
                onStampaChiusura();
              },
              child: const Text('Simula Stampa Chiusura'),
            ),
          ],
        )
    );
  }

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
                    onPressed: () => _mostraScontrinoChiusura(context),
                    icon: const Icon(Icons.print),
                    label: const Text('Stampa Chiusura', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                    onPressed: () {
                      if (nomeEvento.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Non c\'è nessun evento attivo da archiviare.')));
                        return;
                      }

                      bool azzeraListino = false; // Variabile per la spunta

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
                                        onArchiviaEazzera(azzeraListino); // Passiamo la scelta!
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