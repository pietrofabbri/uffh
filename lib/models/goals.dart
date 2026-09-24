import 'package:flutter/foundation.dart';

import 'ability.dart';
import 'exercise.dart';
import 'muscle.dart';
import 'progress.dart';

/// Il peso che l'utente assegna a una coppia muscolo×abilità nei propri
/// obiettivi di allenamento (docs/ARCHITETTURA.md sezione 19). Non usa
/// direttamente la scala 0-3 di `Exercise.scores` (exercise.dart) per
/// restare leggibile in un menu, ma il confronto resta immediato:
/// [GoalsController.coverageOf] pesa ogni esercizio per il proprio
/// `scores[muscle][ability]`, indipendentemente dal peso obiettivo qui
/// impostato -- il peso serve solo a dire "questo mi interessa", non
/// entra nel calcolo di copertura.
enum GoalWeight { nessuna, bassa, media, alta }

extension GoalWeightLabel on GoalWeight {
  /// Etichetta in italiano da mostrare nell'interfaccia.
  String get label {
    switch (this) {
      case GoalWeight.nessuna:
        return 'Nessuna';
      case GoalWeight.bassa:
        return 'Bassa';
      case GoalWeight.media:
        return 'Media';
      case GoalWeight.alta:
        return 'Alta';
    }
  }
}

/// Un obiettivo specifico con nome (es. "Loto", "Verticale", "Spaccate")
/// e priorità (1 = massima), sul modello del vecchio piano scritto a
/// mano (progetto Claude, claude/piano-allenamento.md: "loto (priorità
/// 1)", "verticale (priorità 2)", ecc.). A differenza dei pesi
/// muscolo×abilità non è legato a dati oggettivi nel database esercizi
/// -- nessuna [GoalsController.coverageOf] è calcolabile per un
/// obiettivo con nome, perché non esiste ancora un modo di collegare
/// "Loto" a delle catene di esercizi specifiche (idea per un lavoro
/// futuro, non in questo giro). È solo un elenco ordinato di traguardi
/// per tenere a mente cosa viene prima.
@immutable
class NamedGoal {
  final String name;
  final int priority;

  const NamedGoal({required this.name, required this.priority});

  NamedGoal copyWith({String? name, int? priority}) => NamedGoal(
        name: name ?? this.name,
        priority: priority ?? this.priority,
      );
}

/// Obiettivi generali di allenamento (docs/ARCHITETTURA.md sezione 19):
/// DISACCOPPIATI dalla generazione delle sessioni A/B/C (non ancora
/// costruite, vedi docs/ROADMAP.md) -- servono solo a registrare COSA
/// si vuole raggiungere, in due forme complementari viste nel vecchio
/// piano scritto a mano (claude/piano-allenamento.md nel progetto
/// Claude):
///
/// 1. Pesi muscolo×abilità: "quanto conta allenare la forza sulle
///    spalle" -- confrontabile con `Exercise.scores` per calcolare una
///    copertura reale ([coverageOf]).
/// 2. Obiettivi specifici con nome e priorità ([NamedGoal]): traguardi
///    puntuali senza un corrispettivo diretto in una singola coppia
///    muscolo/abilità.
///
/// Stato solo in memoria, come [ProgressController]: non sopravvive
/// alla chiusura dell'app finché non arriva la persistenza locale
/// prevista in docs/ROADMAP.md.
class GoalsController extends ChangeNotifier {
  final Map<Muscle, Map<Ability, GoalWeight>> _weights;
  final List<NamedGoal> _namedGoals;

  GoalsController({
    Map<Muscle, Map<Ability, GoalWeight>>? weights,
    List<NamedGoal>? namedGoals,
  })  : _weights = {
          for (final entry in (weights ?? {}).entries)
            entry.key: {...entry.value},
        },
        _namedGoals = [...?namedGoals];

  GoalWeight weightOf(Muscle muscle, Ability ability) =>
      _weights[muscle]?[ability] ?? GoalWeight.nessuna;

