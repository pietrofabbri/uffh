// Script di import "catalogo" da free-exercise-db (Unlicense/pubblico
// dominio), filtrato sull'attrezzatura reale di Pietro: pavimento
// (equipment "body only" -> insieme vuoto) e fascia elastica (equipment
// "bands" -> Equipment.fasciaElastica). Il muro non esiste come tag
// nella fonte: quegli esercizi restano curati a mano in
// lib/models/exercise.dart (seedExercises), non da questo script.
//
// USO: dart run tool/import_free_exercise_db.dart
//
// Richiede accesso a Internet vero dalla macchina su cui gira: NON
// funziona dagli ambienti cloud/sandbox di Claude (la rete li' e'
// filtrata e blocca raw.githubusercontent.com, verificato il
// 2026-09-22) -- va eseguito da un terminale reale, es. il tuo Mac in
// VS Code. Richiede il pacchetto `http` (dev_dependencies in
// pubspec.yaml).
//
// Genera lib/data/catalog_exercises.dart con la lista `catalogExercises`
// (vedi lib/models/catalog_exercise.dart). Questi esercizi sono un
// catalogo di sola consultazione: non hanno scores/prerequisiteIds (la
// fonte non li ha) e non entrano nel motore di progressione. Vedi
// docs/ARCHITETTURA.md sezione 11.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _sourceUrl =
    'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json';

// Mappa primaryMuscles/secondaryMuscles della fonte -> Muscle
// (lib/models/muscle.dart), verificata su schema.json il 2026-09-22.
const _muscleMap = {
  'abdominals': 'addominali',
  'abductors': 'abduttori',
  'adductors': 'adduttori',
  'biceps': 'bicipiti',
  'calves': 'polpacci',
  'chest': 'petto',
  'forearms': 'avambracci',
  'glutes': 'glutei',
  'hamstrings': 'femorali',
  'lats': 'dorsali',
  'lower back': 'lombari',
  'middle back': 'dorsaliMedi',
  'neck': 'collo',
  'quadriceps': 'quadricipiti',
  'shoulders': 'spalle',
  'traps': 'trapezi',
  'triceps': 'tricipiti',
};

String _dartId(String rawId) {
  // Gli id della fonte sono gia' slug (es. "Air_Bike"): normalizzati a
  // snake-case minuscolo con prefisso "catalogo-" per non collidere con
  // gli id scelti a mano in seedExercises.
  final slug = rawId
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return 'catalogo-$slug';
}

String _escape(String s) => s.replaceAll(r'\', r'\\').replaceAll("'", r"\'");

Future<void> main() async {
  stderr.writeln('Scarico $_sourceUrl ...');
  final http.Response response;
  try {
    response = await http.get(Uri.parse(_sourceUrl));
  } catch (e) {
    stderr.writeln('Errore di rete: $e');
    exit(1);
  }
  if (response.statusCode != 200) {
    stderr.writeln('Errore HTTP ${response.statusCode}, interrompo.');
    exit(1);
  }

  final all = jsonDecode(response.body) as List<dynamic>;
  stderr.writeln('${all.length} esercizi totali nella fonte.');

  final filtered = all.where((e) {
    final equip = (e as Map<String, dynamic>)['equipment'];
    return equip == 'body only' || equip == 'bands';
  }).toList();
  stderr.writeln('${filtered.length} con equipment "body only" o "bands".');

  final buffer = StringBuffer();
  buffer.writeln('// GENERATO AUTOMATICAMENTE da tool/import_free_exercise_db.dart');
  buffer.writeln('// Fonte: free-exercise-db (github.com/yuhonas/free-exercise-db),');
  buffer.writeln('// licenza Unlicense (pubblico dominio). Non modificare a mano:');
  buffer.writeln('// rilancia lo script per rigenerare questo file.');
  buffer.writeln();
  buffer.writeln("import '../models/catalog_exercise.dart';");
  buffer.writeln("import '../models/category.dart';");
  buffer.writeln("import '../models/muscle.dart';");
  buffer.writeln();
  buffer.writeln('const List<CatalogExercise> catalogExercises = [');

  var skipped = 0;
  for (final raw in filtered) {
    final e = raw as Map<String, dynamic>;
    final rawId = (e['id'] as String?) ?? (e['name'] as String? ?? '');
    final name = ((e['name'] as String?) ?? '').trim();
    if (name.isEmpty || rawId.isEmpty) {
      skipped++;
      continue;
    }

    final primary = <String>[];
    for (final m in (e['primaryMuscles'] as List<dynamic>? ?? const [])) {
      final mapped = _muscleMap[m as String];
      if (mapped != null) primary.add('Muscle.$mapped');
    }
    final secondary = <String>[];
    for (final m in (e['secondaryMuscles'] as List<dynamic>? ?? const [])) {
      final mapped = _muscleMap[m as String];
      if (mapped != null) secondary.add('Muscle.$mapped');
    }

    final equip = e['equipment'] as String;
    final equipmentDart =
        equip == 'bands' ? '{Equipment.fasciaElastica}' : '{}';
    final level = ((e['level'] as String?) ?? '').trim();

    final instructions = <String>[];
    for (final line in (e['instructions'] as List<dynamic>? ?? const [])) {
      instructions.add("'${_escape(line as String)}'");
    }

    buffer.writeln('  CatalogExercise(');
    buffer.writeln("    id: '${_escape(_dartId(rawId))}',");
    buffer.writeln("    name: '${_escape(name)}',");
    buffer.writeln('    primaryMuscles: {${primary.join(', ')}},');
    buffer.writeln('    secondaryMuscles: {${secondary.join(', ')}},');
    buffer.writeln('    equipment: $equipmentDart,');
    buffer.writeln("    sourceLevel: '${_escape(level)}',");
    buffer.writeln('    instructions: [${instructions.join(', ')}],');
    buffer.writeln('  ),');
  }
  buffer.writeln('];');

  final outFile = File('lib/data/catalog_exercises.dart');
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync(buffer.toString());
  stderr.writeln(
      'Scritto ${outFile.path}: ${filtered.length - skipped} esercizi '
      '($skipped scartati per id/nome vuoto).');
}
