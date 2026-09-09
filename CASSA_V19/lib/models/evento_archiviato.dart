import 'ordine.dart'; // Necessario per usare Transazione

class EventoArchiviato {
  String id;
  String nomeEvento;
  String dataChiusura;
  double incassoTotale;
  double incassoContanti;
  double incassoCarta;
  int numeroScontriniEmessi;
  Map<String, int> prodottiVenduti;
  Map<String, double> prezziProdotti;
  List<Transazione> transazioni; // <-- NUOVO: Salviamo tutti gli scontrini per poterli filtrare per data/ora

  EventoArchiviato({
    required this.id,
    required this.nomeEvento,
    required this.dataChiusura,
    required this.incassoTotale,
    this.incassoContanti = 0.0,
    this.incassoCarta = 0.0,
    required this.numeroScontriniEmessi,
    required this.prodottiVenduti,
    required this.prezziProdotti,
    required this.transazioni, // <-- NUOVO
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nomeEvento': nomeEvento,
    'dataChiusura': dataChiusura,
    'incassoTotale': incassoTotale,
    'incassoContanti': incassoContanti,
    'incassoCarta': incassoCarta,
    'numeroScontriniEmessi': numeroScontriniEmessi,
    'prodottiVenduti': prodottiVenduti,
    'prezziProdotti': prezziProdotti,
    'transazioni': transazioni.map((t) => t.toJson()).toList(), // Salvataggio
  };

  factory EventoArchiviato.fromJson(Map<String, dynamic> json) {
    return EventoArchiviato(
      id: json['id'] ?? '',
      nomeEvento: json['nomeEvento'] ?? 'Evento Precedente',
      dataChiusura: json['dataChiusura'] ?? '',
      incassoTotale: (json['incassoTotale'] as num).toDouble(),
      incassoContanti: (json['incassoContanti'] ?? 0.0 as num).toDouble(),
      incassoCarta: (json['incassoCarta'] ?? 0.0 as num).toDouble(),
      numeroScontriniEmessi: json['numeroScontriniEmessi'] ?? 0,
      prodottiVenduti: Map<String, int>.from(json['prodottiVenduti'] ?? {}),
      prezziProdotti: Map<String, double>.from(
        (json['prezziProdotti'] ?? {}).map((k, v) => MapEntry(k, (v as num).toDouble())),
      ),
      // Gestisce in automatico anche i vecchi archivi che non avevano transazioni
      transazioni: json['transazioni'] != null
          ? (json['transazioni'] as List).map((t) => Transazione.fromJson(t)).toList()
          : [],
    );
  }
}