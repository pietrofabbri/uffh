import 'package:flutter_test/flutter_test.dart';

import 'package:allenamento/models/category.dart';
import 'package:allenamento/models/exercise.dart';
import 'package:allenamento/models/progress.dart';

/// Test del motore di progressione (docs/ROADMAP.md, punto 1). Test
/// puramente logici (nessun widget), coprono le regole descritte in
/// lib/models/progress.dart e docs/ARCHITETTURA.md sezione 2.
void main() {
  const base = Exercise(
    id: 'base',
    name: 'Base',
    category: FitnessCategory.spinta,
    equipment: {Equipment.corpoLibero},
    level: 0,
  );
  const advanced = Exercise(
    id: 'advanced',
    name: 'Advanced',
    category: FitnessCategory.spinta,
    equipment: {Equipment.corpoLibero},
    level: 1,
    prerequisiteId: 'base',
  );
  final allExercises = [base, advanced];

  test('un esercizio senza prerequisito è sempre sbloccato', () {
    final progress = ProgressController();
    expect(progress.statusOf(base), ExerciseStatus.unlocked);
  });

  test(
    'un esercizio con prerequisito è bloccato finché il prerequisito '
    'non è acquisito',
    () {
      final progress = ProgressController();
      expect(progress.statusOf(advanced), ExerciseStatus.locked);

      progress.markMastered('base');
      expect(progress.statusOf(advanced), ExerciseStatus.unlocked);
    },
  );

  test(
    'markMastered rende l\'esercizio "mastered" e sblocca chi lo aveva '
    'come prerequisito',
    () {
      final progress = ProgressController();
      progress.markMastered('base');
      expect(progress.statusOf(base), ExerciseStatus.mastered);
      expect(progress.isUnlocked(advanced), isTrue);
    },
  );

  test('toggleMastered è reversibile', () {
    final progress = ProgressController();
    progress.toggleMastered('base');
    expect(progress.isMastered(base), isTrue);
    progress.toggleMastered('base');
    expect(progress.isMastered(base), isFalse);
  });

  test('levelFor restituisce 0 se nessun esercizio della categoria è acquisito', () {
    final progress = ProgressController();
    expect(progress.levelFor(FitnessCategory.spinta, allExercises), 0);
  });

  test('levelFor restituisce il livello più alto tra gli esercizi acquisiti', () {
    final progress = ProgressController();
    progress.markMastered('base');
    progress.markMastered('advanced');
    expect(progress.levelFor(FitnessCategory.spinta, allExercises), 1);
  });

  test(
    'nextStepFor propone l\'esercizio sbloccato di livello più basso non '
    'ancora acquisito',
    () {
      final progress = ProgressController();
      expect(
        progress.nextStepFor(FitnessCategory.spinta, allExercises)?.id,
        'base',
      );

      progress.markMastered('base');
      expect(
        progress.nextStepFor(FitnessCategory.spinta, allExercises)?.id,
        'advanced',
      );

      progress.markMastered('advanced');
      expect(progress.nextStepFor(FitnessCategory.spinta, allExercises), isNull);
    },
  );

  test('categoria senza esercizi: nextStepFor è null, levelFor è 0', () {
    final progress = ProgressController();
    expect(progress.nextStepFor(FitnessCategory.gambe, allExercises), isNull);
    expect(progress.levelFor(FitnessCategory.gambe, allExercises), 0);
  });
}
