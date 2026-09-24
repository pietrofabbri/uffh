import 'breathing.dart';
import 'exercise.dart';

/// Un passo di una [TrainingSession]: o l'esecuzione di un [Exercise] con
/// un respiro scandito ([ExerciseStep]), o un blocco di recupero a
/// respiro libero ([RecoveryStep]). Vedi docs/ARCHITETTURA.md, sezione 9,
/// per il design del motore che consuma questi passi.
sealed class SessionStep {
  const SessionStep();

  /// Durata "di riferimento" del passo. Per [RecoveryStep] è una durata
  /// SUGGERITA, non un vincolo fisiologico — vedi quella classe.
  Duration get duration;

  /// Testo brevissimo per la voce che introduce il passo (es. nome
  /// dell'esercizio, o "Recupero"): deve restare breve per non essere
  /// invasivo durante l'allenamento.
  String get announcement;
}

/// Esecuzione di un [Exercise] con un respiro scandito da [pacing] (mai
/// [BreathPacing.libero]: un esercizio a respiro libero è concettualmente
/// un [RecoveryStep], non un [ExerciseStep]).
class ExerciseStep extends SessionStep {
  final Exercise exercise;
  final BreathPacing pacing;

  @override
  final Duration duration;

  ExerciseStep({
    required this.exercise,
    required this.pacing,
    required this.duration,
  }) : assert(
          pacing != BreathPacing.libero,
          'un ExerciseStep a respiro libero è concettualmente un RecoveryStep',
        );

  @override
  String get announcement => exercise.name;
}

/// Blocco di recupero a respiro libero. Decisione esplicita dell'utente:
/// NON aspetta un tocco manuale, avanza da solo dopo [suggestedDuration]
/// (valore consigliato in fase di progettazione: 30-60s) — vedi
/// docs/ARCHITETTURA.md, sezione 9.
class RecoveryStep extends SessionStep {
  final Duration suggestedDuration;

  const RecoveryStep({this.suggestedDuration = const Duration(seconds: 45)});

  /// Respiro sempre libero per definizione: un [RecoveryStep] con un
  /// pacing diverso da [BreathPacing.libero] sarebbe in realtà un
  /// [ExerciseStep] di recupero attivo.
  BreathPacing get pacing => BreathPacing.libero;

  @override
  Duration get duration => suggestedDuration;

  @override
  String get announcement => 'Recupero';
}

/// Una sessione di allenamento: una sequenza ordinata di [SessionStep], da
/// far scorrere con [TrainingSessionPlayer] (vedi
/// lib/models/session_player.dart).
///
/// Una [TrainingSession] si costruisce passandole una lista di
/// [SessionStep] — a mano (come [demoFlowSession] qui sotto, tenuta come
/// esempio/fixture) o generata da [generateSession]
/// (lib/models/session_generator.dart, docs/ROADMAP.md punto 2), che
/// l'app usa davvero (vedi lib/screens/home_screen.dart).
class TrainingSession {
  final String name;
  final List<SessionStep> steps;

  const TrainingSession({required this.name, required this.steps});

  Duration get totalDuration =>
      steps.fold(Duration.zero, (sum, step) => sum + step.duration);
}

/// Sessione dimostrativa costruita a mano su 3 [seedExercises], usata
/// per provare l'engine end-to-end durante lo sviluppo (docs/ROADMAP.md,
/// punto 2 — non e' piu' quello che lancia l'app, vedi
/// lib/screens/home_screen.dart, che ora chiama `generateSession`). Tenuta
/// come esempio/fixture: alterna soft/hard/recupero per esercitare tutti
/// i [BreathPacing].
final TrainingSession demoFlowSession = TrainingSession(
  name: 'Prova motore (demo)',
  steps: [
    ExerciseStep(
      exercise: seedExercises[0], // piegamento sulle ginocchia
      pacing: BreathPacing.soft,
      duration: const Duration(seconds: 40),
    ),
    const RecoveryStep(),
    ExerciseStep(
      exercise: seedExercises[3], // verticale al muro
      pacing: BreathPacing.hard,
      duration: const Duration(seconds: 20),
    ),
    const RecoveryStep(suggestedDuration: Duration(seconds: 30)),
    ExerciseStep(
      exercise: seedExercises[2], // rematore con fascia elastica
      pacing: BreathPacing.soft,
      duration: const Duration(seconds: 40),
    ),
  ],
);
