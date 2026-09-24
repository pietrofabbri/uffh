import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/exercise.dart';
import '../models/graph_layout.dart';
import '../models/progress.dart';

const _cardWidth = 180.0;
const _cardHeight = 72.0;
const _columnGap = 64.0;
const _rowGap = 16.0;
const _canvasPadding = 24.0;

/// Il grafo dei prerequisiti, disegnato per davvero: un nodo per
/// esercizio, un arco per ogni prerequisito (`Exercise.prerequisiteIds`
/// -- possono essere piu' di uno per nodo, semantica AND, vedi
/// docs/ARCHITETTURA.md sezione 10). Layout calcolato da
/// [computeGraphLayout] (lib/models/graph_layout.dart): colonna =
/// profondita' nel grafo, esercizi propedeutici a sinistra, obiettivi a
/// destra. Bordo colorato = stato di progressione (locked/unlocked/
/// mastered, stessa logica di [CategoryScreen]); pallino colorato =
/// categoria, per distinguere a colpo d'occhio le catene diverse che
/// convergono su un obiettivo composto (es. verticale-libera).
///
/// Pan/zoom con [InteractiveViewer] -- nessuna libreria esterna di
/// grafi: il layout e' deliberatamente semplice (a livelli, non
/// force-directed) per restare una funzione pura e testabile
/// (test/graph_layout_test.dart).
class GraphScreen extends StatelessWidget {
  final List<Exercise> exercises;
  final ProgressController progress;

