import 'package:flutter/foundation.dart';

import 'ability.dart';
import 'category.dart';
import 'exercise.dart';
import 'muscle.dart';

/// L'esito di un esercizio in una sessione, usato da
/// [ProgressController.recordOutcome] per aggiornare
/// [ProgressController.maturityOf] (vedi docs/ARCHITETTURA.md sezione
/// 16). Non sostituisce [ExerciseStatus]: e' un segnale piu' fine,
/// raccolto a fine sessione (o durante i recuperi), che nel tempo porta
/// un esercizio verso la maturazione completa (100%).
enum ExerciseOutcome {
  andataBene,
  cosiCosi,
  nonAncora,
}

extension ExerciseOutcomeDelta on ExerciseOutcome {
  /// Variazione (punti percentuali, puo' essere negativa) applicata a
  /// [ProgressController.maturityOf] quando si registra questo esito.
  /// Numeri di partenza, non ancora tarati su una prova pratica (stesso
  /// spirito di docs/ARCHITETTURA.md sezione 13 per generateSession).
  double get maturityDelta {
    switch (this) {
      case ExerciseOutcome.andataBene:
        return 25;
      case ExerciseOutcome.cosiCosi:
        return 8;
      case ExerciseOutcome.nonAncora:
        return -15;
    }
  }
}

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
/// il grafo di prerequisiti tra esercizi (`Exercise.prerequisiteIds` — un
/// vero grafo con più prerequisiti possibili per esercizio, non solo una
/// catena, vedi docs/ARCHITETTURA.md sezione 10), lo stesso pattern
/// "categoria x livelli x prerequisiti" descritto in docs/ARCHITETTURA.md
/// sezione 2 (ispirato pubblicamente da Titans Grip), esteso per gli
/// obiettivi composti. Il "livello per categoria" è derivato da questo
/// grafo (vedi [levelFor]), non è uno stato indipendente da tenere
/// sincronizzato a mano. Allo stesso modo, [abilityScoreFor] deriva
/// quanto lavoro di forza/flessibilità/equilibrio/coordinazione è stato
/// fatto su un muscolo dagli `Exercise.scores` degli esercizi acquisiti —
/// un'altra vista sugli stessi dati, non un secondo stato da mantenere.
///
/// Persistenza non ancora implementata (vedi docs/ROADMAP.md, punto
/// "Persistenza locale"): [ProgressController] vive solo in memoria e si
/// azzera a ogni riavvio dell'app. Va ricreato/collegato a uno storage
/// locale (sqflite/drift) quando quel punto della roadmap verrà
/// affrontato — l'interfaccia pubblica di questa classe non dovrebbe
/// dover cambiare, solo da dove viene inizializzato [masteredExerciseIds].
class ProgressController extends ChangeNotifier {
  final Set<String> _masteredExerciseIds;

  /// Grado di maturazione per esercizio, 0-100 (vedi [maturityOf]/
  /// [recordOutcome], docs/ARCHITETTURA.md sezione 16). Assente da una
  /// mappa = 0, mai registrato.
  final Map<String, double> _maturity;

  /// Quante volte l'utente ha scelto di aumentare la difficolta' invece
  /// di passare al prossimo esercizio della catena, a maturazione
  /// completa (vedi [resolveUpgrade]). Assente = 0.
  final Map<String, int> _challengeLevel;

  /// Sessioni normali completate (vedi [recordSessionCompleted]) da
  /// quando e' stato fatto l'ultimo checkup di maturazione (vedi
  /// [isCheckupDue], docs/ARCHITETTURA.md sezione 18). Le sessioni di
  /// checkup stesse non incrementano questo contatore -- solo
  /// [completeCheckup] lo azzera.
  int _sessionsSinceCheckup;

  /// Ogni quante sessioni normali completate il checkup di maturazione
  /// diventa obbligatorio (vedi [isCheckupDue]). Valore di partenza, non
  /// ancora tarato su una prova pratica -- stesso spirito delle altre
  /// costanti numeriche di questo file, docs/ARCHITETTURA.md sezione 18.
  static const int checkupIntervalSessions = 6;

  ProgressController({
    Set<String>? masteredExerciseIds,
    Map<String, double>? maturity,
    Map<String, int>? challengeLevel,
    int sessionsSinceCheckup = 0,
  })  : _masteredExerciseIds = {...?masteredExerciseIds},
        _maturity = {...?maturity},
        _challengeLevel = {...?challengeLevel},
        _sessionsSinceCheckup = sessionsSinceCheckup;

  /// Copia difensiva e non modificabile: per cambiare lo stato usare
  /// [markMastered]/[markNotMastered]/[toggleMastered].
  Set<String> get masteredExerciseIds =>
      Set.unmodifiable(_masteredExerciseIds);

