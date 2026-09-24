import 'ability.dart';
import 'category.dart';
import 'muscle.dart';

/// Un esercizio nell'albero di progressione. Ogni esercizio appartiene a
/// UNA categoria di fondamenta (per l'organizzazione in schermate) e può
/// avere uno o più prerequisiti — lo stesso pattern "categoria x livelli x
/// prerequisiti" descritto in docs/ARCHITETTURA.md, sezione 2, esteso a un
/// grafo vero (non solo una catena) da docs/ARCHITETTURA.md sezione 10:
/// un esercizio con PIÙ prerequisiti richiede che siano TUTTI acquisiti
/// prima di sbloccarsi — necessario per obiettivi composti come la
/// verticale libera, che ha bisogno sia di un prerequisito di equilibrio
/// sia di uno di forza spinta (vedi [seedExercises] sotto,
/// `verticale-libera`), che possono benissimo stare in categorie diverse.
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

  /// id di altri [Exercise] da padroneggiare TUTTI prima di questo
  /// (insieme vuoto per i movimenti di base senza prerequisiti). Possono
  /// appartenere a categorie diverse da questo esercizio — vedi la
  /// docstring della classe.
  final Set<String> prerequisiteIds;

  /// Quanto questo esercizio allena ciascuna [Ability] in ciascun
  /// [Muscle] coinvolto, su una scala 0-3 (0 = non presente/trascurabile,
  /// 3 = lavoro primario e intenso). Non tutti i muscoli/abilità vanno
  /// elencati: quelli assenti dalla mappa valgono implicitamente 0.
  ///
  /// Serve a due cose ortogonali a categoria/livello:
  /// [ProgressController.abilityScoreFor] (lib/models/progress.dart) somma
  /// questi punteggi tra gli esercizi acquisiti per rispondere "quanta
  /// forza/flessibilità/equilibrio/coordinazione ho costruito su questo
  /// muscolo", indipendentemente da quale categoria/catena ha portato
  /// quel lavoro.
  final Map<Muscle, Map<Ability, int>> scores;

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
    this.prerequisiteIds = const {},
    this.scores = const {},
    this.cue = '',
    this.tips = const [],
  });
}

