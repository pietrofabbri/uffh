import 'exercise.dart';

/// Un nodo del grafo dei prerequisiti, posizionato su una griglia
/// logica (colonna/riga in UNITA', non pixel -- chi disegna il grafo,
/// lib/screens/graph_screen.dart, decide la dimensione delle celle).
class GraphNode {
  final Exercise exercise;

  /// Colonna = "profondita'" nel grafo: 0 per gli esercizi senza
  /// prerequisiti, altrimenti 1 + la profondita' massima tra i suoi
  /// prerequisiti (vedi [computeGraphLayout]).
  final int column;

  /// Riga dentro la colonna, per non sovrapporre i nodi.
  final int row;

  const GraphNode({
    required this.exercise,
    required this.column,
    required this.row,
  });
}

/// Un arco del grafo: da un prerequisito ([fromId]) verso l'esercizio
/// che lo richiede ([toId]). Un esercizio con piu' prerequisiti genera
/// piu' archi in ingresso (docs/ARCHITETTURA.md sezione 10, semantica
/// AND: tutti richiesti insieme, non basta uno).
class GraphEdge {
  final String fromId;
  final String toId;

  const GraphEdge({required this.fromId, required this.toId});
}

/// Il layout completo: nodi posizionati su una griglia logica, archi tra
/// loro, e le dimensioni della griglia utili a chi disegna per
/// dimensionare il canvas.
class GraphLayout {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final int columnCount;
  final int maxRowCount;

  const GraphLayout({
    required this.nodes,
    required this.edges,
    required this.columnCount,
    required this.maxRowCount,
  });
}

/// Calcola un layout "a livelli" del grafo dei prerequisiti: funzione
/// pura (vedi test/graph_layout_test.dart), stesso principio delle altre
/// funzioni pure del progetto (`TrainingSessionPlayer.stateAt`,
/// `generateSession`).
///
/// La colonna di un esercizio e' la sua profondita' nel grafo (0 =
/// nessun prerequisito, altrimenti 1 + la profondita' massima tra i suoi
/// prerequisiti): esercizi propedeutici a sinistra, obiettivi a destra.
/// Un esercizio con prerequisiti da catene/categorie diverse (es.
/// verticale-libera) converge quindi visivamente nella stessa colonna
/// degli altri obiettivi allo stesso "passo di distanza" dalla base.
/// Dentro una colonna, i nodi sono ordinati per categoria poi nome, per
/// un risultato deterministico.
///
/// **Cicli**: non rilevati esplicitamente (gap noto, docs/ARCHITETTURA.md
/// sezione 10) -- un id coinvolto in un ciclo viene comunque disegnato,
/// con una profondita' calcolata troncando la ricorsione al primo giro
/// di visita, solo per evitare un loop infinito (protezione difensiva,
/// non una vera diagnosi del ciclo).
GraphLayout computeGraphLayout(List<Exercise> exercises) {
  final byId = {for (final e in exercises) e.id: e};
  final depthCache = <String, int>{};
  final visiting = <String>{};

  int depthOf(String id) {
    final cached = depthCache[id];
    if (cached != null) return cached;
    if (visiting.contains(id)) {
      return 0; // ciclo: tronca la ricorsione, non è una vera diagnosi.
    }
    final exercise = byId[id];
    if (exercise == null || exercise.prerequisiteIds.isEmpty) {
      depthCache[id] = 0;
      return 0;
    }
    visiting.add(id);
    var maxPrereqDepth = -1;
    for (final prereqId in exercise.prerequisiteIds) {
      final d = depthOf(prereqId);
      if (d > maxPrereqDepth) maxPrereqDepth = d;
    }
    visiting.remove(id);
    final depth = maxPrereqDepth + 1;
    depthCache[id] = depth;
    return depth;
  }

  final columns = <int, List<Exercise>>{};
  for (final exercise in exercises) {
    final depth = depthOf(exercise.id);
    columns.putIfAbsent(depth, () => []).add(exercise);
  }

  final columnCount =
      columns.isEmpty ? 0 : columns.keys.reduce((a, b) => a > b ? a : b) + 1;

  var maxRowCount = 0;
  final nodes = <GraphNode>[];
  for (var col = 0; col < columnCount; col++) {
    final inColumn = [...?columns[col]]
      ..sort((a, b) {
        final byCategory = a.category.index.compareTo(b.category.index);
        if (byCategory != 0) return byCategory;
        return a.name.compareTo(b.name);
      });
    if (inColumn.length > maxRowCount) maxRowCount = inColumn.length;
    for (var row = 0; row < inColumn.length; row++) {
      nodes.add(GraphNode(exercise: inColumn[row], column: col, row: row));
    }
  }

  final edges = <GraphEdge>[
    for (final exercise in exercises)
      for (final prereqId in exercise.prerequisiteIds)
        if (byId.containsKey(prereqId))
          GraphEdge(fromId: prereqId, toId: exercise.id),
  ];

  return GraphLayout(
    nodes: nodes,
    edges: edges,
    columnCount: columnCount,
    maxRowCount: maxRowCount,
  );
}
