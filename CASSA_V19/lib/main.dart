import 'package:flutter/material.dart';
import 'screens/menu_screen.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const MenuScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}