  void setWeight(Muscle muscle, Ability ability, GoalWeight weight) {
    if (weight == GoalWeight.nessuna) {
      _weights[muscle]?.remove(ability);
    } else {
      _weights.putIfAbsent(muscle, () => {})[ability] = weight;
    }
    notifyListeners();
  }

  /// Elenco (in ordine di priorità: prima 1, poi 2, ...) degli obiettivi
  /// specifici impostati. Copia difensiva -- per modificare l'elenco
  /// usare [upsertNamedGoal]/[removeNamedGoal].
  List<NamedGoal> get namedGoals {
    final sorted = [..._namedGoals];
    sorted.sort((a, b) => a.priority.compareTo(b.priority));
    return List.unmodifiable(sorted);
  }

  /// Aggiunge un nuovo obiettivo specifico, o sostituisce quello
  /// esistente con lo stesso nome (case-insensitive, per evitare
  /// duplicati tipo "Loto"/"loto" creati per svista).
  void upsertNamedGoal(NamedGoal goal) {
    _namedGoals.removeWhere(
      (g) => g.name.toLowerCase() == goal.name.toLowerCase(),
    );
    _namedGoals.add(goal);
    notifyListeners();
  }

  void removeNamedGoal(String name) {
    final removed = _namedGoals.length;
    _namedGoals.removeWhere((g) => g.name.toLowerCase() == name.toLowerCase());
    if (_namedGoals.length != removed) notifyListeners();
  }

  /// Copertura 0-100% di una coppia muscolo/abilità: quanta parte della
  /// capacità allenabile per quella coppia nel database esercizi è già
  /// stata acquisita (docs/ARCHITETTURA.md sezione 19). Per ogni
  /// esercizio che allena la coppia (`scores[muscle][ability] > 0`) pesa
  /// il proprio contributo per il punteggio stesso, e conta come
  /// "raggiunto" solo se [ProgressController.isMastered] -- non usa
  /// [ProgressController.maturityOf] perché quel segnale riparte da 0
  /// ogni volta che si passa al prossimo esercizio della catena
  /// ([ProgressController.resolveUpgrade]), e darebbe quindi una
  /// copertura che scende anche quando si progredisce.
  ///
  /// Ritorna `null` se nessun esercizio nel database allena questa
  /// combinazione: "copertura non calcolabile", non "0% coperto" --
  /// sono informazioni diverse per l'utente.
  double? coverageOf(
    Muscle muscle,
    Ability ability,
    List<Exercise> allExercises,
    ProgressController progress,
  ) {
    var achieved = 0.0;
    var possible = 0.0;
    for (final exercise in allExercises) {
      final score = exercise.scores[muscle]?[ability] ?? 0;
      if (score <= 0) continue;
      possible += score;
      if (progress.isMastered(exercise)) achieved += score;
    }
    if (possible == 0) return null;
    return (achieved / possible) * 100;
  }

  /// Copertura media tra tutte le coppie muscolo/abilità con un peso
  /// impostato (> [GoalWeight.nessuna]) e per cui [coverageOf] è
  /// calcolabile. `null` se non c'è ancora nessun obiettivo impostato, o
  /// se nessuno degli obiettivi impostati ha esercizi corrispondenti nel
  /// database -- usata per il riepilogo in cima a [GoalsScreen].
  double? overallCoverage(List<Exercise> allExercises, ProgressController progress) {
    var total = 0.0;
    var count = 0;
    for (final muscle in _weights.keys) {
      for (final ability in _weights[muscle]!.keys) {
        final coverage = coverageOf(muscle, ability, allExercises, progress);
        if (coverage == null) continue;
        total += coverage;
        count++;
      }
    }
    if (count == 0) return null;
    return total / count;
  }

  /// Numero di coppie muscolo/abilità con un peso impostato (>
  /// [GoalWeight.nessuna]), per il riepilogo in [GoalsScreen].
  int get activeWeightCount {
    var count = 0;
    for (final abilities in _weights.values) {
      count += abilities.values.where((w) => w != GoalWeight.nessuna).length;
    }
    return count;
  }
}
