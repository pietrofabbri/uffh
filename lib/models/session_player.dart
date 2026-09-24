import 'breathing.dart';
import 'session.dart';

/// Fase del respiro scandita da un tono: [inspiro] suona il tono più
/// acuto, [espiro] quello più grave (vedi `assets/audio/`).
enum BreathPhase { inspiro, espiro }

/// Stato della sessione in un preciso istante, cioè a un dato [Duration]
/// trascorso dall'inizio. È il risultato di [TrainingSessionPlayer.stateAt]
/// — vedi quella classe per il perché del design "funzione pura del tempo
/// trascorso".
class SessionPlaybackState {
  final int stepIndex;
  final SessionStep step;
  final Duration elapsedInStep;
  final Duration remainingInStep;

  /// `null` quando il passo corrente è a respiro libero (nessun tono da
  /// suonare), altrimenti la fase di respiro da scandire in questo
  /// istante.
  final BreathPhase? breathPhase;

  final bool isLastStep;

  /// `true` quando la sessione è arrivata in fondo (l'ultimo passo è
  /// esaurito): a questo punto [step]/[stepIndex] restano quelli
  /// dell'ultimo passo, non c'è un passo "oltre la fine".
  final bool isFinished;

  const SessionPlaybackState({
    required this.stepIndex,
    required this.step,
    required this.elapsedInStep,
    required this.remainingInStep,
    required this.breathPhase,
    required this.isLastStep,
    required this.isFinished,
  });
}

/// Motore di riproduzione di una [TrainingSession].
///
/// Segue lo stesso principio di [ProgressController]
/// (lib/models/progress.dart): la logica è una funzione pura del tempo
/// trascorso ([stateAt]), senza `Timer` né stato interno mutabile. Questo
/// la rende testabile passando `Duration` arbitrarie (vedi
/// test/session_player_test.dart) e rende "riavvolgere"/"mettere in
/// pausa e riprendere" solo una questione di ricalcolare a un
/// [Duration] diverso — nessuno stato da tenere sincronizzato a mano.
///
/// Il collegamento a un `Timer.periodic` reale (per pilotare
/// text-to-speech e riproduzione audio) vive nella UI
/// (lib/screens/session_screen.dart), non qui.
class TrainingSessionPlayer {
  final TrainingSession session;

  const TrainingSessionPlayer(this.session);

  /// Stato della sessione a [elapsed] dall'inizio.
  SessionPlaybackState stateAt(Duration elapsed) {
    if (session.steps.isEmpty) {
      throw StateError('TrainingSession "${session.name}" non ha passi');
    }

    var cursor = Duration.zero;
    for (var i = 0; i < session.steps.length; i++) {
      final step = session.steps[i];
      final stepEnd = cursor + step.duration;
      final isLastStep = i == session.steps.length - 1;

      if (elapsed < stepEnd || isLastStep) {
        final rawElapsedInStep = elapsed - cursor;
        final elapsedInStep = rawElapsedInStep.isNegative
            ? Duration.zero
            : (rawElapsedInStep > step.duration
                ? step.duration
                : rawElapsedInStep);
        final remainingInStep = step.duration - elapsedInStep;

        return SessionPlaybackState(
          stepIndex: i,
          step: step,
          elapsedInStep: elapsedInStep,
          remainingInStep: remainingInStep,
          breathPhase: _breathPhaseAt(step, elapsedInStep),
          isLastStep: isLastStep,
          isFinished: isLastStep && elapsed >= stepEnd,
        );
      }

      cursor = stepEnd;
    }

    // Irraggiungibile: il ramo isLastStep sopra copre sempre l'ultima
    // iterazione del for.
    throw StateError('stateAt: nessun passo raggiunto (bug nel motore)');
  }

  /// Istante (tempo trascorso dall'inizio sessione) in cui inizia il passo
  /// [stepIndex]. Usato per i comandi avanti/indietro
  /// ([SessionPlaybackController.skipToNextStep]/[skipToPreviousStep]):
  /// "saltare al passo N" è solo "andare all'istante in cui N inizia".
  Duration startOf(int stepIndex) {
    var cursor = Duration.zero;
    for (var i = 0; i < stepIndex && i < session.steps.length; i++) {
      cursor += session.steps[i].duration;
    }
    return cursor;
  }

  BreathPhase? _breathPhaseAt(SessionStep step, Duration elapsedInStep) {
    final pacing = step is ExerciseStep ? step.pacing : BreathPacing.libero;
    final phaseDuration = pacing.breathPhaseDuration;
    if (phaseDuration == null) return null;

    final phaseIndex =
        elapsedInStep.inMilliseconds ~/ phaseDuration.inMilliseconds;
    return phaseIndex.isEven ? BreathPhase.inspiro : BreathPhase.espiro;
  }

  /// Messaggi da annunciare via voce nell'istante in cui si passa da
  /// [previousElapsed] a [elapsed]. Pensato per essere chiamato una volta
  /// per tick da un `Timer.periodic` lato UI: rileva il momento esatto in
  /// cui si attraversa un "momento chiave" (inizio passo, metà, ultimi
  /// 5-4-3-2-1 secondi), invece di ripeterlo a ogni tick mentre resta
  /// vero — per questo confronta due istanti anziché leggerne uno solo.
  ///
  /// Chiamare con `previousElapsed` negativo (es. `-tickInterval`) al
  /// primissimo tick per ottenere l'annuncio del primo passo.
  List<String> announcementsBetween(
    Duration previousElapsed,
    Duration elapsed,
  ) {
    final before = stateAt(
      previousElapsed.isNegative ? Duration.zero : previousElapsed,
    );
    final after = stateAt(elapsed);
    final messages = <String>[];

    final isFirstTick = previousElapsed.isNegative;
    if (isFirstTick || after.stepIndex != before.stepIndex) {
      messages.add(after.step.announcement);
    }

    final sameStep = !isFirstTick && after.stepIndex == before.stepIndex;
    if (sameStep) {
      final halfway = Duration(
        microseconds: after.step.duration.inMicroseconds ~/ 2,
      );
      final longEnoughToAnnounceHalfway =
          after.step.duration > const Duration(seconds: 20);
      if (longEnoughToAnnounceHalfway &&
          before.remainingInStep > halfway &&
          after.remainingInStep <= halfway) {
        messages.add('A metà');
      }

      for (final seconds in const [5, 4, 3, 2, 1]) {
        final threshold = Duration(seconds: seconds);
        if (before.remainingInStep > threshold &&
            after.remainingInStep <= threshold) {
          messages.add('$seconds');
        }
      }
    }

    return messages;
  }
}
