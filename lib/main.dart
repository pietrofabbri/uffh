import 'package:flutter/material.dart';

import 'models/progress.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(AllenamentoApp(progress: ProgressController()));
}

class AllenamentoApp extends StatelessWidget {
  final ProgressController progress;

  const AllenamentoApp({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Allenamento',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: HomeScreen(progress: progress),
    );
  }
}
