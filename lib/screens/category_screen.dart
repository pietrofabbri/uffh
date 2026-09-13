import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/exercise.dart';

/// Elenco degli esercizi di UNA categoria, con dettagli espandibili.
/// Scheletro minimo: nessuna progressione/persistenza ancora collegata
/// (vedi docs/ROADMAP.md per i prossimi passi).
class CategoryScreen extends StatelessWidget {
  final FitnessCategory category;
  final List<Exercise> exercises;

  const CategoryScreen({
    super.key,
    required this.category,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category.label)),
      body: exercises.isEmpty
          ? const Center(child: Text('Nessun esercizio ancora in questa categoria'))
          : ListView.builder(
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                return ExpansionTile(
                  title: Text(exercise.name),
                  subtitle: Text(
                    exercise.equipment.map((e) => e.label).join(' + '),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (exercise.cue.isNotEmpty) Text(exercise.cue),
                          const SizedBox(height: 8),
                          for (final tip in exercise.tips)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('› $tip'),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
