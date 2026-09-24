import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/exercise.dart';
import '../models/progress.dart';

/// Elenco degli esercizi di UNA categoria, con dettagli espandibili e lo
/// stato di progressione di ciascuno (bloccato / sbloccato / acquisito —
/// vedi [ProgressController]). Toccando "Segna come acquisito" su un
/// esercizio sbloccato, gli esercizi che lo avevano come prerequisito si
/// sbloccano a loro volta.
class CategoryScreen extends StatelessWidget {
  final FitnessCategory category;
  final List<Exercise> exercises;
  final ProgressController progress;

  const CategoryScreen({
    super.key,
    required this.category,
    required this.exercises,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...exercises]..sort((a, b) => a.level.compareTo(b.level));

    return Scaffold(
      appBar: AppBar(title: Text(category.label)),
      body: exercises.isEmpty
          ? const Center(
              child: Text('Nessun esercizio ancora in questa categoria'),
            )
          : ListenableBuilder(
              listenable: progress,
              builder: (context, _) {
                return ListView.builder(
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final exercise = sorted[index];
                    final status = progress.statusOf(exercise);
                    return ExpansionTile(
                      leading: _StatusIcon(status: status),
                      title: Text(exercise.name),
                      subtitle: Text(_subtitleFor(exercise, status)),
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
                              const SizedBox(height: 12),
                              FilledButton.tonal(
                                onPressed: status == ExerciseStatus.locked
                                    ? null
                                    : () => progress.toggleMastered(exercise.id),
                                child: Text(
                                  status == ExerciseStatus.mastered
                                      ? 'Acquisito ✓ — tocca per annullare'
                                      : 'Segna come acquisito',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }

  String _subtitleFor(Exercise exercise, ExerciseStatus status) {
    final equipmentLabel = exercise.equipment.map((e) => e.label).join(' + ');
    if (status != ExerciseStatus.locked) return equipmentLabel;
    return '$equipmentLabel — richiede: ${_prerequisiteNames(exercise)}';
  }

  /// I nomi di TUTTI i prerequisiti (possono essere più di uno — vedi
  /// docs/ARCHITETTURA.md sezione 10 — e possono appartenere a categorie
  /// diverse da questa schermata, quindi si cercano in [seedExercises],
  /// non nella lista [exercises] filtrata per categoria).
  String _prerequisiteNames(Exercise exercise) {
    if (exercise.prerequisiteIds.isEmpty) return '';
    return exercise.prerequisiteIds.map((id) {
      final match = seedExercises.where((e) => e.id == id);
      return match.isEmpty ? id : match.first.name;
    }).join(' + ');
  }
}

class _StatusIcon extends StatelessWidget {
  final ExerciseStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case ExerciseStatus.locked:
        return const Icon(Icons.lock_outline, color: Colors.grey);
      case ExerciseStatus.unlocked:
        return const Icon(Icons.radio_button_unchecked);
      case ExerciseStatus.mastered:
        return const Icon(Icons.check_circle, color: Colors.green);
    }
  }
}
