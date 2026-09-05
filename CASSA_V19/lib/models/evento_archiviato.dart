class EventoArchiviato {
  final String id;
  final String dataChiusura;
  final double incassoTotale;
  final int numeroScontriniEmessi;
  final Map<String, int> prodottiVenduti; // Nome prodotto -> Quantità
  final Map<String, double> prezziProdotti; // Nome prodotto -> Prezzo unitario

  EventoArchiviato({
    required this.id,
    required this.dataChiusura,
    required this.incassoTotale,
    required this.numeroScontriniEmessi,
    required this.prodottiVenduti,
    required this.prezziProdotti,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'dataChiusura': dataChiusura,
    'incassoTotale': incassoTotale,
    'numeroScontriniEmessi': numeroScontriniEmessi,
    'prodottiVenduti': prodottiVenduti,
    'prezziProdotti': prezziProdotti,
  };

  factory EventoArchiviato.fromJson(Map<String, dynamic> json) {
    return EventoArchiviato(
      id: json['id'] ?? '',
      dataChiusura: json['dataChiusura'] ?? '',
      incassoTotale: (json['incassoTotale'] as num).toDouble(),
      numeroScontriniEmessi: json['numeroScontriniEmessi'] ?? 0,
      prodottiVenduti: Map<String, int>.from(json['prodottiVenduti'] ?? {}),
      prezziProdotti: Map<String, double>.from(
        (json['prezziProdotti'] ?? {}).map((k, v) => MapEntry(k, (v as num).toDouble())),
      ),
    );
  }
}