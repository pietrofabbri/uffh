import 'package:flutter/material.dart';

import 'models/goals.dart';
import 'models/progress.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    AllenamentoApp(
      progress: ProgressController(),
      goals: GoalsController(),
    ),
  );
}

class AllenamentoApp extends StatelessWidget {
  final ProgressController progress;
  final GoalsController goals;

  const AllenamentoApp({super.key, required this.progress, required this.goals});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Allenamento',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: HomeScreen(progress: progress, goals: goals),
    );
  }
}
