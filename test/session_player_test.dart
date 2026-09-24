import 'package:flutter_test/flutter_test.dart';

import 'package:allenamento/models/breathing.dart';
import 'package:allenamento/models/category.dart';
import 'package:allenamento/models/exercise.dart';
import 'package:allenamento/models/session.dart';
import 'package:allenamento/models/session_player.dart';

/// Test del motore di riproduzione della sessione guidata
/// (docs/ARCHITETTURA.md, sezione 9). Come in test/progress_test.dart,
/// sono test puramente logici: [TrainingSessionPlayer.stateAt] è una
/// funzione pura del tempo trascorso, quindi si testa passandole
/// `Duration` arbitrarie, senza bisogno di un `Timer` reale né di un
/// widget.
void main() {
  const soft = Exercise(
    id: 'soft',
    name: 'Esercizio soft',
    category: FitnessCategory.flessibilita,
    equipment: {},
    level: 0,
  );
  const hard = Exercise(
    id: 'hard',
    name: 'Esercizio hard',
    category: FitnessCategory.spinta,
    equipment: {},
    level: 0,
  );

  final session = TrainingSession(
    name: 'Sessione di prova',
    steps: [
      ExerciseStep(
        exercise: soft,
        pacing: BreathPacing.soft,
        duration: const Duration(seconds: 10),
      ),
      const RecoveryStep(suggestedDuration: Duration(seconds: 8)),
      ExerciseStep(
        exercise: hard,
        pacing: BreathPacing.hard,
        duration: const Duration(seconds: 6),
      ),
    ],
  );

  group('stateAt', () {
    test('a inizio sessione è nel primo passo, respiro non ancora scaduto', () {
      final player = TrainingSessionPlayer(session);
      final state = player.stateAt(Duration.zero);

      expect(state.stepIndex, 0);
      expect(state.step, isA<ExerciseStep>());
      expect(state.remainingInStep, const Duration(seconds: 10));
      expect(state.breathPhase, BreathPhase.inspiro);
      expect(state.isFinished, isFalse);
    });

    test('passa al passo successivo quando il primo è esaurito', () {
      final player = TrainingSessionPlayer(session);
      final state = player.stateAt(const Duration(seconds: 10));

      expect(state.stepIndex, 1);
      expect(state.step, isA<RecoveryStep>());
      expect(state.remainingInStep, const Duration(seconds: 8));
    });

    test('un RecoveryStep non ha mai una fase di respiro scandita', () {
      final player = TrainingSessionPlayer(session);
      final state = player.stateAt(const Duration(seconds: 14));

      expect(state.step, isA<RecoveryStep>());
      expect(state.breathPhase, isNull);
    });

    test(
      'pacing soft: un atto respiratorio ogni 4s (inspiro poi espiro)',
      () {
        final player = TrainingSessionPlayer(session);
        expect(player.stateAt(Duration.zero).breathPhase, BreathPhase.inspiro);
        expect(
          player.stateAt(const Duration(seconds: 3)).breathPhase,
          BreathPhase.inspiro,
        );
        expect(
          player.stateAt(const Duration(seconds: 4)).breathPhase,
          BreathPhase.espiro,
        );
        expect(
          player.stateAt(const Duration(seconds: 7)).breathPhase,
          BreathPhase.espiro,
        );
        expect(
          player.stateAt(const Duration(seconds: 8)).breathPhase,
          BreathPhase.inspiro,
        );
      },
    );

    test(
      'pacing hard: un atto respiratorio ogni 2s, più rapido del soft',
      () {
        final player = TrainingSessionPlayer(session);
        // Il passo hard inizia a t=18s (10 + 8 di recupero).
        expect(
          player.stateAt(const Duration(seconds: 18)).breathPhase,
          BreathPhase.inspiro,
        );
        expect(
          player.stateAt(const Duration(seconds: 19)).breathPhase,
          BreathPhase.inspiro,
        );
        expect(
          player.stateAt(const Duration(seconds: 20)).breathPhase,
          BreathPhase.espiro,
        );
      },
    );

    test('resta sull\'ultimo passo, marcato isFinished, dopo la fine', () {
      final player = TrainingSessionPlayer(session);
      final state = player.stateAt(const Duration(minutes: 5));

      expect(state.stepIndex, 2);
      expect(state.isLastStep, isTrue);
      expect(state.isFinished, isTrue);
      expect(state.remainingInStep, Duration.zero);
    });

    test('è puramente funzionale: stessa Duration, stesso risultato', () {
      final player = TrainingSessionPlayer(session);
      final a = player.stateAt(const Duration(seconds: 7));
      final b = player.stateAt(const Duration(seconds: 7));

      expect(a.stepIndex, b.stepIndex);
      expect(a.remainingInStep, b.remainingInStep);
      expect(a.breathPhase, b.breathPhase);
    });
  });

  group('startOf', () {
    test('è l\'istante cumulativo di inizio di ciascun passo', () {
      final player = TrainingSessionPlayer(session);

      expect(player.startOf(0), Duration.zero);
      expect(player.startOf(1), const Duration(seconds: 10)); // fine step0
      expect(player.startOf(2), const Duration(seconds: 18)); // 10 + 8
    });

    test('oltre l\'ultimo passo resta la durata totale della sessione', () {
      final player = TrainingSessionPlayer(session);

      expect(player.startOf(3), session.totalDuration);
    });
  });

  group('announcementsBetween', () {
    test('al primissimo tick annuncia il nome del primo esercizio', () {
      final player = TrainingSessionPlayer(session);
      final messages = player.announcementsBetween(
        const Duration(milliseconds: -200),
        Duration.zero,
      );

      expect(messages, contains('Esercizio soft'));
    });

    test('annuncia il passo successivo al cambio (es. "Recupero")', () {
      final player = TrainingSessionPlayer(session);
      final messages = player.announcementsBetween(
        const Duration(milliseconds: 9900),
        const Duration(milliseconds: 10100),
      );

      expect(messages, contains('Recupero'));
    });

    test('annuncia il conto alla rovescia solo una volta per secondo attraversato', () {
      final player = TrainingSessionPlayer(session);
      // Passo hard: 6s, da t=18s a t=24s. Attraversa la soglia dei 3s
      // (rimangono 3s) passando da t=20.9s a t=21.1s.
      final messages = player.announcementsBetween(
        const Duration(milliseconds: 20900),
        const Duration(milliseconds: 21100),
      );

      expect(messages, contains('3'));
      expect(messages.where((m) => m == '3').length, 1);
    });

    test('un tick "largo" cattura tutte le soglie attraversate nel mezzo', () {
      final player = TrainingSessionPlayer(session);
      // Dallo stesso passo hard, un tick che salta da 5,1s-rimanenti a
      // 1s-rimanente deve comunque annunciare 5,4,3,2,1 in ordine.
      final messages = player.announcementsBetween(
        const Duration(milliseconds: 18900), // 5,1s rimanenti nel passo hard
        const Duration(seconds: 23), // 1s rimanente
      );

      expect(messages, ['5', '4', '3', '2', '1']);
    });

    test('non annuncia "A metà" per passi brevi (≤ 20s)', () {
      final player = TrainingSessionPlayer(session);
      final messages = player.announcementsBetween(
        const Duration(seconds: 4),
        const Duration(seconds: 6),
      );

      expect(messages, isNot(contains('A metà')));
    });
  });
}
