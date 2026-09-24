import 'package:flutter_test/flutter_test.dart';

import 'package:allenamento/models/category.dart';
import 'package:allenamento/models/exercise.dart';
import 'package:allenamento/models/graph_layout.dart';

/// Test di computeGraphLayout (lib/models/graph_layout.dart), usata da
/// GraphScreen (docs/ROADMAP.md, punto 8). Funzione pura: si testa
/// direttamente, senza widget, come le altre funzioni pure del progetto.
void main() {
  const base = Exercise(
    id: 'base',
    name: 'Base',
    category: FitnessCategory.spinta,
    equipment: {},
    level: 0,
  );
  const mid = Exercise(
    id: 'mid',
    name: 'Mid',
    category: FitnessCategory.spinta,
    equipment: {},
    level: 1,
    prerequisiteIds: {'base'},
  );
  const otherBase = Exercise(
    id: 'other-base',
    name: 'Other base',
    category: FitnessCategory.equilibrio,
    equipment: {},
    level: 0,
  );
  const goal = Exercise(
    id: 'goal',
    name: 'Goal',
    category: FitnessCategory.equilibrio,
    equipment: {},
    level: 2,
    prerequisiteIds: {'mid', 'other-base'},
  );

  test('un esercizio senza prerequisiti è in colonna 0', () {
    final layout = computeGraphLayout([base]);
    final node = layout.nodes.single;
    expect(node.column, 0);
  });

  test('un esercizio con un prerequisito è nella colonna successiva', () {
    final layout = computeGraphLayout([base, mid]);
    final baseNode = layout.nodes.firstWhere((n) => n.exercise.id == 'base');
    final midNode = layout.nodes.firstWhere((n) => n.exercise.id == 'mid');
    expect(midNode.column, baseNode.column + 1);
  });

  test(
    'un obiettivo composto con prerequisiti a profondità diverse va '
    '1 oltre la profondità massima, non la minima',
    () {
      final layout = computeGraphLayout([base, mid, otherBase, goal]);
      // base(0) -> mid(1); other-base(0). goal richiede mid E other-base:
      // deve stare dopo il più profondo dei due (mid, colonna 1), non
      // dopo il meno profondo (other-base, colonna 0).
      final goalNode = layout.nodes.firstWhere((n) => n.exercise.id == 'goal');
      expect(goalNode.column, 2);
    },
  );

  test('genera un arco per ogni prerequisito, diretto da prerequisito a esercizio', () {
    final layout = computeGraphLayout([base, mid, otherBase, goal]);
    final edgeIds = layout.edges.map((e) => (e.fromId, e.toId)).toSet();
    expect(edgeIds, {
      ('base', 'mid'),
      ('mid', 'goal'),
      ('other-base', 'goal'),
    });
  });

  test('columnCount e maxRowCount riflettono la struttura del grafo', () {
    final layout = computeGraphLayout([base, mid, otherBase, goal]);
    expect(layout.columnCount, 3); // colonne 0, 1, 2
    // colonna 0 ha base + other-base = 2 nodi, la più affollata.
    expect(layout.maxRowCount, 2);
  });

  test('grafo vuoto non genera errori', () {
    final layout = computeGraphLayout(const []);
    expect(layout.nodes, isEmpty);
    expect(layout.edges, isEmpty);
    expect(layout.columnCount, 0);
    expect(layout.maxRowCount, 0);
  });

  test('un ciclo (dato malformato) non causa un loop infinito', () {
    const cycleA = Exercise(
      id: 'cycle-a',
      name: 'Cycle A',
      category: FitnessCategory.spinta,
      equipment: {},
      level: 0,
      prerequisiteIds: {'cycle-b'},
    );
    const cycleB = Exercise(
      id: 'cycle-b',
      name: 'Cycle B',
      category: FitnessCategory.spinta,
      equipment: {},
      level: 0,
      prerequisiteIds: {'cycle-a'},
    );

    // Se questo test non va in timeout, la protezione anti-loop funziona.
    final layout = computeGraphLayout([cycleA, cycleB]);
    expect(layout.nodes.length, 2);
  });

  test('dentro una colonna, i nodi sono ordinati per categoria poi nome', () {
    // Stessa colonna (0, nessun prerequisito): equilibrio dopo spinta per
    // indice di categoria (FitnessCategory.values), non per ordine di
    // inserimento nella lista.
    final layout = computeGraphLayout([otherBase, base]);
    final column0 = layout.nodes.where((n) => n.column == 0).toList()
      ..sort((a, b) => a.row.compareTo(b.row));
    expect(column0.map((n) => n.exercise.id).toList(), ['base', 'other-base']);
  });
}
