class Prodotto {
  final String id;
  final String nome;
  final double prezzo;
  final String tipologia;

  Prodotto({
    required this.id,
    required this.nome,
    required this.prezzo,
    required this.tipologia,
  });

  // Converte il prodotto in JSON per il salvataggio
  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'prezzo': prezzo,
    'tipologia': tipologia,
  };

  // Crea un Prodotto leggendo i dati salvati
  factory Prodotto.fromJson(Map<String, dynamic> json) {
    return Prodotto(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      prezzo: (json['prezzo'] as num).toDouble(),
      tipologia: json['tipologia'] ?? 'bevanda',
    );
  }
}