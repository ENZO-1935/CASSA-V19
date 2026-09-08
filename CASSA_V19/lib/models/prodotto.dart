import 'package:flutter/material.dart';

class Prodotto {
  final String id;
  final String nome;
  final double prezzo;
  final String tipologia;
  final String? immagineBase64; // NUOVO: Campo opzionale per la foto

  Prodotto({
    required this.id,
    required this.nome,
    required this.prezzo,
    required this.tipologia,
    this.immagineBase64,
  });

  IconData get icona {
    String n = nome.toLowerCase();

    if (tipologia == 'bevanda') {
      if (n.contains('birra')) return Icons.sports_bar;
      if (n.contains('vino') || n.contains('prosecco')) return Icons.wine_bar;
      if (n.contains('cocktail') || n.contains('campari') || n.contains('spritz') || n.contains('cicchetto')) return Icons.local_bar;
      if (n.contains('caff')) return Icons.coffee;
      if (n.contains('acqua')) return Icons.water_drop;
      return Icons.local_drink;
    } else {
      if (n.contains('pizza') || n.contains('focaccia')) return Icons.local_pizza;
      if (n.contains('panin')) return Icons.lunch_dining;
      if (n.contains('salsiccia') || n.contains('wrustel') || n.contains('wurstel')) return Icons.kebab_dining;
      if (n.contains('pasta')) return Icons.dinner_dining;
      if (n.contains('zeppol') || n.contains('dolc')) return Icons.cake;
      if (n.contains('patatin')) return Icons.fastfood;
      return Icons.restaurant;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'prezzo': prezzo,
    'tipologia': tipologia,
    'immagineBase64': immagineBase64, // Salva la foto
  };

  factory Prodotto.fromJson(Map<String, dynamic> json) {
    return Prodotto(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      prezzo: (json['prezzo'] as num).toDouble(),
      tipologia: json['tipologia'] ?? 'bevanda',
      immagineBase64: json['immagineBase64'], // Legge la foto
    );
  }
}