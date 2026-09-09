import 'prodotto.dart';

class VoceOrdine {
  final Prodotto prodotto;
  int quantita;

  VoceOrdine({required this.prodotto, this.quantita = 1});

  double get totaleParziale => prodotto.prezzo * quantita;
}

class Ordine {
  final List<VoceOrdine> voci = [];

  void aggiungiProdotto(Prodotto prodotto) {
    final index = voci.indexWhere((v) => v.prodotto.id == prodotto.id);
    if (index >= 0) {
      voci[index].quantita++;
    } else {
      voci.add(VoceOrdine(prodotto: prodotto));
    }
  }

  void rimuoviProdotto(Prodotto prodotto) {
    final index = voci.indexWhere((v) => v.prodotto.id == prodotto.id);
    if (index >= 0) {
      if (voci[index].quantita > 1) {
        voci[index].quantita--;
      } else {
        voci.removeAt(index);
      }
    }
  }

  double get totaleComplessivo {
    return voci.fold(0, (sum, voce) => sum + voce.totaleParziale);
  }

  void svuota() {
    voci.clear();
  }
}

// NUOVO: Fotografia esatta di una singola vendita per i filtri di orario
class Transazione {
  final DateTime dataOra;
  final double totale;
  final String metodoPagamento;
  final Map<String, int> prodotti;

  Transazione({
    required this.dataOra,
    required this.totale,
    required this.metodoPagamento,
    required this.prodotti,
  });

  Map<String, dynamic> toJson() => {
    'dataOra': dataOra.toIso8601String(),
    'totale': totale,
    'metodoPagamento': metodoPagamento,
    'prodotti': prodotti,
  };

  factory Transazione.fromJson(Map<String, dynamic> json) {
    return Transazione(
      dataOra: DateTime.parse(json['dataOra']),
      totale: (json['totale'] as num).toDouble(),
      metodoPagamento: json['metodoPagamento'] ?? 'CONTANTI',
      prodotti: Map<String, int>.from(json['prodotti'] ?? {}),
    );
  }
}