  bool isMastered(Exercise exercise) =>
      _masteredExerciseIds.contains(exercise.id);

  /// Un esercizio è sbloccato se non ha prerequisiti, oppure se TUTTI i
  /// suoi prerequisiti sono già stati acquisiti (non basta uno solo: vedi
  /// docs/ARCHITETTURA.md sezione 10, `verticale-libera` in
  /// `exercise.dart` per un esempio con due prerequisiti da categorie
  /// diverse). Un esercizio già acquisito è per definizione anche
  /// sbloccato.
  bool isUnlocked(Exercise exercise) {
    if (exercise.prerequisiteIds.isEmpty) return true;
    return exercise.prerequisiteIds.every(_masteredExerciseIds.contains);
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

  /// Quanto e' "maturo" un esercizio, 0-100 (vedi [recordOutcome]). 0
  /// per un esercizio mai registrato in una sessione. E' un segnale
  /// diverso e piu' fine di [isMastered]/[ExerciseStatus]: non decide da
  /// solo se l'esercizio resta nella rotazione delle sessioni generate
  /// (vedi [hasPendingUpgrade] per quello), docs/ARCHITETTURA.md sezione
  /// 16.
  double maturityOf(Exercise exercise) => _maturity[exercise.id] ?? 0.0;

  /// Registra come e' andato [exerciseId] in una sessione (vedi
  /// [ExerciseOutcome]), aggiornando [maturityOf] di conseguenza
  /// (clampato 0-100). Pensato per essere chiamato dal recap di fine
  /// sessione (o durante i recuperi), non dopo ogni singola ripetizione
  /// -- vedi docs/ARCHITETTURA.md sezione 16.
  void recordOutcome(String exerciseId, ExerciseOutcome outcome) {
    final current = _maturity[exerciseId] ?? 0.0;
    final next = (current + outcome.maturityDelta).clamp(0.0, 100.0);
    if (next == current) return;
    _maturity[exerciseId] = next;
    notifyListeners();
  }

  /// True quando un esercizio e' arrivato a maturazione completa (100%)
  /// ma la decisione non e' ancora stata presa (vedi [resolveUpgrade]):
  /// prima di iniziare una sessione che lo includerebbe, l'app chiede se
  /// aumentare la difficolta' o passare al prossimo esercizio della
  /// catena. Falso per un esercizio gia' [isMastered] (la decisione e'
  /// gia' stata presa, nel senso "passa al successivo").
  bool hasPendingUpgrade(Exercise exercise) =>
      maturityOf(exercise) >= 100.0 && !isMastered(exercise);

  /// Quante volte l'utente ha scelto "aumenta la difficolta'" invece di
  /// passare al prossimo esercizio della catena (vedi [resolveUpgrade]).
  /// [generateSession] (lib/models/session_generator.dart) lo usa per
  /// allungare la durata assegnata all'esercizio nella sessione generata
  /// -- un'approssimazione finche' il modello non ha un vero conteggio
  /// di ripetizioni, vedi docs/ARCHITETTURA.md sezione 16.
  int challengeLevelOf(Exercise exercise) => _challengeLevel[exercise.id] ?? 0;

  /// Risolve una richiesta segnalata da [hasPendingUpgrade]. Se
  /// [moveToNext] e' vero, l'esercizio viene segnato come acquisito
  /// (stessa logica di [markMastered]: sblocca il prossimo passo della
  /// catena e lo toglie dalla rotazione di [generateSession]);
  /// altrimenti resta nella rotazione ma il suo [challengeLevelOf] sale
  /// di uno. In entrambi i casi [maturityOf] riparte da 0, per
  /// ricominciare a misurare i progressi sul nuovo traguardo (il
  /// prossimo esercizio, o la versione piu' impegnativa di questo).
  void resolveUpgrade(String exerciseId, {required bool moveToNext}) {
    if (moveToNext) {
      _masteredExerciseIds.add(exerciseId);
    } else {
      _challengeLevel[exerciseId] = (_challengeLevel[exerciseId] ?? 0) + 1;
    }
    _maturity[exerciseId] = 0.0;
    notifyListeners();
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

  /// Quanto lavoro di [ability] è stato fatto su [muscle] finora: la
  /// somma di `Exercise.scores[muscle][ability]` tra gli esercizi
  /// ACQUISITI (indipendentemente da categoria/catena di appartenenza —
  /// vedi la docstring della classe). 0 se nessun esercizio acquisito
  /// tocca quella coppia muscolo/abilità.
  int abilityScoreFor(
    Muscle muscle,
    Ability ability,
    List<Exercise> allExercises,
  ) {
    return allExercises
        .where(isMastered)
        .map((e) => e.scores[muscle]?[ability] ?? 0)
        .fold(0, (sum, score) => sum + score);
  }

  /// Tutti i muscoli con almeno un punteggio in [allExercises], utile per
  /// popolare una vista "per muscolo" senza dover conoscere in anticipo
  /// quali muscoli sono coperti dal database esercizi attuale.
  Set<Muscle> musclesCovered(List<Exercise> allExercises) {
    return {for (final e in allExercises) ...e.scores.keys};
  }

  /// Sessioni normali completate da quando e' stato fatto l'ultimo
  /// checkup (vedi [checkupIntervalSessions], [isCheckupDue]).
  int get sessionsSinceCheckup => _sessionsSinceCheckup;

  /// True quando e' il momento di fare un checkup di maturazione prima
  /// della prossima sessione normale (docs/ARCHITETTURA.md sezione 18):
  /// [HomeScreen] lo controlla prima di avviare una sessione e, se vero,
  /// avvia il checkup al suo posto invece della sessione normale
  /// richiesta -- e' cosi' che il checkup diventa "obbligatorio", non
  /// un promemoria ignorabile.
  bool get isCheckupDue => _sessionsSinceCheckup >= checkupIntervalSessions;

  /// Da chiamare a fine di ogni sessione NORMALE (non di checkup): fa
  /// avanzare il conto verso il prossimo checkup obbligatorio. Le
  /// sessioni di checkup non chiamano mai questo metodo -- vedi
  /// [completeCheckup].
  void recordSessionCompleted() {
    _sessionsSinceCheckup++;
    notifyListeners();
  }

  /// Da chiamare a checkup di maturazione concluso: azzera il conto di
  /// [sessionsSinceCheckup], cosi' [isCheckupDue] torna falso fino al
  /// prossimo ciclo.
  void completeCheckup() {
    if (_sessionsSinceCheckup == 0) return;
    _sessionsSinceCheckup = 0;
    notifyListeners();
  }

  /// Gli esercizi da includere in un checkup di maturazione (docs/
  /// ARCHITETTURA.md sezione 18): solo quelli GIA' acquisiti
  /// ([isMastered]) -- il checkup verifica che le basi restino solide,
  /// non rivaluta ciò che e' ancora in costruzione (per quello c'e' gia'
  /// il recap di fine sessione, vedi [recordOutcome]). Ordinati per
  /// categoria (nell'ordine di dichiarazione di [FitnessCategory], che
  /// raggruppa gli schemi di movimento simili) e poi per livello
  /// crescente: MAI in ordine sparso, per non far saltare chi fa il
  /// checkup da una catena all'altra a caso disperdendo energie
  /// (richiesta esplicita di Pietro).
  List<Exercise> exercisesForCheckup(List<Exercise> allExercises) {
    final exercises = allExercises.where(isMastered).toList()
      ..sort((a, b) {
        final byCategory = a.category.index.compareTo(b.category.index);
        if (byCategory != 0) return byCategory;
        return a.level.compareTo(b.level);
      });
    return exercises;
  }

  /// Registra l'esito di un esercizio durante un checkup di
  /// maturazione (docs/ARCHITETTURA.md sezione 18) -- diverso da
  /// [recordOutcome], usato invece durante il recap di una sessione
  /// normale. Un checkup verifica la TENUTA di un esercizio gia'
  /// acquisito, quindi l'effetto e' più diretto di un semplice
  /// incremento/decremento:
  /// - [ExerciseOutcome.andataBene]: la base regge, [maturityOf] torna
  ///   al massimo, resta [isMastered].
  /// - [ExerciseOutcome.cosiCosi]: resta [isMastered] (non e' persa),
  ///   ma [maturityOf] scende a meta' come segnale visibile in "Cosa so
  ///   fare" che serve un ripasso.
  /// - [ExerciseOutcome.nonAncora]: la base non regge più: l'esercizio
  ///   viene tolto da [isMastered] (torna nella rotazione di
  ///   [generateSession] come uno qualsiasi degli esercizi da allenare)
  ///   con [maturityOf] a un valore basso ma non azzerato (resta una
  ///   competenza residua, non si riparte da zero assoluto). Effetto
  ///   collaterale voluto: se altri esercizi avevano questo come
  ///   prerequisito, tornano [ExerciseStatus.locked] finché non viene
  ///   riacquisito -- coerente con [isUnlocked].
  void recordCheckupOutcome(String exerciseId, ExerciseOutcome outcome) {
    switch (outcome) {
      case ExerciseOutcome.andataBene:
        _maturity[exerciseId] = 100.0;
        break;
      case ExerciseOutcome.cosiCosi:
        _maturity[exerciseId] = 50.0;
        break;
      case ExerciseOutcome.nonAncora:
        _masteredExerciseIds.remove(exerciseId);
        _maturity[exerciseId] = 30.0;
        break;
    }
    notifyListeners();
  }
}
