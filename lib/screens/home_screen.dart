import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/exercise.dart';
import 'category_screen.dart';

/// Schermata iniziale: una categoria per riga (le "9 fondamenta" +
/// flessibilita' ed equilibrio), con il numero di esercizi disponibili.
/// Scheletro minimo per validare la pipeline di build — nessun motore
/// di generazione allenamento ancora collegato.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final byCategory = <FitnessCategory, List<Exercise>>{
      for (final category in FitnessCategory.values)
        category: seedExercises.where((e) => e.category == category).toList(),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Allenamento')),
      body: ListView(
        children: [
          for (final entry in byCategory.entries)
            ListTile(
              title: Text(entry.key.label),
              subtitle: Text('${entry.value.length} esercizi'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CategoryScreen(
                    category: entry.key,
                    exercises: entry.value,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
