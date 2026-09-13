import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/exercise.dart';
import '../models/progress.dart';
import 'category_screen.dart';

/// Schermata iniziale: una categoria per riga, con il livello raggiunto
/// (derivato dagli esercizi acquisiti — vedi
/// [ProgressController.levelFor]) e il prossimo passo consigliato (vedi
/// [ProgressController.nextStepFor]).
class HomeScreen extends StatelessWidget {
  final ProgressController progress;

  const HomeScreen({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final byCategory = <FitnessCategory, List<Exercise>>{
      for (final category in FitnessCategory.values)
        category: seedExercises.where((e) => e.category == category).toList(),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Allenamento')),
      body: ListenableBuilder(
        listenable: progress,
        builder: (context, _) {
          return ListView(
            children: [
              for (final entry in byCategory.entries)
                _CategoryTile(
                  category: entry.key,
                  exercises: entry.value,
                  progress: progress,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final FitnessCategory category;
  final List<Exercise> exercises;
  final ProgressController progress;

  const _CategoryTile({
    required this.category,
    required this.exercises,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final level = progress.levelFor(category, exercises);
    final next = progress.nextStepFor(category, exercises);

    final String subtitle;
    if (exercises.isEmpty) {
      subtitle = 'Nessun esercizio ancora in questa categoria';
    } else if (next == null) {
      subtitle = 'Livello $level — completata con gli esercizi attuali';
    } else {
      subtitle = 'Livello $level — prossimo: ${next.name}';
    }

    return ListTile(
      title: Text(category.label),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CategoryScreen(
            category: category,
            exercises: exercises,
            progress: progress,
          ),
        ),
      ),
    );
  }
}
