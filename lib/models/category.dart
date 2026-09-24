/// Le categorie di fondamenta usate per valutare il livello del
/// praticante e bilanciare l'allenamento, ispirate al modello "9
/// fondamenta indipendenti" (vedi docs/ARCHITETTURA.md, sezione 2):
/// invece di un punteggio unico, ogni categoria ha la propria scala di
/// livelli, perche' la forza/abilita' reale non e' mai uniforme tra un
/// movimento e l'altro.
enum FitnessCategory {
  spinta,
  trazione,
  coreFrontale,
  coreLaterale,
  corePosteriore,
  bodyline,
  gambe,
  flessibilita,
  equilibrio,
  acrobazie,
}

extension FitnessCategoryLabel on FitnessCategory {
  /// Etichetta in italiano da mostrare nell'interfaccia.
  String get label {
    switch (this) {
      case FitnessCategory.spinta:
        return 'Spinta';
      case FitnessCategory.trazione:
        return 'Trazione';
      case FitnessCategory.coreFrontale:
        return 'Core (frontale)';
      case FitnessCategory.coreLaterale:
        return 'Core (laterale)';
      case FitnessCategory.corePosteriore:
        return 'Core (posteriore)';
      case FitnessCategory.bodyline:
        return 'Bodyline';
      case FitnessCategory.gambe:
        return 'Gambe';
      case FitnessCategory.flessibilita:
        return 'Flessibilita\'';
      case FitnessCategory.equilibrio:
        return 'Equilibrio';
      case FitnessCategory.acrobazie:
        return 'Acrobazie';
    }
  }
}

/// Attrezzatura OLTRE al corpo che un esercizio puo' richiedere: un muro
/// libero, e/o una fascia elastica (niente piu' taniche/bottiglie). Il
/// corpo stesso non e' un valore qui: e' sempre disponibile per
/// definizione, quindi non e' mai un vincolo di filtro reale. Un insieme
/// VUOTO significa "solo corpo libero, nessun'altra attrezzatura". Un
/// esercizio puo' richiedere piu' di un elemento (es. "verticale al
/// muro" richiede Equipment.muro, oltre al corpo che e' sempre
/// implicito).
enum Equipment {
  muro,
  fasciaElastica,
}

extension EquipmentLabel on Equipment {
  String get label {
    switch (this) {
      case Equipment.muro:
        return 'Muro';
      case Equipment.fasciaElastica:
        return 'Fascia elastica';
    }
  }
}
