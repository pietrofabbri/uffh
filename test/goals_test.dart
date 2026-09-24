import 'package:flutter_test/flutter_test.dart';

import 'package:allenamento/models/ability.dart';
import 'package:allenamento/models/category.dart';
import 'package:allenamento/models/exercise.dart';
import 'package:allenamento/models/goals.dart';
import 'package:allenamento/models/muscle.dart';
import 'package:allenamento/models/progress.dart';

/// Test degli obiettivi generali di allenamento (docs/ARCHITETTURA.md
/// sezione 19). Test puramente logici (nessun widget), coprono le
/// regole descritte in lib/models/goals.dart.
void main() {
  const pushA = Exercise(
    id: 'push-a',
    name: 'Push A',
    category: FitnessCategory.spinta,
    equipment: {},
    level: 0,
    scores: {
      Muscle.spalle: {Ability.forza: 2},
      Muscle.petto: {Ability.forza: 1},
    },
  );
  const pushB = Exercise(
    id: 'push-b',
    name: 'Push B',
    category: FitnessCategory.spinta,
    equipment: {},
    level: 1,
    prerequisiteIds: {'push-a'},
    scores: {
      Muscle.spalle: {Ability.forza: 3},
    },
  );
  final allExercises = [pushA, pushB];

  test('un peso non impostato è GoalWeight.nessuna', () {
    final goals = GoalsController();
    expect(goals.weightOf(Muscle.spalle, Ability.forza), GoalWeight.nessuna);
  });

  test('setWeight imposta e sovrascrive il peso di una coppia', () {
    final goals = GoalsController();
    goals.setWeight(Muscle.spalle, Ability.forza, GoalWeight.alta);
    expect(goals.weightOf(Muscle.spalle, Ability.forza), GoalWeight.alta);

    goals.setWeight(Muscle.spalle, Ability.forza, GoalWeight.bassa);
    expect(goals.weightOf(Muscle.spalle, Ability.forza), GoalWeight.bassa);
  });

  test('impostare GoalWeight.nessuna rimuove la coppia (non conta più come attiva)', () {
    final goals = GoalsController();
    goals.setWeight(Muscle.spalle, Ability.forza, GoalWeight.alta);
    expect(goals.activeWeightCount, 1);

    goals.setWeight(Muscle.spalle, Ability.forza, GoalWeight.nessuna);
    expect(goals.activeWeightCount, 0);
  });

  group('coverageOf', () {
    test('null se nessun esercizio del catalogo allena la combinazione', () {
      final goals = GoalsController();
      expect(
        goals.coverageOf(Muscle.polpacci, Ability.forza, allExercises, ProgressController()),
        isNull,
      );
    });

    test('0% se gli esercizi rilevanti non sono ancora acquisiti', () {
      final goals = GoalsController();
      final coverage = goals.coverageOf(
        Muscle.spalle,
        Ability.forza,
        allExercises,
        ProgressController(),
      );
      expect(coverage, 0.0);
    });

    test('pesa il contributo per lo score di ciascun esercizio, non per il conteggio', () {
      final goals = GoalsController();
      final progress = ProgressController()..markMastered('push-a');
      // push-a contribuisce 2 (spalle/forza), push-b 3: acquisito solo
      // push-a => 2 / (2 + 3) = 40%, non 50% (che sarebbe "1 esercizio
      // su 2", ignorando il peso relativo).
      final coverage = goals.coverageOf(
        Muscle.spalle,
        Ability.forza,
        allExercises,
        progress,
      );
      expect(coverage, 40.0);
    });

    test('100% quando tutti gli esercizi rilevanti sono acquisiti', () {
      final goals = GoalsController();
      final progress = ProgressController()
        ..markMastered('push-a')
        ..markMastered('push-b');
      final coverage = goals.coverageOf(
        Muscle.spalle,
        Ability.forza,
        allExercises,
        progress,
      );
      expect(coverage, 100.0);
    });

    test(
      'non usa maturityOf: un esercizio acquisito conta comunque anche se '
      'la sua maturazione è tornata a 0 (docs/ARCHITETTURA.md sezione 19)',
      () {
        final goals = GoalsController();
        final progress = ProgressController()..markMastered('push-a');
        // resolveUpgrade azzera sempre maturityOf, anche quando sposta
        // sul prossimo esercizio della catena: la copertura non deve
        // scendere per questo.
        progress.resolveUpgrade('push-a', moveToNext: true);
        expect(progress.maturityOf(pushA), 0.0);

        final coverage = goals.coverageOf(
          Muscle.spalle,
          Ability.forza,
          allExercises,
          progress,
        );
        expect(coverage, 40.0);
      },
    );
  });

  group('overallCoverage', () {
    test('null se nessun obiettivo è impostato', () {
      final goals = GoalsController();
      expect(goals.overallCoverage(allExercises, ProgressController()), isNull);
    });

    test('media solo tra le coppie con peso impostato e copertura calcolabile', () {
      final goals = GoalsController();
      final progress = ProgressController()..markMastered('push-a');

      // Spalle/forza: 40% coperto, calcolabile.
      goals.setWeight(Muscle.spalle, Ability.forza, GoalWeight.alta);
      // Polpacci/forza: nessun esercizio nel catalogo, non calcolabile:
      // deve essere escluso dalla media, non contare come 0%.
      goals.setWeight(Muscle.polpacci, Ability.forza, GoalWeight.bassa);

      expect(goals.overallCoverage(allExercises, progress), 40.0);
    });
  });

  group('obiettivi specifici (NamedGoal)', () {
    test('upsertNamedGoal aggiunge un nuovo obiettivo', () {
      final goals = GoalsController();
      goals.upsertNamedGoal(const NamedGoal(name: 'Loto', priority: 1));
      expect(goals.namedGoals, [const NamedGoal(name: 'Loto', priority: 1)]);
    });

    test('upsertNamedGoal con lo stesso nome (case-insensitive) sostituisce, non duplica', () {
      final goals = GoalsController();
      goals.upsertNamedGoal(const NamedGoal(name: 'Loto', priority: 1));
      goals.upsertNamedGoal(const NamedGoal(name: 'loto', priority: 3));

      expect(goals.namedGoals.length, 1);
      expect(goals.namedGoals.single.priority, 3);
    });

    test('namedGoals è ordinato per priorità crescente', () {
      final goals = GoalsController();
      goals.upsertNamedGoal(const NamedGoal(name: 'Spaccate', priority: 3));
      goals.upsertNamedGoal(const NamedGoal(name: 'Loto', priority: 1));
      goals.upsertNamedGoal(const NamedGoal(name: 'Verticale', priority: 2));

      expect(
        goals.namedGoals.map((g) => g.name).toList(),
        ['Loto', 'Verticale', 'Spaccate'],
      );
    });

    test('removeNamedGoal rimuove per nome (case-insensitive)', () {
      final goals = GoalsController();
      goals.upsertNamedGoal(const NamedGoal(name: 'Loto', priority: 1));
      goals.removeNamedGoal('LOTO');
      expect(goals.namedGoals, isEmpty);
    });
  });
}
