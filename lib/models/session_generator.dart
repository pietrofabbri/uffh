import 'breathing.dart';
import 'category.dart';
import 'exercise.dart';
import 'progress.dart';
import 'session.dart';

/// Ordine di scorrimento delle categorie in una sessione generata:
/// pensato per alternare lavoro "hard" (forza/skill) e "soft"
/// (flessibilita'), cosi' che la sessione non sia un blocco di forza
/// seguito da un blocco di mobilita' separato -- coerente con la scelta
/// di flow continuo di docs/ARCHITETTURA.md sezione 9. Categorie senza
/// esercizi (oggi coreFrontale/coreLaterale/corePosteriore/bodyline/
/// gambe) vengono saltate automaticamente da [generateSession].
const _categoryOrder = [
  FitnessCategory.spinta,
  FitnessCategory.flessibilita,
  FitnessCategory.trazione,
  FitnessCategory.equilibrio,
  FitnessCategory.gambe,
  FitnessCategory.coreFrontale,
  FitnessCategory.coreLaterale,
  FitnessCategory.corePosteriore,
  FitnessCategory.bodyline,
  FitnessCategory.acrobazie,
];

/// Durata di un passo di lavoro per [BreathPacing], di default. Numeri di
/// partenza -- NON ancora tarati su una prova pratica come il pacing del
/// respiro stesso (docs/ARCHITETTURA.md sezione 9.1, soft 5s->4s dopo la
/// prima prova): "hard" e' pensato per skill/forza a tentativi/ripetizioni
/// brevi e controllate (2s/atto -> 40s = ~20 atti), "soft" per lavoro di
/// mobilita' piu' prolungato (4s/atto -> 60s = ~15 atti).
const _durationForPacing = {
  BreathPacing.hard: Duration(seconds: 40),
  BreathPacing.soft: Duration(seconds: 60),
};

/// Genera una [TrainingSession] vera dal database di esercizi e dai
/// progressi correnti, al posto di una sequenza fissa come
/// [demoFlowSession] (docs/ROADMAP.md, punto 2).
///
/// Funzione pura (nessuno stato, nessun effetto collaterale): stesso
/// [progress]/[allExercises] -> stessa sessione, facile da testare senza
/// widget (vedi `test/session_generator_test.dart`), stesso principio di
/// [TrainingSessionPlayer.stateAt] (lib/models/session_player.dart).
///
/// Algoritmo, deliberatamente semplice per una prima versione -- le
/// scelte numeriche sotto sono ipotesi ragionevoli, non richieste
/// esplicitamente da Pietro, da tarare dopo una prova pratica come gia'
/// fatto per il pacing del respiro:
/// 1. Scorre le categorie nell'ordine [_categoryOrder].
/// 2. Per ciascuna, chiede a [ProgressController.nextStepFor] il
///    prossimo esercizio sbloccato-non-acquisito di livello piu' basso.
///    Categorie senza esercizi, o gia' completate con quelli attuali,
///    vengono saltate.
/// 3. Aggiunge l'esercizio come [ExerciseStep]: pacing hard per tutte le
///    categorie tranne flessibilita' (soft), durata da
///    [_durationForPacing].
/// 4. Tra un esercizio e il successivo inserisce un [RecoveryStep].
/// 5. Se dopo un giro completo delle categorie la durata totale non ha
///    ancora raggiunto [targetDuration], rifa' un altro giro (e' normale
///    ripetere lo stesso esercizio piu' volte in una seduta -- un
///    secondo "set") fino a un massimo di [maxRounds], per non entrare in
///    loop se il database ha troppo pochi esercizi sbloccati per
///    riempire il tempo richiesto (o li ha gia' acquisiti tutti).

/// Genera una sessione di CHECKUP di maturazione (docs/ARCHITETTURA.md
/// sezione 18) -- diversa da [generateSession]:
/// - include TUTTI gli esercizi gia' acquisiti (vedi
///   [ProgressController.exercisesForCheckup]), non solo il prossimo
///   passo non ancora acquisito per categoria, e ciascuno una volta
///   sola (nessun giro ripetuto: il checkup verifica la tenuta, non fa
///   volume);
/// - usa sempre la durata di BASE di [_durationForPacing], MAI il
///   bonus per [ProgressController.challengeLevelOf]: il punto e'
///   verificare che la forma minima regga ancora, non ripetere la
///   variante piu' impegnativa raggiunta nel tempo -- altrimenti un
///   checkup su molti esercizi con livello di sfida alto stancherebbe
///   troppo per essere sostenibile ogni [ProgressController.
///   checkupIntervalSessions] sessioni (richiesta esplicita di
///   Pietro: "nella forma minima, sennò ci si stanca");
/// - MAI mescola l'ordine: usa esattamente l'ordine restituito da
///   [ProgressController.exercisesForCheckup] (categoria poi livello),
///   per non far saltare chi lo esegue da una catena all'altra a caso
///   (altra richiesta esplicita di Pietro, "non possono essere fatti
///   in ordine casuale per non disperdere energie").
TrainingSession generateCheckupSession({
  required ProgressController progress,
  required List<Exercise> allExercises,
  String name = 'Checkup di maturazione',
}) {
  final exercises = progress.exercisesForCheckup(allExercises);
  final steps = <SessionStep>[];

  for (final exercise in exercises) {
    final pacing = exercise.category == FitnessCategory.flessibilita
        ? BreathPacing.soft
        : BreathPacing.hard;
    final duration = _durationForPacing[pacing]!;

    if (steps.isNotEmpty) {
      const recovery = RecoveryStep();
      steps.add(recovery);
    }
    steps.add(ExerciseStep(exercise: exercise, pacing: pacing, duration: duration));
  }

  return TrainingSession(name: name, steps: steps);
}

TrainingSession generateSession({
  required ProgressController progress,
  required List<Exercise> allExercises,
  Duration targetDuration = const Duration(minutes: 20),
  int maxRounds = 4,
  String name = 'Sessione',
}) {
  final steps = <SessionStep>[];
  var total = Duration.zero;

  for (var round = 0; round < maxRounds && total < targetDuration; round++) {
    var addedThisRound = false;
    for (final category in _categoryOrder) {
      if (total >= targetDuration) break;

      final categoryExercises =
          allExercises.where((e) => e.category == category).toList();
      final next = progress.nextStepFor(category, categoryExercises);
      if (next == null) continue;

      final pacing = category == FitnessCategory.flessibilita
          ? BreathPacing.soft
          : BreathPacing.hard;
      // Un esercizio a maturazione completa su cui l'utente ha scelto
      // di restare (invece di passare al successivo, vedi
      // ProgressController.resolveUpgrade) guadagna qualche secondo in
      // piu' per giro di "sfida" -- un'approssimazione di "piu'
      // ripetizioni", finche' il modello non ha un vero conteggio di
      // ripetizioni (docs/ARCHITETTURA.md sezione 16).
      final challengeLevel = progress.challengeLevelOf(next);
      final duration = _durationForPacing[pacing]! +
          Duration(seconds: 15 * challengeLevel);

      if (steps.isNotEmpty) {
        const recovery = RecoveryStep();
        steps.add(recovery);
        total += recovery.duration;
      }
      steps.add(ExerciseStep(exercise: next, pacing: pacing, duration: duration));
      total += duration;
      addedThisRound = true;
    }
    if (!addedThisRound) break;
  }

  return TrainingSession(name: name, steps: steps);
}
