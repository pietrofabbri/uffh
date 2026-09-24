/// Le abilità fisiche che un esercizio può allenare in un [Muscle] (vedi
/// `Exercise.scores` in `exercise.dart`).
///
/// Non è "quanto è difficile" l'esercizio — quello resta `Exercise.level`
/// dentro la sua `FitnessCategory` (categoria.dart), pensato per ordinare
/// la progressione dentro una singola catena. [Ability] è ortogonale:
/// "che TIPO di capacità sviluppa, e in che muscolo" — utile per capire se
/// la programmazione sta trascurando un'abilità su un muscolo (es. "sto
/// facendo tanta forza sulle gambe ma zero equilibrio") e per le catene
/// propedeutiche che convergono su un obiettivo come la verticale o la
/// spaccata (docs/ARCHITETTURA.md, sezione 10).
enum Ability {
  forza,
  flessibilita,
  equilibrio,
  coordinazione,
}

extension AbilityLabel on Ability {
  /// Etichetta in italiano da mostrare nell'interfaccia.
  String get label {
    switch (this) {
      case Ability.forza:
        return 'Forza';
      case Ability.flessibilita:
        return 'Flessibilità';
      case Ability.equilibrio:
        return 'Equilibrio';
      case Ability.coordinazione:
        return 'Coordinazione';
    }
  }
}
