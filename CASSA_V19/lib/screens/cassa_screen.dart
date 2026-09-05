import 'package:flutter/material.dart';
import '../models/prodotto.dart';

class CassaScreen extends StatefulWidget {
  final List<Prodotto> prodotti;

  const CassaScreen({super.key, required this.prodotti});

  @override
  State<CassaScreen> createState() => _CassaScreenState();
}

class _CassaScreenState extends State<CassaScreen> {
  final Map<Prodotto, int> _carrello = {};

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
      _carrello.remove(p);
    });
  }

  void _svuotaCarrello() {
    setState(() {
      _carrello.clear();
    });
  }

  double get _totaleIncasso {
    double totale = 0;
    _carrello.forEach((prodotto, quantita) {
      totale += (prodotto.prezzo * quantita);
    });
    return totale;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Cassa - Modalità Vendita', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.grey.shade100,
        surfaceTintColor: Colors.transparent,
      ),
      body: Row(
        children: [
          // SINISTRA: Griglia Prodotti (aggiornata in tempo reale dal listino)
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.6,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: widget.prodotti.length,
                itemBuilder: (context, index) {
                  final p = widget.prodotti[index];
                  final isCibo = p.tipologia == 'cibo';
                  final colorePulsante = isCibo ? Colors.orange.shade700 : Colors.blue.shade600;

                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorePulsante,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _aggiungiAlCarrello(p),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(p.nome, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('${p.prezzo.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 18)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // DESTRA: Carrello e Comandi
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
                            title: Text(
                              '${quantita}x ${prodotto.nome} - ${prezzoTotale.toStringAsFixed(2)} €',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.deepOrange),
                              onPressed: () => _rimuoviDalCarrello(prodotto),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const Divider(thickness: 2),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'Totale: ${_totaleIncasso.toStringAsFixed(2)} €',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                    ),
                  ),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                      onPressed: () {},
                      child: const Text('Modifica Listino', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
                      onPressed: _svuotaCarrello,
                      child: const Text('Svuota Tutto', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                      onPressed: () {},
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