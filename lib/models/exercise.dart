import 'category.dart';

/// Un esercizio nell'albero di progressione. Ogni esercizio appartiene a
/// UNA categoria di fondamenta e puo' avere un prerequisito (l'esercizio
/// che, secondo il piano, va padroneggiato prima di questo) — lo stesso
/// pattern "categoria x livelli x prerequisiti" descritto in
/// docs/ARCHITETTURA.md, sezione 2, invece delle scalette isolate per
/// singolo esercizio del vecchio piano.
class Exercise {
  final String id;
  final String name;
  final FitnessCategory category;
  final Set<Equipment> equipment;

  /// Livello di difficolta' relativo all'interno della categoria (0 =
  /// piu' semplice). Non e' un valore assoluto tra categorie diverse:
  /// "spinta livello 2" e "gambe livello 2" non sono necessariamente
  /// paragonabili.
  final int level;

  /// id di un altro [Exercise] da padroneggiare prima di questo, se
  /// esiste (null per i movimenti di base senza prerequisiti).
  final String? prerequisiteId;

  /// Indicazione di forma (come si esegue), sintetica.
  final String cue;

  /// Errori comuni/best practice, in stile "poche righe, molto concrete"
  /// (vedi il vecchio TIPS in app-allenamento-stato.md — lo stesso
  /// principio, non lo stesso contenuto: qui vanno riscritti per la
  /// nuova attrezzatura).
  final List<String> tips;

  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.equipment,
    required this.level,
    this.prerequisiteId,
    this.cue = '',
    this.tips = const [],
  });
}

/// Seed MINIMO, solo per validare la pipeline di build e la forma dei
/// dati — non e' ancora il database di esercizi reale. Il prossimo passo
/// (vedi docs/ROADMAP.md) e' importare/mappare un set piu' ampio,
/// coerente con pavimento + muro + fascia elastica, eventualmente a
/// partire dai dataset pubblici citati in
/// docs/FONTI-ED-EQUIPAGGIAMENTO.md.
const List<Exercise> seedExercises = [
  Exercise(
    id: 'pushup-ginocchia',
    name: 'Piegamento sulle ginocchia',
    category: FitnessCategory.spinta,
    equipment: {Equipment.corpoLibero},
    level: 0,
    cue: 'Corpo allineato dalle ginocchia alla testa, scendi controllato.',
    tips: [
      'Non far cadere il bacino durante la discesa',
      'Gomiti a circa 45 gradi dal busto, non larghi',
    ],
  ),
  Exercise(
    id: 'pushup-standard',
    name: 'Piegamento standard',
    category: FitnessCategory.spinta,
    equipment: {Equipment.corpoLibero},
    level: 1,
    prerequisiteId: 'pushup-ginocchia',
    cue: 'Corpo rigido dalla testa ai talloni, petto verso terra.',
    tips: [
      'Se il bacino cede, torna al livello precedente qualche settimana',
    ],
  ),
  Exercise(
    id: 'rematore-fascia',
    name: 'Rematore con fascia elastica',
    category: FitnessCategory.trazione,
    equipment: {Equipment.fasciaElastica},
    level: 0,
    cue: 'Fascia ancorata davanti, tira i gomiti indietro, scapole strette.',
    tips: [
      'Sostituisce il vecchio "rematore con taniche": stessa forma, '
          'resistenza dalla fascia invece che dal peso',
    ],
  ),
  Exercise(
    id: 'verticale-al-muro',
    name: 'Verticale al muro',
    category: FitnessCategory.equilibrio,
    equipment: {Equipment.corpoLibero, Equipment.muro},
    level: 1,
    cue: 'Pancia rivolta al muro, spalle spinte in alto, impilati sopra le mani.',
    tips: ['Cadi verso il muro? Sei partito troppo lontano dal muro'],
  ),
];
