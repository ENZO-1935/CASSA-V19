import 'package:flutter/material.dart';
import '../models/prodotto.dart';

class ListinoScreen extends StatefulWidget {
  final List<Prodotto> prodotti;
  final VoidCallback onAggiornato;

  const ListinoScreen({super.key, required this.prodotti, required this.onAggiornato});

  @override
  State<ListinoScreen> createState() => _ListinoScreenState();
}

class _ListinoScreenState extends State<ListinoScreen> {

  void _eliminaProdotto(int index) {
    setState(() {
      widget.prodotti.removeAt(index);
    });
    widget.onAggiornato();
  }

  // Finestra popup con sfumatura arancione
  void _mostraDialogProdotto({Prodotto? prodottoEsistente, int? index}) {
    final _nomeController = TextEditingController(text: prodottoEsistente?.nome ?? '');
    final _prezzoController = TextEditingController(
      text: prodottoEsistente != null ? prodottoEsistente.prezzo.toString() : '',
    );
    String _tipologiaSelezionata = prodottoEsistente?.tipologia ?? 'bevanda';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              content: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFE65100)], // Sfumatura Arancione
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prodottoEsistente == null ? 'Nuovo Prodotto' : 'Modifica Prodotto',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _nomeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Nome Prodotto',
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white70), borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white), borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _prezzoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Prezzo (€)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white70), borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white), borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _tipologiaSelezionata,
                      dropdownColor: Colors.deepOrange.shade800,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Tipologia',
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white70), borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white), borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'cibo', child: Text('Cibo (Arancione)', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'bevanda', child: Text('Bevanda (Blu)', style: TextStyle(color: Colors.white))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setStateDialog(() {
                            _tipologiaSelezionata = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annulla', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.deepOrange.shade900,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            final nome = _nomeController.text.trim();
                            final prezzo = double.tryParse(_prezzoController.text.replaceAll(',', '.')) ?? 0.0;

                            if (nome.isNotEmpty && prezzo > 0) {
                              setState(() {
                                if (prodottoEsistente == null) {
                                  widget.prodotti.add(Prodotto(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    nome: nome,
                                    prezzo: prezzo,
                                    tipologia: _tipologiaSelezionata,
                                  ));
                                } else {
                                  widget.prodotti[index!] = Prodotto(
                                    id: prodottoEsistente.id,
                                    nome: nome,
                                    prezzo: prezzo,
                                    tipologia: _tipologiaSelezionata,
                                  );
                                }
                              });
                              widget.onAggiornato();
                              Navigator.pop(context);
                            }
                          },
                          child: Text(prodottoEsistente == null ? 'Aggiungi' : 'Salva', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Gestione Listino', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.grey.shade100,
        surfaceTintColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _mostraDialogProdotto(),
                icon: const Icon(Icons.add),
                label: const Text('Nuovo Prodotto', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: widget.prodotti.length,
                itemBuilder: (context, index) {
                  final p = widget.prodotti[index];
                  final isCibo = p.tipologia == 'cibo';

                  return Card(
                    color: Colors.white,
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: isCibo ? Colors.orange.shade100 : Colors.blue.shade100,
                        child: Icon(
                          isCibo ? Icons.restaurant : Icons.local_drink,
                          color: isCibo ? Colors.orange.shade800 : Colors.blue.shade700,
                        ),
                      ),
                      title: Text(p.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: Text(p.tipologia.toUpperCase(), style: TextStyle(color: Colors.grey.shade600)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                              '${p.prezzo.toStringAsFixed(2)} €',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange)
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _mostraDialogProdotto(prodottoEsistente: p, index: index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.deepOrange),
                            onPressed: () => _eliminaProdotto(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}