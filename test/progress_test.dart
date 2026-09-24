import 'package:flutter_test/flutter_test.dart';

import 'package:allenamento/models/ability.dart';
import 'package:allenamento/models/category.dart';
import 'package:allenamento/models/exercise.dart';
import 'package:allenamento/models/muscle.dart';
import 'package:allenamento/models/progress.dart';

/// Test del motore di progressione (docs/ROADMAP.md, punto 1). Test
/// puramente logici (nessun widget), coprono le regole descritte in
/// lib/models/progress.dart e docs/ARCHITETTURA.md sezioni 2 e 10.
void main() {
  const base = Exercise(
    id: 'base',
    name: 'Base',
    category: FitnessCategory.spinta,
    equipment: {},
    level: 0,
    scores: {
      Muscle.petto: {Ability.forza: 2},
    },
  );
  const advanced = Exercise(
    id: 'advanced',
    name: 'Advanced',
    category: FitnessCategory.spinta,
    equipment: {},
    level: 1,
    prerequisiteIds: {'base'},
    scores: {
      Muscle.petto: {Ability.forza: 3},
      Muscle.spalle: {Ability.forza: 1, Ability.equilibrio: 1},
    },
  );
  final allExercises = [base, advanced];

  test('un esercizio senza prerequisiti è sempre sbloccato', () {
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
    'con più prerequisiti servono TUTTI: uno solo non basta a sbloccare '
    '(docs/ARCHITETTURA.md sezione 10)',
    () {
      const gate1 = Exercise(
        id: 'gate1',
        name: 'Gate 1',
        category: FitnessCategory.spinta,
        equipment: {},
        level: 0,
      );
      const gate2 = Exercise(
        id: 'gate2',
        name: 'Gate 2',
        category: FitnessCategory.equilibrio,
        equipment: {},
        level: 0,
      );
      const goal = Exercise(
        id: 'goal',
        name: 'Goal',
        category: FitnessCategory.equilibrio,
        equipment: {},
        level: 1,
        prerequisiteIds: {'gate1', 'gate2'},
      );

      final progress = ProgressController();
      expect(progress.isUnlocked(goal), isFalse);

      progress.markMastered('gate1');
      expect(progress.isUnlocked(goal), isFalse); // manca ancora gate2

      progress.markMastered('gate2');
      expect(progress.isUnlocked(goal), isTrue); // ora entrambi acquisiti
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

  group('abilityScoreFor', () {
    test('0 se nessun esercizio che tocca quel muscolo/abilità è acquisito', () {
      final progress = ProgressController();
      expect(
        progress.abilityScoreFor(Muscle.petto, Ability.forza, allExercises),
        0,
      );
    });

    test('somma i punteggi tra TUTTI gli esercizi acquisiti, non solo uno', () {
      final progress = ProgressController();
      progress.markMastered('base'); // petto/forza: 2
      progress.markMastered('advanced'); // petto/forza: 3
      expect(
        progress.abilityScoreFor(Muscle.petto, Ability.forza, allExercises),
        5,
      );
    });

    test('conta solo l\'abilità richiesta, non tutte quelle dell\'esercizio', () {
      final progress = ProgressController();
      progress.markMastered('advanced'); // spalle: forza 1, equilibrio 1
      expect(
        progress.abilityScoreFor(Muscle.spalle, Ability.forza, allExercises),
        1,
      );
      expect(
        progress.abilityScoreFor(Muscle.spalle, Ability.equilibrio, allExercises),
        1,
      );
      expect(
        progress.abilityScoreFor(
          Muscle.spalle,
          Ability.coordinazione,
          allExercises,
        ),
        0,
      );
    });
  });

  test('musclesCovered elenca solo i muscoli presenti nei punteggi', () {
    final progress = ProgressController();
    expect(
      progress.musclesCovered(allExercises),
      {Muscle.petto, Muscle.spalle},
    );
  });

  group('grado di maturazione (docs/ARCHITETTURA.md sezione 16)', () {
    test('un esercizio mai registrato ha maturità 0', () {
      final progress = ProgressController();
      expect(progress.maturityOf(base), 0.0);
    });

    test('recordOutcome alza la maturità per un esito positivo', () {
      final progress = ProgressController();
      progress.recordOutcome('base', ExerciseOutcome.andataBene);
      expect(progress.maturityOf(base), 25.0);
    });

    test('recordOutcome abbassa la maturità per un esito negativo, senza scendere sotto 0', () {
      final progress = ProgressController();
      progress.recordOutcome('base', ExerciseOutcome.nonAncora);
      expect(progress.maturityOf(base), 0.0); // 0 - 15, clampato a 0
    });

    test('recordOutcome non supera mai 100', () {
      final progress = ProgressController();
      for (var i = 0; i < 10; i++) {
        progress.recordOutcome('base', ExerciseOutcome.andataBene);
      }
      expect(progress.maturityOf(base), 100.0);
    });

    test('hasPendingUpgrade è vero solo a maturità piena e non ancora acquisito', () {
      final progress = ProgressController();
      expect(progress.hasPendingUpgrade(base), isFalse);
      for (var i = 0; i < 4; i++) {
        progress.recordOutcome('base', ExerciseOutcome.andataBene);
      }
      expect(progress.maturityOf(base), 100.0);
      expect(progress.hasPendingUpgrade(base), isTrue);
    });

    test('hasPendingUpgrade torna falso una volta acquisito manualmente', () {
      final progress = ProgressController();
      for (var i = 0; i < 4; i++) {
        progress.recordOutcome('base', ExerciseOutcome.andataBene);
      }
      progress.markMastered('base');
      expect(progress.hasPendingUpgrade(base), isFalse);
    });

    test('resolveUpgrade(moveToNext: true) segna acquisito e azzera la maturità', () {
      final progress = ProgressController();
      for (var i = 0; i < 4; i++) {
        progress.recordOutcome('base', ExerciseOutcome.andataBene);
      }
      progress.resolveUpgrade('base', moveToNext: true);
      expect(progress.isMastered(base), isTrue);
      expect(progress.maturityOf(base), 0.0);
      expect(progress.challengeLevelOf(base), 0);
    });

    test('resolveUpgrade(moveToNext: false) alza il livello di sfida, resta non acquisito', () {
      final progress = ProgressController();
      for (var i = 0; i < 4; i++) {
        progress.recordOutcome('base', ExerciseOutcome.andataBene);
      }
      progress.resolveUpgrade('base', moveToNext: false);
      expect(progress.isMastered(base), isFalse);
      expect(progress.maturityOf(base), 0.0);
      expect(progress.challengeLevelOf(base), 1);
      expect(progress.hasPendingUpgrade(base), isFalse);
    });

    test('più resolveUpgrade(moveToNext: false) di fila accumulano il livello di sfida', () {
      final progress = ProgressController();
      for (var round = 0; round < 2; round++) {
        for (var i = 0; i < 4; i++) {
          progress.recordOutcome('base', ExerciseOutcome.andataBene);
        }
        progress.resolveUpgrade('base', moveToNext: false);
      }
      expect(progress.challengeLevelOf(base), 2);
    });
  });

  group('checkup di maturazione obbligatorio (docs/ARCHITETTURA.md sezione 18)', () {
    test('isCheckupDue diventa vero dopo checkupIntervalSessions sessioni normali', () {
      final progress = ProgressController();
      expect(progress.isCheckupDue, isFalse);
      for (var i = 0; i < ProgressController.checkupIntervalSessions - 1; i++) {
        progress.recordSessionCompleted();
      }
      expect(progress.isCheckupDue, isFalse);
      progress.recordSessionCompleted();
      expect(progress.isCheckupDue, isTrue);
    });

    test('completeCheckup azzera il conto verso il prossimo checkup', () {
      final progress = ProgressController();
      for (var i = 0; i < ProgressController.checkupIntervalSessions; i++) {
        progress.recordSessionCompleted();
      }
      expect(progress.isCheckupDue, isTrue);
      progress.completeCheckup();
      expect(progress.isCheckupDue, isFalse);
      expect(progress.sessionsSinceCheckup, 0);
    });

    test('exercisesForCheckup include solo gli esercizi acquisiti, ordinati per categoria poi livello', () {
      const legVeryEasy = Exercise(
        id: 'gambe-facile',
        name: 'Gambe facile',
        category: FitnessCategory.gambe,
        equipment: {},
        level: 0,
      );
      const legHarder = Exercise(
        id: 'gambe-difficile',
        name: 'Gambe difficile',
        category: FitnessCategory.gambe,
        equipment: {},
        level: 1,
      );
      final progress = ProgressController();
      // Acquisiti in ordine sparso apposta: l'ordine del checkup non deve
      // dipendere dall'ordine in cui sono stati acquisiti.
      progress.markMastered('gambe-difficile');
      progress.markMastered('advanced');
      progress.markMastered('base');
      progress.markMastered('gambe-facile');

      final forCheckup = progress.exercisesForCheckup(
        [base, advanced, legVeryEasy, legHarder],
      );

      // spinta (categoria con indice più basso) prima di gambe, e dentro
      // ciascuna categoria dal livello più basso al più alto -- mai
      // nell'ordine sparso in cui sono stati acquisiti.
      expect(forCheckup.map((e) => e.id).toList(), [
        'base',
        'advanced',
        'gambe-facile',
        'gambe-difficile',
      ]);
    });

    test('exercisesForCheckup non include esercizi non ancora acquisiti', () {
      final progress = ProgressController();
      progress.markMastered('base');
      final forCheckup = progress.exercisesForCheckup(allExercises);
      expect(forCheckup.map((e) => e.id).toList(), ['base']);
    });

    test('recordCheckupOutcome(andataBene) conferma la maturità piena e resta acquisito', () {
      final progress = ProgressController();
      progress.markMastered('base');
      progress.recordCheckupOutcome('base', ExerciseOutcome.andataBene);
      expect(progress.maturityOf(base), 100.0);
      expect(progress.isMastered(base), isTrue);
    });

    test('recordCheckupOutcome(cosiCosi) abbassa la maturità ma resta acquisito', () {
      final progress = ProgressController();
      progress.markMastered('base');
      progress.recordCheckupOutcome('base', ExerciseOutcome.cosiCosi);
      expect(progress.maturityOf(base), 50.0);
      expect(progress.isMastered(base), isTrue);
    });

    test('recordCheckupOutcome(nonAncora) toglie l\'acquisizione e riblocca chi ne dipendeva', () {
      final progress = ProgressController();
      progress.markMastered('base');
      expect(progress.statusOf(advanced), ExerciseStatus.unlocked);

      progress.recordCheckupOutcome('base', ExerciseOutcome.nonAncora);

      expect(progress.isMastered(base), isFalse);
      expect(progress.maturityOf(base), 30.0);
      // Effetto a cascata: advanced dipendeva da base, ora ritorna
      // bloccato finché base non viene riacquisito.
      expect(progress.statusOf(advanced), ExerciseStatus.locked);
    });
  });
}
