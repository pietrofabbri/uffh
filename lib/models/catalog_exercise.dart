import 'category.dart';
import 'muscle.dart';

/// Un esercizio "di catalogo": importato meccanicamente da una fonte
/// esterna (free-exercise-db, github.com/yuhonas/free-exercise-db,
/// licenza Unlicense/pubblico dominio) tramite
/// `tool/import_free_exercise_db.dart`, senza curatela editoriale.
///
/// Ha nome/muscoli/attrezzatura/istruzioni ma NON `scores` (punteggio
/// muscolo x abilita') ne' `prerequisiteIds`: la fonte non ha equivalenti
/// per questi due campi (vedi docs/ARCHITETTURA.md sezione 11). Per
/// questo un [CatalogExercise] non entra nel motore di progressione
/// (`ProgressController`) ne' nella generazione di sedute -- serve solo a
/// una futura schermata di consultazione libera ("sfoglia tutti gli
/// esercizi"). Il sottoinsieme che entra davvero nel motore vive in
/// `Exercise`/`seedExercises` (exercise.dart), curato a mano.
class CatalogExercise {
  final String id;
  final String name;
  final Set<Muscle> primaryMuscles;
  final Set<Muscle> secondaryMuscles;

  /// Vuoto = solo corpo libero (equipment "body only" nella fonte).
  final Set<Equipment> equipment;

  /// Livello ASSOLUTO dalla fonte (beginner/intermediate/expert) -- non
  /// confrontabile con `Exercise.level`, che e' relativo alla posizione
  /// dentro una catena di prerequisiti. Tenuto solo per riferimento/UI.
  final String sourceLevel;

  /// Istruzioni passo-passo, cosi' come fornite dalla fonte.
  final List<String> instructions;

  const CatalogExercise({
    required this.id,
    required this.name,
    this.primaryMuscles = const {},
    this.secondaryMuscles = const {},
    this.equipment = const {},
    this.sourceLevel = '',
    this.instructions = const [],
  });
}
