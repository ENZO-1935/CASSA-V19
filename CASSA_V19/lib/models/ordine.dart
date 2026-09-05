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
    // Controlla se il prodotto è già nel carrello
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