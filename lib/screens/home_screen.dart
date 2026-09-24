import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/exercise.dart';
import '../models/goals.dart';
import '../models/progress.dart';
import '../models/session.dart';
import '../models/session_generator.dart';
import 'category_screen.dart';
import 'goals_screen.dart';
import 'graph_screen.dart';
import 'maturity_screen.dart';
import 'session_screen.dart';

/// Schermata iniziale: una categoria per riga, con il livello raggiunto
/// (derivato dagli esercizi acquisiti — vedi
/// [ProgressController.levelFor]) e il prossimo passo consigliato (vedi
/// [ProgressController.nextStepFor]).
class HomeScreen extends StatelessWidget {
  final ProgressController progress;
  final GoalsController goals;

  const HomeScreen({super.key, required this.progress, required this.goals});

  @override
  Widget build(BuildContext context) {
    final byCategory = <FitnessCategory, List<Exercise>>{
      for (final category in FitnessCategory.values)
        category: seedExercises.where((e) => e.category == category).toList(),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Allenamento'),
        actions: [
          IconButton(
            tooltip: 'Cosa so fare',
            icon: const Icon(Icons.insights_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MaturityScreen(
                  exercises: seedExercises,
                  progress: progress,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Grafo dei prerequisiti',
            icon: const Icon(Icons.hub_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => GraphScreen(
                  exercises: seedExercises,
                  progress: progress,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Obiettivi',
            icon: const Icon(Icons.track_changes_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => GoalsScreen(
                  goals: goals,
                  progress: progress,
                  exercises: seedExercises,
                ),
              ),
            ),
          ),
        ],
      ),
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
      // Sessione guidata a respiro sincronizzato (docs/ARCHITETTURA.md,
      // sezione 9): genera una sessione vera al momento del tocco, dal
      // database di esercizi e dai progressi correnti
      // (`generateSession`, lib/models/session_generator.dart,
      // docs/ROADMAP.md punto 2) — non più la sequenza fissa
      // `demoFlowSession`, che resta in session.dart solo come esempio.
      // Prima di avviarla, risolve eventuali richieste di "maturazione
      // completa" in sospeso (docs/ARCHITETTURA.md sezione 16).
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startSession(context),
        icon: Icon(
          progress.isCheckupDue
              ? Icons.fact_check_outlined
              : Icons.self_improvement,
        ),
        label: Text(
          progress.isCheckupDue ? 'Checkup di maturazione' : 'Inizia sessione',
        ),
      ),
    );
  }

  /// Genera la sessione, ma prima chiede all'utente cosa fare di ogni
  /// esercizio a maturazione completa in sospeso (vedi
  /// [ProgressController.hasPendingUpgrade], docs/ARCHITETTURA.md
  /// sezione 16): aumentare la difficoltà (resta nella sessione, più a
  /// lungo) o passare al prossimo esercizio della catena (lo sostituisce
  /// da qui in poi). Solo se qualcosa è cambiato rigenera la sessione,
  /// così le scelte fatte si riflettono davvero in cosa viene proposto.
  Future<void> _startSession(BuildContext context) async {
    // Checkup di maturazione obbligatorio (docs/ARCHITETTURA.md sezione
    // 18): se e' dovuto, lo si avvia AL POSTO della sessione normale
    // richiesta -- e' cosi' che diventa un vincolo reale e non un
    // promemoria ignorabile. Occorre toccare di nuovo "Inizia sessione"
    // per ottenere davvero la sessione normale, una volta risolto.
    if (progress.isCheckupDue) {
      final checkupExercises = progress.exercisesForCheckup(seedExercises);
      if (checkupExercises.isEmpty) {
        // Nulla ancora acquisito da ricontrollare: nessun checkup ha
        // senso, non blocchiamo chi sta ancora ai primi passi.
        progress.completeCheckup();
      } else {
        final checkupSession = generateCheckupSession(
          progress: progress,
          allExercises: seedExercises,
        );
        if (!context.mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SessionScreen(
              session: checkupSession,
              progress: progress,
              isCheckup: true,
            ),
          ),
        );
        return;
      }
    }

    var session = generateSession(
      progress: progress,
      allExercises: seedExercises,
      name: 'Sessione',
    );

    final exercisesInSession = <String, Exercise>{
      for (final step in session.steps)
        if (step is ExerciseStep) step.exercise.id: step.exercise,
    };
    final pending =
        exercisesInSession.values.where(progress.hasPendingUpgrade).toList();

    for (final exercise in pending) {
      if (!context.mounted) return;
      final moveToNext = await _askUpgradeChoice(context, exercise);
      if (moveToNext == null) continue; // chiuso senza scegliere: richiesta ancora aperta la prossima volta
      progress.resolveUpgrade(exercise.id, moveToNext: moveToNext);
    }

    if (pending.isNotEmpty) {
      session = generateSession(
        progress: progress,
        allExercises: seedExercises,
        name: 'Sessione',
      );
    }

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SessionScreen(session: session, progress: progress),
      ),
    );
  }

  /// `true` = passa al prossimo esercizio della catena, `false` = resta
  /// su questo aumentando la difficoltà, `null` = chiuso senza scegliere
  /// (vedi [ProgressController.resolveUpgrade]).
  Future<bool?> _askUpgradeChoice(BuildContext context, Exercise exercise) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${exercise.name}: pronto per il prossimo passo?'),
        content: const Text(
          "Hai raggiunto la maturazione completa su questo esercizio. "
          'Vuoi aumentare la difficoltà restando su questo esercizio, '
          'o passare al prossimo della catena?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Aumenta la difficoltà'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Passa al successivo'),
          ),
        ],
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
