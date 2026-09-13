import 'package:flutter/foundation.dart';

import 'category.dart';
import 'exercise.dart';

/// Stato di un esercizio rispetto ai progressi dell'utente.
enum ExerciseStatus {
  /// Il prerequisito non è ancora stato acquisito: esercizio non ancora
  /// consigliato.
  locked,

  /// Prerequisiti soddisfatti (o nessun prerequisito): esercizio pronto
  /// da allenare.
  unlocked,

  /// L'utente ha segnato l'esercizio come acquisito/consolidato.
  mastered,
}

/// Il motore di progressione (vedi docs/ROADMAP.md, punto 1).
///
/// Non usa un singolo "livello" numerico per decidere cosa proporre: usa
/// il grafo di prerequisiti tra esercizi (`Exercise.prerequisiteId`), lo
/// stesso pattern "categoria x livelli x prerequisiti" descritto in
/// docs/ARCHITETTURA.md sezione 2 (ispirato pubblicamente da Titans
/// Grip). Il "livello per categoria" è derivato da questo grafo (vedi
/// [levelFor]), non è uno stato indipendente da tenere sincronizzato a
/// mano.
///
/// Persistenza non ancora implementata (vedi docs/ROADMAP.md, punto
/// "Persistenza locale"): [ProgressController] vive solo in memoria e si
/// azzera a ogni riavvio dell'app. Va ricreato/collegato a uno storage
/// locale (sqflite/drift) quando quel punto della roadmap verrà
/// affrontato — l'interfaccia pubblica di questa classe non dovrebbe
/// dover cambiare, solo da dove viene inizializzato [masteredExerciseIds].
class ProgressController extends ChangeNotifier {
  final Set<String> _masteredExerciseIds;

  ProgressController({Set<String>? masteredExerciseIds})
      : _masteredExerciseIds = {...?masteredExerciseIds};

  /// Copia difensiva e non modificabile: per cambiare lo stato usare
  /// [markMastered]/[markNotMastered]/[toggleMastered].
  Set<String> get masteredExerciseIds =>
      Set.unmodifiable(_masteredExerciseIds);

  bool isMastered(Exercise exercise) =>
      _masteredExerciseIds.contains(exercise.id);

  /// Un esercizio è sbloccato se non ha prerequisito, oppure se il suo
  /// prerequisito è già stato acquisito. Un esercizio già acquisito è
  /// per definizione anche sbloccato.
  bool isUnlocked(Exercise exercise) {
    final prerequisiteId = exercise.prerequisiteId;
    if (prerequisiteId == null) return true;
    return _masteredExerciseIds.contains(prerequisiteId);
  }

  ExerciseStatus statusOf(Exercise exercise) {
    if (isMastered(exercise)) return ExerciseStatus.mastered;
    if (isUnlocked(exercise)) return ExerciseStatus.unlocked;
    return ExerciseStatus.locked;
  }

  void markMastered(String exerciseId) {
    if (_masteredExerciseIds.add(exerciseId)) notifyListeners();
  }

  void markNotMastered(String exerciseId) {
    if (_masteredExerciseIds.remove(exerciseId)) notifyListeners();
  }

  void toggleMastered(String exerciseId) {
    if (_masteredExerciseIds.contains(exerciseId)) {
      markNotMastered(exerciseId);
    } else {
      markMastered(exerciseId);
    }
  }

  /// Livello raggiunto in una categoria: il livello più alto tra gli
  /// esercizi acquisiti in quella categoria, 0 se nessuno è ancora stato
  /// acquisito ("mai valutato", vedi docs/ROADMAP.md punto
  /// "Valutazione iniziale del livello per categoria").
  int levelFor(FitnessCategory category, List<Exercise> allExercises) {
    final masteredLevels = allExercises
        .where((e) => e.category == category && isMastered(e))
        .map((e) => e.level);
    if (masteredLevels.isEmpty) return 0;
    return masteredLevels.reduce((a, b) => a > b ? a : b);
  }

  /// Il prossimo passo ragionevole in una categoria: tra gli esercizi
  /// sbloccati e non ancora acquisiti, quello con livello più basso (il
  /// più vicino a ciò che l'utente sa già fare). `null` se non c'è nulla
  /// di sbloccato-e-non-acquisito, cioè la categoria è vuota o è già
  /// stata completata con gli esercizi attualmente presenti.
  Exercise? nextStepFor(FitnessCategory category, List<Exercise> allExercises) {
    final candidates = allExercises
        .where((e) => e.category == category)
        .where((e) => isUnlocked(e) && !isMastered(e))
        .toList()
      ..sort((a, b) => a.level.compareTo(b.level));
    return candidates.isEmpty ? null : candidates.first;
  }
}
