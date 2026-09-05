import 'package:flutter/material.dart';
import '../models/prodotto.dart';
import '../models/ordine.dart';

class CassaScreen extends StatefulWidget {
  const CassaScreen({super.key});

  @override
  State<CassaScreen> createState() => _CassaScreenState();
}

class _CassaScreenState extends State<CassaScreen> {
  final Ordine _ordine = Ordine();

  // Prodotti di esempio tipici da sagra
  final List<Prodotto> _prodottiDisponibili = [
    Prodotto(id: '1', nome: 'Birra 0.4L', prezzo: 4.50),
    Prodotto(id: '2', nome: 'Panino con Salsiccia', prezzo: 6.00),
    Prodotto(id: '3', nome: 'Patatine Fritte', prezzo: 3.50),
    Prodotto(id: '4', nome: 'Acqua 0.5L', prezzo: 1.50),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cassa Sagra - Touch Terminal'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Row(
        children: [
          // Griglia dei prodotti (lato sinistro)
          Expanded(
            flex: 2,
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _prodottiDisponibili.length,
              itemBuilder: (context, index) {
                final prodotto = _prodottiDisponibili[index];
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade100,
                    foregroundColor: Colors.black87,
                  ),
                  onPressed: () {
                    setState(() {
                      _ordine.aggiungiProdotto(prodotto);
                    });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        prodotto.nome,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '€ ${prodotto.prezzo.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Riepilogo ordine / Carrello (lato destro)
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey.shade100,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      'Carrello Corrente',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _ordine.voci.length,
                      itemBuilder: (context, index) {
                        final voce = _ordine.voci[index];
                        return ListTile(
                          title: Text(voce.prodotto.nome),
                          subtitle: Text('${voce.quantita}x € ${voce.prodotto.prezzo.toStringAsFixed(2)}'),
                          trailing: Text('€ ${voce.totaleParziale.toStringAsFixed(2)}'),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Totale:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(
                          '€ ${_ordine.totaleComplessivo.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: _ordine.voci.isEmpty
                          ? null
                          : () {
                        // Qui integreremo la stampa con la stampante Epson
                        setState(() {
                          _ordine.svuota();
                        });
                      },
                      child: const Text('STAMPA E CHIUDI', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}