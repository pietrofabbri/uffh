import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const AllenamentoApp());
}

class AllenamentoApp extends StatelessWidget {
  const AllenamentoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Allenamento',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
