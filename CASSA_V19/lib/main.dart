import 'package:flutter/material.dart';
import 'screens/cassa_screen.dart';

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
      home: const CassaScreen(),
    );
  }
}