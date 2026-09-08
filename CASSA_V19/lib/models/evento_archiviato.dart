class EventoArchiviato {
  final String id;
  final String nomeEvento; // Nuovo campo aggiunto
  final String dataChiusura;
  final double incassoTotale;
  final int numeroScontriniEmessi;
  final Map<String, int> prodottiVenduti;
  final Map<String, double> prezziProdotti;

  EventoArchiviato({
    required this.id,
    required this.nomeEvento,
    required this.dataChiusura,
    required this.incassoTotale,
    required this.numeroScontriniEmessi,
    required this.prodottiVenduti,
    required this.prezziProdotti,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nomeEvento': nomeEvento,
    'dataChiusura': dataChiusura,
    'incassoTotale': incassoTotale,
    'numeroScontriniEmessi': numeroScontriniEmessi,
    'prodottiVenduti': prodottiVenduti,
    'prezziProdotti': prezziProdotti,
  };

  factory EventoArchiviato.fromJson(Map<String, dynamic> json) {
    return EventoArchiviato(
      id: json['id'] ?? '',
      nomeEvento: json['nomeEvento'] ?? 'Evento Precedente', // Gestisce anche gli eventi vecchi
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