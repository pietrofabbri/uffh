import 'package:flutter_test/flutter_test.dart';

import 'package:allenamento/models/ability.dart';
import 'package:allenamento/models/breathing.dart';
import 'package:allenamento/models/category.dart';
import 'package:allenamento/models/exercise.dart';
import 'package:allenamento/models/muscle.dart';
import 'package:allenamento/models/progress.dart';
import 'package:allenamento/models/session.dart';
import 'package:allenamento/models/session_generator.dart';

/// Test di generateSession (docs/ROADMAP.md, punto 2). Come negli altri
/// test di questa cartella: puramente logici, nessun widget --
/// generateSession e' una funzione pura (stesso progress/allExercises ->
/// stessa sessione), quindi si testa direttamente.
void main() {
  const withExercise = Exercise(
    id: 'spinta-a',
    name: 'Esercizio spinta',
    category: FitnessCategory.spinta,
    equipment: {},
    level: 0,
    scores: {
      Muscle.petto: {Ability.forza: 2},
    },
  );
  const flexExercise = Exercise(
    id: 'flex-a',
    name: 'Esercizio flessibilita',
    category: FitnessCategory.flessibilita,
    equipment: {},
    level: 0,
  );
  final allExercises = [withExercise, flexExercise];

  test('include un esercizio per ogni categoria con esercizi disponibili', () {
    final progress = ProgressController();
    final session = generateSession(
      progress: progress,
      allExercises: allExercises,
      targetDuration: const Duration(minutes: 20),
    );

    final exerciseIds = session.steps
        .whereType<ExerciseStep>()
        .map((s) => s.exercise.id)
        .toSet();
    expect(exerciseIds, {'spinta-a', 'flex-a'});
  });

  test('assegna pacing soft a flessibilita e hard alle altre categorie', () {
    final progress = ProgressController();
    final session = generateSession(
      progress: progress,
      allExercises: allExercises,
      targetDuration: const Duration(minutes: 2),
      maxRounds: 1,
    );

    for (final step in session.steps.whereType<ExerciseStep>()) {
      if (step.exercise.category == FitnessCategory.flessibilita) {
        expect(step.pacing, BreathPacing.soft);
      } else {
        expect(step.pacing, BreathPacing.hard);
      }
    }
  });

  test('inserisce un recupero tra un esercizio e il successivo, non prima del primo', () {
    final progress = ProgressController();
    final session = generateSession(
      progress: progress,
      allExercises: allExercises,
      targetDuration: const Duration(minutes: 2),
      maxRounds: 1,
    );

    expect(session.steps.first, isA<ExerciseStep>());
    // Ogni RecoveryStep e' preceduto da un ExerciseStep (mai due recuperi
    // consecutivi, mai un recupero come primo passo).
    for (var i = 0; i < session.steps.length; i++) {
      if (session.steps[i] is RecoveryStep) {
        expect(i, greaterThan(0));
        expect(session.steps[i - 1], isA<ExerciseStep>());
      }
    }
  });

  test('categoria senza esercizi non genera errori, viene solo saltata', () {
    final progress = ProgressController();
    final session = generateSession(
      progress: progress,
      allExercises: [withExercise], // niente in flessibilita
      targetDuration: const Duration(minutes: 5),
      maxRounds: 1,
    );

    expect(
      session.steps.whereType<ExerciseStep>().every(
            (s) => s.exercise.category == FitnessCategory.spinta,
          ),
      isTrue,
    );
  });

  test('con tutto già acquisito, la sessione generata è vuota (nessun loop infinito)', () {
    final progress = ProgressController();
    progress.markMastered('spinta-a');
    progress.markMastered('flex-a');

    final session = generateSession(
      progress: progress,
      allExercises: allExercises,
      targetDuration: const Duration(minutes: 20),
    );

    expect(session.steps, isEmpty);
    expect(session.totalDuration, Duration.zero);
  });

  test('senza limite di round, ripete gli esercizi (nuovo "set") finché non raggiunge la durata target', () {
    final progress = ProgressController();
    final session = generateSession(
      progress: progress,
      allExercises: allExercises,
      targetDuration: const Duration(minutes: 10),
      maxRounds: 4,
    );

    final spintaCount = session.steps
        .whereType<ExerciseStep>()
        .where((s) => s.exercise.id == 'spinta-a')
        .length;
    expect(spintaCount, greaterThan(1));
    expect(session.totalDuration, lessThanOrEqualTo(const Duration(minutes: 10) + const Duration(seconds: 60)));
  });

  test('e\' deterministica: stesso progress/allExercises -> stessa sessione', () {
    final progress = ProgressController();
    progress.markMastered('spinta-a');

    final a = generateSession(progress: progress, allExercises: allExercises);
    final b = generateSession(progress: progress, allExercises: allExercises);

    final idsA = a.steps.whereType<ExerciseStep>().map((s) => s.exercise.id).toList();
    final idsB = b.steps.whereType<ExerciseStep>().map((s) => s.exercise.id).toList();
    expect(idsA, idsB);
  });

  test('un livello di sfida allunga la durata assegnata a quell\'esercizio (docs/ARCHITETTURA.md sezione 16)', () {
    final progress = ProgressController();
    for (var i = 0; i < 4; i++) {
      progress.recordOutcome('spinta-a', ExerciseOutcome.andataBene);
    }
    progress.resolveUpgrade('spinta-a', moveToNext: false); // livello di sfida 1

    final session = generateSession(
      progress: progress,
      allExercises: allExercises,
      targetDuration: const Duration(minutes: 2),
      maxRounds: 1,
    );

    final spintaStep = session.steps
        .whereType<ExerciseStep>()
        .firstWhere((s) => s.exercise.id == 'spinta-a');
    // hard = 40s di base, +15s per livello di sfida.
    expect(spintaStep.duration, const Duration(seconds: 55));
  });

  group('generateCheckupSession (docs/ARCHITETTURA.md sezione 18)', () {
    test('include solo gli esercizi già acquisiti, una volta ciascuno', () {
      final progress = ProgressController();
      progress.markMastered('spinta-a');
      // flex-a resta non acquisito: non deve comparire nel checkup.

      final checkup = generateCheckupSession(
        progress: progress,
        allExercises: allExercises,
      );

      final ids = checkup.steps.whereType<ExerciseStep>().map((s) => s.exercise.id).toList();
      expect(ids, ['spinta-a']);
    });

    test('ignora il livello di sfida: usa sempre la durata di base ("forma minima")', () {
      final progress = ProgressController();
      // Accumula un livello di sfida restando sull'esercizio (resolveUpgrade
      // con moveToNext: false), poi lo marca acquisito -- resolveUpgrade non
      // tocca mai il livello di sfida quando si passa al successivo, quindi
      // resta 1 anche dopo.
      for (var i = 0; i < 4; i++) {
        progress.recordOutcome('spinta-a', ExerciseOutcome.andataBene);
      }
      progress.resolveUpgrade('spinta-a', moveToNext: false);
      expect(progress.challengeLevelOf(withExercise), 1);
      progress.markMastered('spinta-a');

      final checkup = generateCheckupSession(
        progress: progress,
        allExercises: allExercises,
      );

      final spintaStep = checkup.steps
          .whereType<ExerciseStep>()
          .firstWhere((s) => s.exercise.id == 'spinta-a');
      // generateSession, con lo stesso livello di sfida 1, darebbe 55s
      // (40s + 15s): il checkup resta invece a 40s, la durata di base.
      expect(spintaStep.duration, const Duration(seconds: 40));
    });

    test('non mescola mai l\'ordine: categoria poi livello, come exercisesForCheckup', () {
      const legEasy = Exercise(
        id: 'gambe-facile',
        name: 'Gambe facile',
        category: FitnessCategory.gambe,
        equipment: {},
        level: 0,
      );
      final progress = ProgressController();
      progress.markMastered('gambe-facile');
      progress.markMastered('flex-a');
      progress.markMastered('spinta-a');

      final checkup = generateCheckupSession(
        progress: progress,
        allExercises: [withExercise, flexExercise, legEasy],
      );

      final ids = checkup.steps.whereType<ExerciseStep>().map((s) => s.exercise.id).toList();
      // L'ordine segue FitnessCategory.values (spinta, ..., gambe,
      // flessibilita, ...), MAI l'ordine sparso in cui sono stati
      // acquisiti sopra -- verificato contro
      // ProgressController.exercisesForCheckup direttamente, che è la
      // fonte di verità per l'ordinamento.
      expect(
        ids,
        progress.exercisesForCheckup([withExercise, flexExercise, legEasy]).map((e) => e.id).toList(),
      );
    });

    test('senza nulla di acquisito, il checkup è vuoto', () {
      final progress = ProgressController();
      final checkup = generateCheckupSession(
        progress: progress,
        allExercises: allExercises,
      );
      expect(checkup.steps, isEmpty);
    });
  });
}
