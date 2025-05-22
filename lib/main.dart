import 'package:flutter/material.dart';
import 'arayuz.dart'; // Arayüz sayfasını import ediyoruz

void main() {
  runApp(const SoruBotuApp());
}

class SoruBotuApp extends StatelessWidget {
  const SoruBotuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soru Botu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.indigo[900],
      ),
      home: const Arayuz(),
    );
  }
}