  const GraphScreen({
    super.key,
    required this.exercises,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final layout = computeGraphLayout(exercises);

    final positions = <String, Offset>{
      for (final node in layout.nodes)
        node.exercise.id: Offset(
          _canvasPadding + node.column * (_cardWidth + _columnGap),
          _canvasPadding + node.row * (_cardHeight + _rowGap),
        ),
    };

    final canvasWidth = layout.columnCount == 0
        ? _canvasPadding * 2
        : _canvasPadding * 2 +
            layout.columnCount * _cardWidth +
            (layout.columnCount - 1) * _columnGap;
    final canvasHeight = layout.maxRowCount == 0
        ? _canvasPadding * 2
        : _canvasPadding * 2 +
            layout.maxRowCount * _cardHeight +
            (layout.maxRowCount - 1) * _rowGap;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grafo dei prerequisiti'),
        actions: [
          IconButton(
            tooltip: 'Legenda',
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showLegend(context),
          ),
        ],
      ),
      body: layout.nodes.isEmpty
          ? const Center(child: Text('Nessun esercizio da disegnare'))
          : ListenableBuilder(
              listenable: progress,
              builder: (context, _) {
                return InteractiveViewer(
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(80),
                  minScale: 0.4,
                  maxScale: 2.5,
                  child: SizedBox(
                    width: canvasWidth,
                    height: canvasHeight,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _EdgesPainter(
                              edges: layout.edges,
                              positions: positions,
                            ),
                          ),
                        ),
                        for (final node in layout.nodes)
                          Positioned(
                            left: positions[node.exercise.id]!.dx,
                            top: positions[node.exercise.id]!.dy,
                            width: _cardWidth,
                            height: _cardHeight,
                            child: _ExerciseNode(
                              exercise: node.exercise,
                              status: progress.statusOf(node.exercise),
                              allExercises: exercises,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  /// Spiega le convenzioni visive del grafo: colori di categoria e di
  /// stato, e cosa rappresentano colonne/frecce nel layout (docs/
  /// ARCHITETTURA.md sezione 14). Aperta dall'icona "i" in AppBar.
  void _showLegend(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text('Legenda', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('Categoria (pallino colorato)',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final category in FitnessCategory.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.primaries[
                            category.index % Colors.primaries.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(category.label),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Text('Stato (bordo e icona)',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            const _LegendStatusRow(
              icon: Icons.lock_outline,
              color: Colors.grey,
              label: 'Bloccato — mancano ancora dei prerequisiti',
            ),
            const _LegendStatusRow(
              icon: Icons.radio_button_unchecked,
              color: Colors.blue,
              label: 'Sbloccato — pronto da allenare',
            ),
            const _LegendStatusRow(
              icon: Icons.check_circle,
              color: Colors.green,
              label: 'Acquisito',
            ),
            const SizedBox(height: 16),
            Text('Layout', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            const Text(
              'Le colonne rappresentano la profondità nei prerequisiti: '
              'più a destra, più passi propedeutici richiede — un '
              'obiettivo con più catene di prerequisiti (es. la '
              'verticale libera) va oltre la più lunga delle due. Le '
              'frecce vanno dal prerequisito verso l\'esercizio che lo '
              'richiede.',
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendStatusRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _LegendStatusRow({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _EdgesPainter extends CustomPainter {
  final List<GraphEdge> edges;
  final Map<String, Offset> positions;

  _EdgesPainter({required this.edges, required this.positions});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final arrowPaint = Paint()..color = Colors.grey.shade400;

    for (final edge in edges) {
      final from = positions[edge.fromId];
      final to = positions[edge.toId];
      if (from == null || to == null) continue;

      final start = Offset(from.dx + _cardWidth, from.dy + _cardHeight / 2);
      final end = Offset(to.dx, to.dy + _cardHeight / 2);

      final controlOffset = (end.dx - start.dx) / 2;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
          start.dx + controlOffset,
          start.dy,
          end.dx - controlOffset,
          end.dy,
          end.dx,
          end.dy,
        );
      canvas.drawPath(path, paint);

      const arrowSize = 6.0;
      final arrowPath = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(end.dx - arrowSize, end.dy - arrowSize / 1.5)
        ..lineTo(end.dx - arrowSize, end.dy + arrowSize / 1.5)
        ..close();
      canvas.drawPath(arrowPath, arrowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EdgesPainter oldDelegate) {
    return oldDelegate.edges != edges || oldDelegate.positions != positions;
  }
}

class _ExerciseNode extends StatelessWidget {
  final Exercise exercise;
  final ExerciseStatus status;
  final List<Exercise> allExercises;

  const _ExerciseNode({
    required this.exercise,
    required this.status,
    required this.allExercises,
  });

  Color get _statusColor {
    switch (status) {
      case ExerciseStatus.locked:
        return Colors.grey.shade400;
      case ExerciseStatus.unlocked:
        return Colors.blue.shade400;
      case ExerciseStatus.mastered:
        return Colors.green.shade600;
    }
  }

  Color get _categoryColor =>
      Colors.primaries[exercise.category.index % Colors.primaries.length];

  IconData get _statusIcon {
    switch (status) {
      case ExerciseStatus.locked:
        return Icons.lock_outline;
      case ExerciseStatus.unlocked:
        return Icons.radio_button_unchecked;
      case ExerciseStatus.mastered:
        return Icons.check_circle;
    }
  }

  String _prerequisiteNames() {
    if (exercise.prerequisiteIds.isEmpty) return '';
    return exercise.prerequisiteIds.map((id) {
      final match = allExercises.where((e) => e.id == id);
      return match.isEmpty ? id : match.first.name;
    }).join(' + ');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: status == ExerciseStatus.locked ? 0 : 2,
      color: status == ExerciseStatus.locked ? Colors.grey.shade100 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: _statusColor, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _categoryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      exercise.category.label,
                      style: Theme.of(context).textTheme.labelSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(_statusIcon, size: 14, color: _statusColor),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                exercise.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final prerequisites = _prerequisiteNames();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exercise.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('${exercise.category.label} — livello ${exercise.level}'),
            if (prerequisites.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Richiede: $prerequisites'),
            ],
            if (exercise.cue.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(exercise.cue),
            ],
            for (final tip in exercise.tips)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('› $tip'),
              ),
          ],
        ),
      ),
    );
  }
}
