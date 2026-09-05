import 'package:flutter/material.dart';
import 'screens/menu_screen.dart'; // Questa riga è FONDAMENTALE per far funzionare MenuScreen

void main() {
  runApp(const CassaApp());
}

class CassaApp extends StatelessWidget {
  const CassaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cassa Sagra',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: MenuScreen(), // Rimuovi 'const' qui se ci sono errori dopo l'importazione
    );
  }
}