/// Esercizi curati a mano ("programmati", vedi docs/ARCHITETTURA.md
/// sezione 11): entrano nel motore di progressione e nella generazione
/// di sedute, con `scores`/`prerequisiteIds` reali. Le catene equilibrio
/// (verticale, crow/crane pose, elbow lever), flessibilita' (loto,
/// spaccate), acrobazie, core frontale (L-sit, dragon flag), core
/// posteriore (ponte/wheel pose), spinta (push-up, planche, handstand
/// push-up) e gambe (pistol squat) sono complete dalla base al traguardo
/// (2026-09-22, estese il 2026-09-23, ulteriormente frammentate con più
/// step intermedi il 2026-09-23 su richiesta esplicita di Pietro, vedi
/// docs/ARCHITETTURA.md sezione 17 -- fonti in
/// `ricerca-fondamenta-redesign.md` del progetto Claude, sezioni 3-4 e
/// 8a). Trazione, core laterale e bodyline restano ridotte/vuote: quel
/// volume e' il lavoro del "catalogo" importato meccanicamente
/// (`tool/import_free_exercise_db.dart`,
/// `lib/data/catalog_exercises.dart`), non di questa lista curata a mano.
const List<Exercise> seedExercises = [
  Exercise(
    id: 'pushup-ginocchia',
    name: 'Piegamento sulle ginocchia',
    category: FitnessCategory.spinta,
    equipment: {},
    level: 0,
    scores: {
      Muscle.petto: {Ability.forza: 2},
      Muscle.tricipiti: {Ability.forza: 1},
      Muscle.spalle: {Ability.forza: 1},
    },
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
    equipment: {},
    level: 1,
    prerequisiteIds: {'pushup-ginocchia'},
    scores: {
      Muscle.petto: {Ability.forza: 3},
      Muscle.tricipiti: {Ability.forza: 2},
      Muscle.spalle: {Ability.forza: 2},
      Muscle.addominali: {Ability.forza: 1},
    },
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
    scores: {
      Muscle.dorsali: {Ability.forza: 2},
      Muscle.bicipiti: {Ability.forza: 1},
      Muscle.trapezi: {Ability.forza: 1},
    },
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
    equipment: {Equipment.muro},
    level: 1,
    prerequisiteIds: {'verticale-wall-walk'},
    scores: {
      Muscle.spalle: {Ability.forza: 2, Ability.equilibrio: 2},
      Muscle.addominali: {Ability.forza: 1, Ability.equilibrio: 1},
      Muscle.avambracci: {Ability.equilibrio: 1},
    },
    cue: 'Pancia rivolta al muro, spalle spinte in alto, impilati sopra le mani.',
    tips: ['Cadi verso il muro? Sei partito troppo lontano dal muro'],
  ),
  // Dimostra un obiettivo composto (docs/ARCHITETTURA.md, sezione 10):
  // richiede ENTRAMBI i prerequisiti, uno di equilibrio (verticale al
  // muro) e uno di forza spinta (piegamento standard), da due categorie
  // diverse — esattamente l'esempio "la verticale richiede sia forza
  // spalle sia equilibrio" che ha motivato il passaggio a più
  // prerequisiti.
  Exercise(
    id: 'verticale-libera',
    name: 'Verticale libera',
    category: FitnessCategory.equilibrio,
    equipment: {},
    level: 4,
    prerequisiteIds: {'verticale-kick-up-al-muro', 'pushup-standard'},
    scores: {
      Muscle.spalle: {Ability.forza: 3, Ability.equilibrio: 3},
      Muscle.addominali: {Ability.forza: 2, Ability.equilibrio: 1},
      Muscle.avambracci: {Ability.equilibrio: 2},
    },
    cue: 'Stacco controllato dal muro, sguardo tra le mani, cerca l\'equilibrio prima di allungare le gambe.',
    tips: [
      'Fai prima molte "punte" (stacco breve, tocca e riscendi) prima di cercare tempi lunghi',
      'Se cadi sempre dalla stessa parte, correggi la spinta delle mani prima ancora del bacino',
    ],
  ),

  // --- Catena verticale (equilibrio): wall walk -> kick-up, aggiunta
  // 2026-09-22. verticale-al-muro e verticale-libera sopra restano gli
  // estremi della catena, con prerequisiteIds aggiornati di conseguenza.
  Exercise(
    id: 'verticale-wall-walk',
    name: 'Wall walk',
    category: FitnessCategory.equilibrio,
    equipment: {Equipment.muro},
    level: 0,
    scores: {
      Muscle.spalle: {Ability.forza: 1, Ability.equilibrio: 1},
      Muscle.addominali: {Ability.forza: 1},
    },
    cue: 'Parti in plank con i piedi al muro, cammina con le mani indietro '
        'mentre i piedi salgono lungo la parete.',
    tips: [
      'Fermati appena la posizione non è più controllata, non serve arrivare in cima subito',
      'Prepara i polsi con qualche rotazione prima di iniziare',
    ],
  ),
  Exercise(
    id: 'verticale-shoulder-taps',
    name: 'Verticale al muro con tap alle spalle',
    category: FitnessCategory.equilibrio,
    equipment: {Equipment.muro},
    level: 2,
    prerequisiteIds: {'verticale-al-muro'},
    scores: {
      Muscle.spalle: {Ability.forza: 2, Ability.equilibrio: 3},
      Muscle.addominali: {Ability.forza: 1, Ability.equilibrio: 2},
      Muscle.avambracci: {Ability.equilibrio: 2},
    },
    cue: 'In verticale al muro, sposta il peso su una mano e tocca la '
        'spalla opposta con l\'altra, alternando.',
    tips: [
      'Se il bacino si stacca dal muro mentre tocchi la spalla, il peso non è ancora abbastanza sulle mani',
    ],
  ),
  Exercise(
    id: 'verticale-kick-up-al-muro',
    name: 'Kick-up in verticale al muro',
    category: FitnessCategory.equilibrio,
    equipment: {Equipment.muro},
    level: 3,
    prerequisiteIds: {'verticale-shoulder-taps'},
    scores: {
      Muscle.spalle: {Ability.forza: 2, Ability.equilibrio: 3},
      Muscle.addominali: {Ability.forza: 2, Ability.equilibrio: 2},
      Muscle.quadricipiti: {Ability.coordinazione: 1},
    },
    cue: 'Mani a terra vicino al muro, una gamba sale con uno slancio '
        'controllato, l\'altra segue: la schiena verso il muro fa da rete di sicurezza.',
    tips: [
      'Lavora prima molte "punte" (sali e riscendi subito) prima di cercare di reggere il tempo',
      'Il muro qui è un paracadute, non un appoggio: l\'obiettivo è non toccarlo',
    ],
  ),

  // --- Catena loto (flessibilità), da piano-allenamento.md, trascritta 2026-09-22 ---
  Exercise(
    id: 'anche-90-90',
    name: '90/90 transitions',
    category: FitnessCategory.flessibilita,
    equipment: {},
    level: 0,
    scores: {
      Muscle.adduttori: {Ability.flessibilita: 2},
      Muscle.glutei: {Ability.flessibilita: 1},
    },
    cue: 'Seduto, una gamba piegata davanti a 90°, l\'altra piegata dietro '
        'a 90°: passa da un lato all\'altro con controllo.',
    tips: ['Tieni il busto eretto durante la transizione, non serve schiacciarsi in avanti'],
  ),
  Exercise(
    id: 'loto-half-passivo',
    name: 'Half lotus passivo',
    category: FitnessCategory.flessibilita,
    equipment: {},
    level: 1,
    prerequisiteIds: {'anche-90-90'},
    scores: {
      Muscle.adduttori: {Ability.flessibilita: 2},
      Muscle.glutei: {Ability.flessibilita: 2},
    },
    cue: 'Un piede sulla coscia opposta, tieni la posizione aiutandoti con '
        'le mani, senza forzare il ginocchio.',
    tips: ['Il dolore va fermato subito: qui si lavora sul range, non sulla resistenza al dolore'],
  ),
  Exercise(
    id: 'loto-half-attivo',
    name: 'Half lotus attivo senza mani',
    category: FitnessCategory.flessibilita,
    equipment: {},
    level: 2,
    prerequisiteIds: {'loto-half-passivo'},
    scores: {
      Muscle.adduttori: {Ability.flessibilita: 2, Ability.equilibrio: 1},
      Muscle.addominali: {Ability.forza: 1},
    },
    cue: 'Stessa posizione dell\'half lotus, ma reggi 3×20s per lato senza aiutarti con le mani.',
    tips: ['Se cadi subito, torna alla versione passiva ancora qualche settimana'],
  ),
  Exercise(
    id: 'loto-assistito',
    name: 'Lotus assistito',
    category: FitnessCategory.flessibilita,
    equipment: {},
    level: 3,
    prerequisiteIds: {'loto-half-attivo'},
    scores: {
      Muscle.adduttori: {Ability.flessibilita: 3},
      Muscle.glutei: {Ability.flessibilita: 1},
    },
    cue: 'Entrambi i piedi sulle cosce opposte, aiutandoti con le mani per posizionarli.',
    tips: ['Entra ed esci con calma: è il momento in cui il ginocchio è più esposto'],
  ),
  Exercise(
    id: 'loto-completo',
    name: 'Lotus completo',
    category: FitnessCategory.flessibilita,
    equipment: {},
    level: 4,
    prerequisiteIds: {'loto-assistito'},
    scores: {
      Muscle.adduttori: {Ability.flessibilita: 3},
      Muscle.glutei: {Ability.flessibilita: 2},
    },
    cue: 'Entrambi i piedi sulle cosce opposte, mani libere, colonna eretta.',
    tips: ['Alterna quale gamba va sopra tra una seduta e l\'altra, se possibile'],
  ),

  // --- Catena spaccate (flessibilità), da piano-allenamento.md, trascritta 2026-09-22 ---
  Exercise(
    id: 'spaccata-affondo',
    name: 'Affondo profondo e half split',
    category: FitnessCategory.flessibilita,
    equipment: {},
    level: 0,
    scores: {
      Muscle.femorali: {Ability.flessibilita: 2},
      Muscle.adduttori: {Ability.flessibilita: 1},
    },
    cue: 'Affondo profondo, poi distendi la gamba davanti mantenendo il '
        'bacino basso (half split).',
    tips: ['Le anche restano quadrate verso avanti, non ruotate'],
  ),
  Exercise(
    id: 'spaccata-isometrie',
    name: 'Isometrie di spaccata',
    category: FitnessCategory.flessibilita,
    equipment: {},
    level: 1,
    prerequisiteIds: {'spaccata-affondo'},
    scores: {
      Muscle.femorali: {Ability.flessibilita: 2},
      Muscle.adduttori: {Ability.flessibilita: 2},
    },
    cue: 'Nella posizione più profonda che riesci a tenere comoda, '
        '"trascina" i piedi verso il centro senza muoverli, 5-10s.',
    tips: ['La contrazione isometrica prepara il range successivo, non serve spingere oltre il comodo'],
  ),
  Exercise(
    id: 'spaccata-range-profondo',
    name: 'Spaccata: range più profondo',
    category: FitnessCategory.flessibilita,
    equipment: {},
    level: 2,
    prerequisiteIds: {'spaccata-isometrie'},
    scores: {
      Muscle.femorali: {Ability.flessibilita: 3},
      Muscle.adduttori: {Ability.flessibilita: 2},
    },
    cue: 'Stessa progressione di affondo/isometria, ma cercando qualche '
        'centimetro in più ogni settimana.',
    tips: ['Un centimetro alla settimana è un buon ritmo: qui la fretta è controproducente'],
  ),
  Exercise(
    id: 'spaccata-assistita',
    name: 'Spaccata assistita',
    category: FitnessCategory.flessibilita,
    equipment: {},
    level: 3,
    prerequisiteIds: {'spaccata-range-profondo'},
    scores: {
      Muscle.femorali: {Ability.flessibilita: 3},
      Muscle.adduttori: {Ability.flessibilita: 2},
    },
    cue: 'Spaccata con le mani a terra o su rialzi a fare da appoggio, '
        'bacino verso il pavimento.',
    tips: ['Usa gli appoggi per controllare la discesa, non per lasciarti cadere'],
  ),
  Exercise(
    id: 'spaccata-completa',
    name: 'Spaccata completa',
    category: FitnessCategory.flessibilita,
    equipment: {},
    level: 4,
    prerequisiteIds: {'spaccata-assistita'},
    scores: {
      Muscle.femorali: {Ability.flessibilita: 3},
      Muscle.adduttori: {Ability.flessibilita: 3},
      Muscle.glutei: {Ability.flessibilita: 1},
    },
    cue: 'Bacino a terra, gambe completamente distese in linea, busto eretto.',
    tips: ['Allena entrambi i lati anche dopo aver raggiunto il primo: restano spesso asimmetrici'],
  ),

  // --- Catena acrobazie (nuova FitnessCategory, decisa il 2026-09-22) ---
  Exercise(
    id: 'acrobazie-animal-flow',
    name: 'Animal flow (bear, crab, kick-through)',
    category: FitnessCategory.acrobazie,
    equipment: {},
    level: 0,
    scores: {
      Muscle.spalle: {Ability.coordinazione: 2, Ability.forza: 1},
      Muscle.addominali: {Ability.coordinazione: 1, Ability.forza: 1},
      Muscle.quadricipiti: {Ability.coordinazione: 1},
    },
    cue: 'Cammina in posizione "bear" (mani e piedi, ginocchia sollevate), '
        'ruota in "crab" (pancia in su), poi kick-through da un lato all\'altro.',
    tips: ['Movimento libero, non a ripetizioni: cerca fluidità nelle transizioni'],
  ),
  Exercise(
    id: 'acrobazie-cartwheel-prep',
    name: 'Cartwheel prep',
    category: FitnessCategory.acrobazie,
    equipment: {},
    level: 1,
    prerequisiteIds: {'acrobazie-animal-flow'},
    scores: {
      Muscle.spalle: {Ability.forza: 1, Ability.coordinazione: 2},
      Muscle.addominali: {Ability.coordinazione: 1},
      Muscle.avambracci: {Ability.forza: 1},
    },
    cue: 'Mani a terra una dopo l\'altra, trasferisci il peso e solleva '
        'una gamba, poi torna giù controllato, senza completare la rotazione.',
    tips: ['Fallo su un tappetino o erba, non su pavimento duro, finché il controllo non è solido'],
  ),
  Exercise(
    id: 'acrobazie-kick-up-laterale',
    name: 'Kick-up laterale controllato',
    category: FitnessCategory.acrobazie,
    equipment: {},
    level: 2,
    prerequisiteIds: {'acrobazie-cartwheel-prep'},
    scores: {
      Muscle.spalle: {Ability.forza: 1, Ability.coordinazione: 2},
      Muscle.quadricipiti: {Ability.coordinazione: 2},
      Muscle.glutei: {Ability.coordinazione: 1},
    },
    cue: 'Come il cartwheel prep, ma con più slancio: la gamba che sale '
        'arriva quasi verticale prima di ridiscendere.',
    tips: ['Se non sei sicuro dell\'atterraggio, valuta prima con qualcuno che ti guardi'],
  ),
  Exercise(
    id: 'acrobazie-ruota',
    name: 'Ruota completa',
    category: FitnessCategory.acrobazie,
    equipment: {},
    level: 3,
    prerequisiteIds: {'acrobazie-kick-up-laterale'},
    scores: {
      Muscle.spalle: {Ability.forza: 2, Ability.coordinazione: 3},
      Muscle.addominali: {Ability.coordinazione: 2},
      Muscle.quadricipiti: {Ability.coordinazione: 2},
      Muscle.avambracci: {Ability.forza: 1},
    },
    cue: 'Mano-mano-piede-piede in sequenza fluida, corpo che ruota '
        'lateralmente passando per la verticale.',
    tips: [
      'Skill più impegnativa: valuta prima con qualcuno che ti guardi/faccia da spotter, non da solo su pavimento normale',
    ],
  ),

  // --- Catena push avanzata: pike push-up, planche e handstand push-up
  // (spinta), aggiunta 2026-09-23. Planche e HSPU si diramano entrambe da
  // pushup-standard; hspu-negativa e' un obiettivo composto (docs/
  // ARCHITETTURA.md sezione 10) che richiede sia pike-pushup (spinta) sia
  // verticale-al-muro (equilibrio) — stesso pattern di verticale-libera.
  Exercise(
    id: 'pike-pushup',
    name: 'Piegamento a V (pike push-up)',
    category: FitnessCategory.spinta,
    equipment: {},
    level: 2,
    prerequisiteIds: {'pushup-standard'},
    scores: {
      Muscle.spalle: {Ability.forza: 2},
      Muscle.tricipiti: {Ability.forza: 1},
      Muscle.petto: {Ability.forza: 1},
    },
    cue: 'A V rovesciata (bacino alto), piega i gomiti portando la testa '
        'verso il pavimento tra le mani.',
    tips: [
      'Più i piedi sono vicini alle mani, più il lavoro si sposta sulle spalle',
      'Tieni le braccia a circa 45 gradi dal busto, non larghe',
    ],
  ),
  Exercise(
    id: 'planche-lean',
    name: 'Planche lean',
    category: FitnessCategory.spinta,
    equipment: {},
    level: 2,
    prerequisiteIds: {'pushup-standard'},
    scores: {
      Muscle.spalle: {Ability.forza: 2},
      Muscle.petto: {Ability.forza: 1},
      Muscle.avambracci: {Ability.forza: 1},
      Muscle.addominali: {Ability.forza: 1},
    },
    cue: 'In appoggio su mani e piedi, spingi le spalle oltre le mani '
        'mantenendo braccia tese e scapole spinte in basso.',
    tips: [
      'Il peso extra sui polsi va introdotto gradualmente: pochi secondi alla volta all\'inizio',
      'Bacino e spalle restano allineati, non incurvare la schiena',
    ],
  ),
  Exercise(
    id: 'pike-pushup-rialzato',
    name: 'Piegamento a V con piedi rialzati',
    category: FitnessCategory.spinta,
    equipment: {},
    level: 3,
    prerequisiteIds: {'pike-pushup'},
    scores: {
      Muscle.spalle: {Ability.forza: 3},
      Muscle.tricipiti: {Ability.forza: 1},
      Muscle.petto: {Ability.forza: 1},
      Muscle.addominali: {Ability.equilibrio: 1},
    },
    cue: 'Come il pike push-up, ma con i piedi appoggiati su un rialzo '
        '(sedia, gradino): più il bacino è alto, più il lavoro si '
        'avvicina a quello della verticale.',
    tips: [
      'Aumenta l\'altezza del rialzo gradualmente: anche pochi centimetri cambiano molto il carico sulle spalle',
      'Le mani restano più larghe delle spalle di circa una spanna',
    ],
  ),

  Exercise(
    id: 'hspu-negativa',
    name: 'Handstand push-up negativa al muro',
    category: FitnessCategory.spinta,
    equipment: {Equipment.muro},
    level: 4,
    prerequisiteIds: {'pike-pushup-rialzato', 'verticale-al-muro'},
    scores: {
      Muscle.spalle: {Ability.forza: 3, Ability.equilibrio: 2},
      Muscle.tricipiti: {Ability.forza: 2},
      Muscle.addominali: {Ability.equilibrio: 1},
    },
    cue: 'In verticale al muro, piega lentamente i gomiti abbassando la '
        'testa verso terra, poi torna giù in sicurezza senza spingere su.',
    tips: [
      'Solo la discesa è controllata: risali togliendo prima i piedi dal muro, o aiutandoti',
      'Fermati appena senti perdere il controllo della testa, non serve arrivare a terra i primi tempi',
    ],
  ),
  Exercise(
    id: 'planche-lean-avanzata',
    name: 'Planche lean avanzata',
    category: FitnessCategory.spinta,
    equipment: {},
    level: 3,
    prerequisiteIds: {'planche-lean'},
    scores: {
      Muscle.spalle: {Ability.forza: 3},
      Muscle.petto: {Ability.forza: 1},
      Muscle.avambracci: {Ability.forza: 2},
      Muscle.addominali: {Ability.forza: 1},
    },
    cue: 'Stessa posizione del planche lean, ma sposta le spalle più in '
        'avanti oltre le mani e allunga il tempo di tenuta.',
    tips: [
      'È lo stesso esercizio del lean, solo più inclinato e più a lungo: non serve imparare una posizione nuova',
      'Se i polsi si affaticano prima delle spalle, accorcia la serie invece di allentare la posizione',
    ],
  ),

  Exercise(
    id: 'planche-tuck',
    name: 'Tuck planche',
    category: FitnessCategory.spinta,
    equipment: {},
    level: 4,
    prerequisiteIds: {'planche-lean-avanzata'},
    scores: {
      Muscle.spalle: {Ability.forza: 2, Ability.equilibrio: 2},
      Muscle.addominali: {Ability.forza: 2, Ability.equilibrio: 1},
      Muscle.avambracci: {Ability.forza: 1},
    },
    cue: 'Ginocchia al petto, piedi sollevati da terra, bacino sopra le '
        'mani: bilanciati sulle braccia tese.',
    tips: [
      'Le anche restano più alte delle spalle: se scendono, il peso torna sui piedi',
      'Pochi secondi per volta, la tenuta cresce con la pratica',
    ],
  ),
  Exercise(
    id: 'hspu-parziale',
    name: 'Handstand push-up parziale al muro',
    category: FitnessCategory.spinta,
    equipment: {Equipment.muro},
    level: 5,
    prerequisiteIds: {'hspu-negativa'},
    scores: {
      Muscle.spalle: {Ability.forza: 3, Ability.equilibrio: 2},
      Muscle.tricipiti: {Ability.forza: 3},
      Muscle.addominali: {Ability.equilibrio: 1},
    },
    cue: 'Scendi come nella negativa, ma risali solo per l\'ultima metà '
        'del percorso invece di fermarti in basso.',
    tips: [
      'La parte finale della risalita, vicino alla verticale, è la più semplice: costruisci da lì verso il basso',
    ],
  ),

  Exercise(
    id: 'hspu-completa',
    name: 'Handstand push-up completa al muro',
    category: FitnessCategory.spinta,
    equipment: {Equipment.muro},
    level: 6,
    prerequisiteIds: {'hspu-parziale'},
    scores: {
      Muscle.spalle: {Ability.forza: 3, Ability.equilibrio: 2},
      Muscle.tricipiti: {Ability.forza: 3},
      Muscle.addominali: {Ability.equilibrio: 1},
    },
    cue: 'Stessa posizione della negativa, ma risali spingendo con le '
        'braccia fino a distenderle di nuovo.',
    tips: [
      'Se non risali dal fondo, lavora ancora sulle negative e su qualche ripetizione parziale',
    ],
  ),
  Exercise(
    id: 'planche-tuck-avanzata',
    name: 'Advanced tuck planche',
    category: FitnessCategory.spinta,
    equipment: {},
    level: 5,
    prerequisiteIds: {'planche-tuck'},
    scores: {
      Muscle.spalle: {Ability.forza: 3, Ability.equilibrio: 2},
      Muscle.addominali: {Ability.forza: 2, Ability.equilibrio: 2},
      Muscle.avambracci: {Ability.forza: 2},
    },
    cue: 'Come il tuck planche, ma allontana le ginocchia dal petto: '
        'cosce quasi parallele al pavimento.',
    tips: ['Sposta il peso più in avanti sulle mani rispetto al tuck base'],
  ),
  Exercise(
    id: 'planche-una-gamba',
    name: 'Planche a una gamba',
    category: FitnessCategory.spinta,
    equipment: {},
    level: 6,
    prerequisiteIds: {'planche-tuck-avanzata'},
    scores: {
      Muscle.spalle: {Ability.forza: 3, Ability.equilibrio: 3},
      Muscle.addominali: {Ability.forza: 3, Ability.equilibrio: 2},
      Muscle.avambracci: {Ability.forza: 2},
    },
    cue: 'Dalla advanced tuck, distendi una sola gamba mantenendo '
        'l\'altra piegata al petto.',
    tips: ['Alterna la gamba distesa tra una serie e l\'altra'],
  ),

  Exercise(
    id: 'planche-straddle',
    name: 'Straddle planche',
    category: FitnessCategory.spinta,
    equipment: {},
    level: 7,
    prerequisiteIds: {'planche-una-gamba'},
    scores: {
      Muscle.spalle: {Ability.forza: 3, Ability.equilibrio: 3},
      Muscle.addominali: {Ability.forza: 3, Ability.equilibrio: 2},
      Muscle.avambracci: {Ability.forza: 2},
      Muscle.adduttori: {Ability.flessibilita: 1},
    },
    cue: 'Gambe distese e aperte a V, corpo il più parallelo possibile al '
        'pavimento.',
    tips: [
      'Le gambe aperte spostano il baricentro e alleggeriscono il lavoro rispetto alla planche a gambe unite: è una tappa intermedia, non un vicolo cieco',
    ],
  ),
  Exercise(
    id: 'planche-completa',
    name: 'Planche completa',
    category: FitnessCategory.spinta,
    equipment: {},
    level: 8,
    prerequisiteIds: {'planche-straddle'},
    scores: {
      Muscle.spalle: {Ability.forza: 3, Ability.equilibrio: 3},
      Muscle.petto: {Ability.forza: 2},
      Muscle.addominali: {Ability.forza: 3, Ability.equilibrio: 3},
      Muscle.avambracci: {Ability.forza: 3},
      Muscle.tricipiti: {Ability.forza: 2},
    },
    cue: 'Gambe distese e unite, corpo parallelo al pavimento, sostenuto '
        'solo dalle braccia tese.',
    tips: [
      'Chiudere le gambe dopo la straddle richiede settimane/mesi: è normale restare a lungo su questo passaggio',
    ],
  ),

  // --- Catena pistol squat (gambe), aggiunta 2026-09-23. Prima catena
  // per questa categoria, finora vuota. ---
  Exercise(
    id: 'squat-assistito',
    name: 'Squat assistito',
    category: FitnessCategory.gambe,
    equipment: {},
    level: 0,
    scores: {
      Muscle.quadricipiti: {Ability.forza: 2},
      Muscle.glutei: {Ability.forza: 1},
    },
    cue: 'Squat completo tenendoti con una mano a un appoggio stabile '
        '(stipite, sedia), talloni a terra.',
    tips: ['Usa l\'appoggio solo per l\'equilibrio, non per tirarti su con le braccia'],
  ),
  Exercise(
    id: 'squat-bulgaro',
    name: 'Squat bulgaro',
    category: FitnessCategory.gambe,
    equipment: {},
    level: 1,
    prerequisiteIds: {'squat-assistito'},
    scores: {
      Muscle.quadricipiti: {Ability.forza: 2},
      Muscle.glutei: {Ability.forza: 2},
      Muscle.femorali: {Ability.forza: 1},
      Muscle.addominali: {Ability.equilibrio: 1},
    },
    cue: 'Piede posteriore rialzato dietro di te, scendi con la gamba '
        'davanti fino a sfiorare il ginocchio dietro a terra.',
    tips: ['Il busto resta quasi verticale, non inclinarti troppo in avanti'],
  ),
  Exercise(
    id: 'pistol-squat-su-rialzo',
    name: 'Pistol squat su rialzo (box pistol)',
    category: FitnessCategory.gambe,
    equipment: {},
    level: 2,
    prerequisiteIds: {'squat-bulgaro'},
    scores: {
      Muscle.quadricipiti: {Ability.forza: 2},
      Muscle.glutei: {Ability.forza: 2},
      Muscle.addominali: {Ability.equilibrio: 1},
    },
    cue: 'Una gamba distesa davanti, scendi senza mani fino a sederti '
        'su un rialzo (sedia, gradino), poi risali senza aiuto.',
    tips: [
      'Abbassa l\'altezza del rialzo mano a mano che diventa facile, verso il pistol assistito',
    ],
  ),

  Exercise(
    id: 'pistol-squat-assistito',
    name: 'Pistol squat assistito',
    category: FitnessCategory.gambe,
    equipment: {},
    level: 3,
    prerequisiteIds: {'pistol-squat-su-rialzo'},
    scores: {
      Muscle.quadricipiti: {Ability.forza: 3},
      Muscle.glutei: {Ability.forza: 2},
      Muscle.addominali: {Ability.equilibrio: 2},
      Muscle.abduttori: {Ability.equilibrio: 1},
    },
    cue: 'Una gamba distesa davanti, scendi tenendoti con le mani a un '
        'supporto fino in fondo.',
    tips: ['Il tallone della gamba di appoggio resta a terra per tutta la discesa'],
  ),
  Exercise(
    id: 'pistol-squat-parziale',
    name: 'Pistol squat parziale',
    category: FitnessCategory.gambe,
    equipment: {},
    level: 4,
    prerequisiteIds: {'pistol-squat-assistito'},
    scores: {
      Muscle.quadricipiti: {Ability.forza: 3},
      Muscle.glutei: {Ability.forza: 2},
      Muscle.addominali: {Ability.equilibrio: 2},
    },
    cue: 'Senza supporto, scendi solo fino a metà percorso e risali, '
        'senza toccare terra con i glutei.',
    tips: ['Il range aumenta con la pratica: non forzare la profondità'],
  ),

  Exercise(
    id: 'pistol-squat-negativo',
    name: 'Pistol squat negativo',
    category: FitnessCategory.gambe,
    equipment: {},
    level: 5,
    prerequisiteIds: {'pistol-squat-parziale'},
    scores: {
      Muscle.quadricipiti: {Ability.forza: 3, Ability.equilibrio: 2},
      Muscle.glutei: {Ability.forza: 2},
      Muscle.femorali: {Ability.flessibilita: 1},
      Muscle.addominali: {Ability.equilibrio: 2},
    },
    cue: 'Scendi lentamente senza supporto fino in fondo, poi usa le mani '
        'solo per aiutarti a risalire.',
    tips: ['Il controllo nella discesa è ciò che costruisce la forza per la risalita completa'],
  ),
  Exercise(
    id: 'pistol-squat-completo',
    name: 'Pistol squat completo',
    category: FitnessCategory.gambe,
    equipment: {},
    level: 6,
    prerequisiteIds: {'pistol-squat-negativo'},
    scores: {
      Muscle.quadricipiti: {Ability.forza: 3, Ability.equilibrio: 3},
      Muscle.glutei: {Ability.forza: 3},
      Muscle.femorali: {Ability.flessibilita: 1},
      Muscle.addominali: {Ability.equilibrio: 2},
      Muscle.abduttori: {Ability.equilibrio: 2},
    },
    cue: 'Una gamba distesa davanti, scendi e risali in equilibrio, senza '
        'toccare terra con l\'altra gamba né usare le mani.',
    tips: ['Allena entrambe le gambe separatamente: il lato debole va sempre indietro'],
  ),

  // --- Catena L-sit / V-sit / dragon flag (core frontale), aggiunta
  // 2026-09-23. Prima catena per questa categoria, finora vuota. V-sit e
  // dragon-flag-negativa si diramano entrambe da l-sit-completo. ---
  Exercise(
    id: 'hollow-body-hold',
    name: 'Hollow body hold',
    category: FitnessCategory.coreFrontale,
    equipment: {},
    level: 0,
    scores: {
      Muscle.addominali: {Ability.forza: 2},
      Muscle.lombari: {Ability.forza: 1},
    },
    cue: 'Disteso sulla schiena, solleva spalle e gambe da terra '
        'schiacciando la zona lombare sul pavimento, braccia tese '
        'sopra la testa.',
    tips: [
      'La schiena bassa resta sempre a contatto con il pavimento: se si stacca, alza meno le gambe',
      'È la tensione di base che serve per praticamente tutti gli esercizi di questa categoria',
    ],
  ),

  Exercise(
    id: 'l-sit-tuck-hold',
    name: 'Tuck hold',
    category: FitnessCategory.coreFrontale,
    equipment: {},
    level: 1,
    prerequisiteIds: {'hollow-body-hold'},
    scores: {
      Muscle.addominali: {Ability.forza: 2},
      Muscle.tricipiti: {Ability.forza: 1},
      Muscle.spalle: {Ability.forza: 1},
      Muscle.avambracci: {Ability.forza: 1},
    },
    cue: 'Seduto, mani a terra vicino ai fianchi, ginocchia al petto: '
        'solleva tutto il corpo da terra.',
    tips: ['Spingi verso il basso con le braccia, non incurvare le spalle in avanti'],
  ),
  Exercise(
    id: 'l-sit-una-gamba',
    name: 'L-sit a una gamba',
    category: FitnessCategory.coreFrontale,
    equipment: {},
    level: 2,
    prerequisiteIds: {'l-sit-tuck-hold'},
    scores: {
      Muscle.addominali: {Ability.forza: 2},
      Muscle.tricipiti: {Ability.forza: 1},
      Muscle.spalle: {Ability.forza: 1},
      Muscle.femorali: {Ability.flessibilita: 1},
    },
    cue: 'Stessa posizione del tuck hold, ma distendi una gamba in '
        'avanti, parallela al pavimento.',
    tips: ['Alterna quale gamba distendi tra una serie e l\'altra'],
  ),
  Exercise(
    id: 'l-sit-completo',
    name: 'L-sit completo',
    category: FitnessCategory.coreFrontale,
    equipment: {},
    level: 3,
    prerequisiteIds: {'l-sit-una-gamba'},
    scores: {
      Muscle.addominali: {Ability.forza: 3},
      Muscle.tricipiti: {Ability.forza: 2},
      Muscle.spalle: {Ability.forza: 1},
      Muscle.femorali: {Ability.flessibilita: 1},
    },
    cue: 'Entrambe le gambe distese e parallele al pavimento, braccia '
        'tese, corpo sollevato da terra.',
    tips: ['Se le gambe scendono, il tempo di tenuta conta più della perfezione della forma'],
  ),
  Exercise(
    id: 'v-sit',
    name: 'V-sit',
    category: FitnessCategory.coreFrontale,
    equipment: {},
    level: 4,
    prerequisiteIds: {'l-sit-completo'},
    scores: {
      Muscle.addominali: {Ability.forza: 3},
      Muscle.femorali: {Ability.flessibilita: 2},
      Muscle.tricipiti: {Ability.forza: 2},
      Muscle.spalle: {Ability.forza: 1},
    },
    cue: 'Dalla posizione dell\'L-sit, alza le gambe verso l\'alto '
        'avvicinandole al busto, verso una V.',
    tips: ['Richiede più flessibilità dei femorali rispetto alla posizione L-sit: se non arrivi, lavora anche sulle spaccate'],
  ),
  Exercise(
    id: 'dragon-flag-negativa',
    name: 'Dragon flag negativa',
    category: FitnessCategory.coreFrontale,
    equipment: {},
    level: 5,
    prerequisiteIds: {'l-sit-completo'},
    scores: {
      Muscle.addominali: {Ability.forza: 3},
      Muscle.lombari: {Ability.forza: 1},
      Muscle.dorsali: {Ability.forza: 1},
    },
    cue: 'Disteso sulla schiena, mani sopra la testa che tengono un '
        'appoggio fisso: solleva tutto il corpo in linea retta e scendi '
        'lentamente controllato.',
    tips: [
      'Solo la discesa è controllata: rialzati aiutandoti con le gambe piegate o le mani',
    ],
  ),
  Exercise(
    id: 'dragon-flag-tenuta-parziale',
    name: 'Dragon flag a tenuta parziale',
    category: FitnessCategory.coreFrontale,
    equipment: {},
    level: 6,
    prerequisiteIds: {'dragon-flag-negativa'},
    scores: {
      Muscle.addominali: {Ability.forza: 3},
      Muscle.lombari: {Ability.forza: 1},
      Muscle.dorsali: {Ability.forza: 1},
    },
    cue: 'Come la negativa, ma fermati e tieni la posizione a metà '
        'percorso (corpo a circa 45 gradi) per qualche secondo prima '
        'di continuare a scendere.',
    tips: ['La tenuta isometrica a metà percorso è spesso il punto più debole della discesa'],
  ),

  Exercise(
    id: 'dragon-flag-ginocchia-piegate',
    name: 'Dragon flag a ginocchia piegate',
    category: FitnessCategory.coreFrontale,
    equipment: {},
    level: 7,
    prerequisiteIds: {'dragon-flag-tenuta-parziale'},
    scores: {
      Muscle.addominali: {Ability.forza: 3},
      Muscle.lombari: {Ability.forza: 1},
    },
    cue: 'Stessa posizione, ma piega le ginocchia verso il petto durante '
        'la discesa invece di tenerle distese.',
    tips: ['Versione più accessibile della dragon flag completa: usala per allungare il tempo sotto tensione'],
  ),
  Exercise(
    id: 'dragon-flag-completo',
    name: 'Dragon flag completo',
    category: FitnessCategory.coreFrontale,
    equipment: {},
    level: 8,
    prerequisiteIds: {'dragon-flag-ginocchia-piegate'},
    scores: {
      Muscle.addominali: {Ability.forza: 3},
      Muscle.lombari: {Ability.forza: 2},
      Muscle.dorsali: {Ability.forza: 1},
    },
    cue: 'Corpo interamente disteso e rigido dalle spalle ai piedi, sali '
        'e scendi in controllo completo, toccando terra solo con le '
        'scapole.',
    tips: ['Il bacino non deve piegarsi durante il movimento: se cede, torna alla versione a ginocchia piegate'],
  ),

  // --- Catena crow/crane pose ed elbow lever (equilibrio), aggiunta
  // 2026-09-23: prosegue la categoria oltre la verticale. Crow pose parte
  // da pushup-standard (prerequisito incrociato con spinta, indipendente
  // dalla catena verticale); crane pose ed elbow lever si diramano
  // entrambe da crow-pose-completo. ---
  Exercise(
    id: 'crow-pose-su-rialzo',
    name: 'Crow pose su rialzo',
    category: FitnessCategory.equilibrio,
    equipment: {},
    level: 5,
    prerequisiteIds: {'pushup-standard'},
    scores: {
      Muscle.spalle: {Ability.forza: 1, Ability.equilibrio: 1},
      Muscle.avambracci: {Ability.forza: 1},
    },
    cue: 'Mani appoggiate su un rialzo basso (libri, gradino), '
        'ginocchia sui tricipiti: sposta il peso avanti finché i '
        'piedi si staccano da terra.',
    tips: [
      'Il rialzo accorcia la distanza da percorrere in avanti con il peso, rendendo il bilanciamento più semplice da sentire',
    ],
  ),

  Exercise(
    id: 'crow-pose-assistito',
    name: 'Crow pose assistito',
    category: FitnessCategory.equilibrio,
    equipment: {},
    level: 6,
    prerequisiteIds: {'crow-pose-su-rialzo'},
    scores: {
      Muscle.spalle: {Ability.forza: 1, Ability.equilibrio: 2},
      Muscle.addominali: {Ability.equilibrio: 1},
      Muscle.avambracci: {Ability.forza: 1},
    },
    cue: 'Accovacciato, ginocchia appoggiate sui tricipiti, sposta il '
        'peso in avanti sulle mani finché i piedi si alleggeriscono da '
        'terra.',
    tips: ['Guarda un punto avanti a terra, non i piedi: aiuta a non cadere all\'indietro'],
  ),
  Exercise(
    id: 'crow-pose-completo',
    name: 'Crow pose completo',
    category: FitnessCategory.equilibrio,
    equipment: {},
    level: 7,
    prerequisiteIds: {'crow-pose-assistito'},
    scores: {
      Muscle.spalle: {Ability.forza: 2, Ability.equilibrio: 3},
      Muscle.addominali: {Ability.equilibrio: 2},
      Muscle.avambracci: {Ability.forza: 1},
    },
    cue: 'Stessa posizione, ma solleva completamente i piedi e tieni la '
        'posizione qualche secondo.',
    tips: ['Le ginocchia restano agganciate ai tricipiti per tutta la tenuta'],
  ),
  Exercise(
    id: 'crane-pose',
    name: 'Crane pose',
    category: FitnessCategory.equilibrio,
    equipment: {},
    level: 8,
    prerequisiteIds: {'crow-pose-completo'},
    scores: {
      Muscle.spalle: {Ability.forza: 3, Ability.equilibrio: 3},
      Muscle.addominali: {Ability.equilibrio: 2},
      Muscle.avambracci: {Ability.forza: 2},
    },
    cue: 'Come il crow pose, ma con le braccia distese invece che '
        'piegate: bacino più in alto, sguardo avanti.',
    tips: ['Richiede più forza di spalle del crow pose: se cadi subito, torna a rinforzare lì prima'],
  ),
  Exercise(
    id: 'elbow-lever-assistito',
    name: 'Elbow lever assistito',
    category: FitnessCategory.equilibrio,
    equipment: {},
    level: 9,
    prerequisiteIds: {'crow-pose-completo'},
    scores: {
      Muscle.addominali: {Ability.forza: 2, Ability.equilibrio: 2},
      Muscle.spalle: {Ability.forza: 1},
      Muscle.avambracci: {Ability.forza: 1},
      Muscle.tricipiti: {Ability.forza: 1},
    },
    cue: 'Gomiti appoggiati ai fianchi, mani a terra, sposta il peso in '
        'avanti sollevando i piedi di poco.',
    tips: ['I gomiti restano ben piantati nei fianchi: se scivolano, il peso non è ancora ben distribuito'],
  ),
  Exercise(
    id: 'elbow-lever-una-gamba',
    name: 'Elbow lever a una gamba',
    category: FitnessCategory.equilibrio,
    equipment: {},
    level: 10,
    prerequisiteIds: {'elbow-lever-assistito'},
    scores: {
      Muscle.addominali: {Ability.forza: 2, Ability.equilibrio: 3},
      Muscle.spalle: {Ability.forza: 1},
      Muscle.avambracci: {Ability.forza: 2},
      Muscle.tricipiti: {Ability.forza: 1},
    },
    cue: 'Dalla posizione assistita, distendi una sola gamba tenendo '
        'l\'altra piegata, gomiti sempre ben piantati nei fianchi.',
    tips: ['Alterna quale gamba distendi tra una serie e l\'altra'],
  ),

  Exercise(
    id: 'elbow-lever-completo',
    name: 'Elbow lever completo',
    category: FitnessCategory.equilibrio,
    equipment: {},
    level: 11,
    prerequisiteIds: {'elbow-lever-una-gamba'},
    scores: {
      Muscle.addominali: {Ability.forza: 3, Ability.equilibrio: 3},
      Muscle.spalle: {Ability.forza: 1},
      Muscle.avambracci: {Ability.forza: 2},
      Muscle.tricipiti: {Ability.forza: 1},
    },
    cue: 'Gambe distese e sollevate, corpo quasi orizzontale, in '
        'equilibrio solo sui gomiti appoggiati ai fianchi.',
    tips: ['Sposta lo sguardo avanti, non verso i piedi, per aiutare l\'equilibrio'],
  ),

  // --- Catena ponte / wheel pose (core posteriore), aggiunta
  // 2026-09-23. Prima catena per questa categoria, finora vuota. ---
  Exercise(
    id: 'estensione-spalle-a-muro',
    name: 'Estensione di spalle e schiena a muro',
    category: FitnessCategory.corePosteriore,
    equipment: {Equipment.muro},
    level: 0,
    scores: {
      Muscle.spalle: {Ability.flessibilita: 2},
      Muscle.lombari: {Ability.flessibilita: 1},
    },
    cue: 'In piedi rivolto verso il muro, mani appoggiate in alto '
        'sulla parete, lascia scendere il petto verso terra piegando '
        'le anche, allungando spalle e schiena.',
    tips: [
      'Serve a preparare la mobilità di spalle e schiena richiesta dal ponte, non è ancora un vero ponte',
    ],
  ),

  Exercise(
    id: 'ponte-spalle',
    name: 'Ponte da spalle',
    category: FitnessCategory.corePosteriore,
    equipment: {},
    level: 1,
    prerequisiteIds: {'estensione-spalle-a-muro'},
    scores: {
      Muscle.glutei: {Ability.forza: 2},
      Muscle.lombari: {Ability.forza: 1},
      Muscle.femorali: {Ability.forza: 1},
    },
    cue: 'Disteso sulla schiena, piedi vicini ai glutei, solleva il '
        'bacino spingendo sui talloni.',
    tips: ['Stringi i glutei in alto invece di inarcare solo la parte bassa della schiena'],
  ),
  Exercise(
    id: 'ponte-testa',
    name: 'Ponte da testa',
    category: FitnessCategory.corePosteriore,
    equipment: {},
    level: 2,
    prerequisiteIds: {'ponte-spalle'},
    scores: {
      Muscle.lombari: {Ability.flessibilita: 1, Ability.forza: 1},
      Muscle.spalle: {Ability.flessibilita: 1},
      Muscle.glutei: {Ability.forza: 1},
    },
    cue: 'Dalla stessa posizione, appoggia la sommità della testa a '
        'terra e solleva leggermente il bacino aiutandoti con le mani '
        'vicino alle orecchie.',
    tips: ['Poco peso sulla testa: le braccia fanno la maggior parte del lavoro'],
  ),
  Exercise(
    id: 'ponte-testa-mani-vicine',
    name: 'Ponte da testa con mani vicine',
    category: FitnessCategory.corePosteriore,
    equipment: {},
    level: 3,
    prerequisiteIds: {'ponte-testa'},
    scores: {
      Muscle.lombari: {Ability.flessibilita: 2, Ability.forza: 1},
      Muscle.spalle: {Ability.flessibilita: 2, Ability.forza: 1},
      Muscle.glutei: {Ability.forza: 1},
    },
    cue: 'Come il ponte da testa, ma cammina con le mani un po\' più '
        'vicine ai piedi, alleggerendo il peso sulla testa.',
    tips: ['Ogni sessione prova ad avvicinare le mani di un centimetro, non di più'],
  ),

  Exercise(
    id: 'ponte-completo',
    name: 'Ponte completo',
    category: FitnessCategory.corePosteriore,
    equipment: {},
    level: 4,
    prerequisiteIds: {'ponte-testa-mani-vicine'},
    scores: {
      Muscle.lombari: {Ability.flessibilita: 2, Ability.forza: 1},
      Muscle.spalle: {Ability.flessibilita: 2, Ability.forza: 1},
      Muscle.glutei: {Ability.forza: 1},
      Muscle.femorali: {Ability.flessibilita: 1},
    },
    cue: 'Spingi con mani e piedi fino a staccare la testa da terra, '
        'braccia e gambe distese, schiena arcuata.',
    tips: ['Se le spalle sono rigide, scalda con qualche estensione a muro prima di provare'],
  ),
  Exercise(
    id: 'ponte-a-muro',
    name: 'Ponte a muro',
    category: FitnessCategory.corePosteriore,
    equipment: {Equipment.muro},
    level: 5,
    prerequisiteIds: {'ponte-completo'},
    scores: {
      Muscle.lombari: {Ability.flessibilita: 2, Ability.forza: 1},
      Muscle.spalle: {Ability.flessibilita: 2},
      Muscle.glutei: {Ability.forza: 1},
    },
    cue: 'In piedi con la schiena al muro, cammina con le mani lungo la '
        'parete scendendo in ponte, poi risali allo stesso modo.',
    tips: ['Il muro riduce il range richiesto rispetto al ponte da terra: usalo per costruire fiducia nel movimento'],
  ),
  Exercise(
    id: 'ponte-avanzato',
    name: 'Ponte avanzato (wheel pose)',
    category: FitnessCategory.corePosteriore,
    equipment: {},
    level: 6,
    prerequisiteIds: {'ponte-a-muro'},
    scores: {
      Muscle.lombari: {Ability.flessibilita: 3, Ability.forza: 1},
      Muscle.spalle: {Ability.flessibilita: 3, Ability.forza: 1},
      Muscle.glutei: {Ability.forza: 1},
      Muscle.femorali: {Ability.flessibilita: 1},
    },
    cue: 'Nel ponte completo, cammina con le mani (o i piedi) più '
        'vicino possibile, avvicinando il petto alle gambe.',
    tips: ['Il progresso qui si misura in centimetri, non in sedute: ci vuole tempo'],
  ),
];
