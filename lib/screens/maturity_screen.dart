import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/exercise.dart';
import '../models/progress.dart';

/// "Cosa so fare": tutti gli esercizi con il loro grado di maturazione
/// (`ProgressController.maturityOf`, 0-100%, docs/ARCHITETTURA.md
/// sezione 16) -- un segnale più fine di acquisito/non acquisito,
/// alimentato dagli esiti registrati nel recap di fine sessione
/// (`lib/screens/session_screen.dart`). A differenza di
/// [CategoryScreen] mostra TUTTI gli esercizi, anche quelli bloccati,
/// per dare un quadro completo di dove si è: le due schermate sono
/// complementari, non alternative.
class MaturityScreen extends StatelessWidget {
  final List<Exercise> exercises;
  final ProgressController progress;

  const MaturityScreen({
    super.key,
    required this.exercises,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final byCategory = <FitnessCategory, List<Exercise>>{};
    for (final exercise in exercises) {
      byCategory.putIfAbsent(exercise.category, () => []).add(exercise);
    }
    final categories = byCategory.keys.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return Scaffold(
      appBar: AppBar(title: const Text('Cosa so fare')),
      body: categories.isEmpty
          ? const Center(child: Text('Nessun esercizio nel database'))
          : ListenableBuilder(
              listenable: progress,
              builder: (context, _) {
                return ListView(
                  children: [
                    for (final category in categories) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Text(
                          category.label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      for (final exercise in (byCategory[category]!
                        ..sort((a, b) => a.level.compareTo(b.level))))
                        _MaturityRow(exercise: exercise, progress: progress),
                    ],
                  ],
                );
              },
            ),
    );
  }
}

class _MaturityRow extends StatelessWidget {
  final Exercise exercise;
  final ProgressController progress;

  const _MaturityRow({required this.exercise, required this.progress});

  @override
  Widget build(BuildContext context) {
    final status = progress.statusOf(exercise);
    final maturity = progress.maturityOf(exercise);
    final pending = progress.hasPendingUpgrade(exercise);
    final challengeLevel = progress.challengeLevelOf(exercise);

    return ListTile(
      leading: _StatusDot(status: status),
      title: Text(exercise.name),
      subtitle: status == ExerciseStatus.locked
          ? const Text('Bloccato')
          : Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: maturity / 100,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status == ExerciseStatus.mastered
                        ? 'Acquisito'
                            '${challengeLevel > 0 ? " — livello di sfida $challengeLevel" : ""}'
                        : '${maturity.round()}% maturo'
                            '${pending ? " — pronto per il prossimo passo" : ""}',
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final ExerciseStatus status;

  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ExerciseStatus.locked => Colors.grey,
      ExerciseStatus.unlocked => Colors.blue,
      ExerciseStatus.mastered => Colors.green,
    };
    return Icon(Icons.circle, color: color, size: 14);
  }
}
