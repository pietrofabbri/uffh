/// I gruppi muscolari usati per etichettare quali muscoli allena ciascun
/// esercizio (vedi `Exercise.scores` in `exercise.dart`).
///
/// Elenco allineato alla tassonomia di
/// [free-exercise-db](https://github.com/yuhonas/free-exercise-db)
/// (docs/ARCHITETTURA.md sezione 3 — il dataset candidato per popolare il
/// database esercizi, vedi docs/ROADMAP.md punto 1), tradotta in
/// italiano: un futuro import può mappare `primaryMuscles`/
/// `secondaryMuscles` direttamente su questi valori invece di dover
/// inventare una tassonomia nuova. `dorsali` mappa il loro "lats"
/// (grande dorsale, il muscolo delle trazioni verticali); `dorsaliMedi`
/// mappa il loro "middle back" (romboidi/trapezio medio, il muscolo dei
/// rematori orizzontali) — due muscoli distinti, verificato sullo
/// schema.json del dataset il 2026-09-22.
enum Muscle {
  petto,
  dorsali,
  dorsaliMedi,
  trapezi,
  spalle,
  bicipiti,
  tricipiti,
  avambracci,
  addominali,
  lombari,
  glutei,
  quadricipiti,
  femorali,
  adduttori,
  abduttori,
  polpacci,
  collo,
}

extension MuscleLabel on Muscle {
  /// Etichetta in italiano da mostrare nell'interfaccia.
  String get label {
    switch (this) {
      case Muscle.petto:
        return 'Petto';
      case Muscle.dorsali:
        return 'Dorsali';
      case Muscle.dorsaliMedi:
        return 'Dorsali (medi)';
      case Muscle.trapezi:
        return 'Trapezi';
      case Muscle.spalle:
        return 'Spalle';
      case Muscle.bicipiti:
        return 'Bicipiti';
      case Muscle.tricipiti:
        return 'Tricipiti';
      case Muscle.avambracci:
        return 'Avambracci';
      case Muscle.addominali:
        return 'Addominali';
      case Muscle.lombari:
        return 'Lombari';
      case Muscle.glutei:
        return 'Glutei';
      case Muscle.quadricipiti:
        return 'Quadricipiti';
      case Muscle.femorali:
        return 'Femorali';
      case Muscle.adduttori:
        return 'Adduttori';
      case Muscle.abduttori:
        return 'Abduttori';
      case Muscle.polpacci:
        return 'Polpacci';
      case Muscle.collo:
        return 'Collo';
    }
  }
}
