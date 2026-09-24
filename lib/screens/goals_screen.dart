import 'package:flutter/material.dart';

import '../models/ability.dart';
import '../models/exercise.dart';
import '../models/goals.dart';
import '../models/muscle.dart';
import '../models/progress.dart';

/// Schermata "Obiettivi": qui si impostano i traguardi generali di
/// allenamento, DISACCOPPIATI dalla generazione delle sessioni A/B/C
/// (non ancora costruite, vedi docs/ROADMAP.md e docs/ARCHITETTURA.md
/// sezione 19) -- serve solo a registrare cosa si vuole raggiungere, non
/// a costruire le sessioni stesse. Due sezioni, sul modello del vecchio
/// piano scritto a mano (progetto Claude, claude/piano-allenamento.md):
/// obiettivi specifici con nome e priorità, e pesi per ogni coppia
/// muscolo/abilità, ciascuno con accanto la copertura attuale calcolata
/// dal catalogo esercizi ([GoalsController.coverageOf]).
class GoalsScreen extends StatelessWidget {
  final GoalsController goals;
  final ProgressController progress;
  final List<Exercise> exercises;

  const GoalsScreen({
    super.key,
    required this.goals,
    required this.progress,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Obiettivi')),
      body: ListenableBuilder(
        listenable: Listenable.merge([goals, progress]),
        builder: (context, _) {
          final overall = goals.overallCoverage(exercises, progress);
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (goals.activeWeightCount > 0) _OverallCoverageCard(overall: overall),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  'Obiettivi specifici',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _NamedGoalsSection(goals: goals),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: OutlinedButton.icon(
                  onPressed: () => _addNamedGoal(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Aggiungi obiettivo specifico'),
                ),
              ),
              const Divider(height: 32),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Text(
                  'Pesi per muscolo e abilità',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Quanto conta allenare ciascuna abilità su ciascun '
                  'muscolo. La copertura mostra quanto del catalogo '
                  'esercizi per quella combinazione hai già acquisito.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              for (final muscle in Muscle.values)
                _MuscleTile(
                  muscle: muscle,
                  goals: goals,
                  progress: progress,
                  exercises: exercises,
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addNamedGoal(BuildContext context) async {
    final result = await showDialog<NamedGoal>(
      context: context,
      builder: (context) => const _NamedGoalDialog(),
    );
    if (result != null) {
      goals.upsertNamedGoal(result);
    }
  }
}

class _OverallCoverageCard extends StatelessWidget {
  final double? overall;

  const _OverallCoverageCard({required this.overall});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.track_changes_outlined, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                overall == null
                    ? 'Nessun esercizio nel catalogo copre ancora gli '
                        'obiettivi impostati'
                    : 'Copertura media degli obiettivi impostati: '
                        '${overall!.round()}%',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NamedGoalsSection extends StatelessWidget {
  final GoalsController goals;

  const _NamedGoalsSection({required this.goals});

  @override
  Widget build(BuildContext context) {
    final namedGoals = goals.namedGoals;
    if (namedGoals.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('Nessun obiettivo specifico impostato'),
      );
    }
    return Column(
      children: [
        for (final goal in namedGoals)
          ListTile(
            leading: CircleAvatar(child: Text('${goal.priority}')),
            title: Text(goal.name),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Rimuovi',
              onPressed: () => goals.removeNamedGoal(goal.name),
            ),
            onTap: () async {
              final result = await showDialog<NamedGoal>(
                context: context,
                builder: (context) => _NamedGoalDialog(initial: goal),
              );
              if (result != null) goals.upsertNamedGoal(result);
            },
          ),
      ],
    );
  }
}

class _NamedGoalDialog extends StatefulWidget {
  final NamedGoal? initial;

  const _NamedGoalDialog({this.initial});

  @override
  State<_NamedGoalDialog> createState() => _NamedGoalDialogState();
}

class _NamedGoalDialogState extends State<_NamedGoalDialog> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.initial?.name ?? '',
  );
  late int _priority = widget.initial?.priority ?? 1;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Nuovo obiettivo' : 'Modifica obiettivo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nome (es. Verticale)'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Priorità'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: _priority > 1 ? () => setState(() => _priority--) : null,
              ),
              Text('$_priority'),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => setState(() => _priority++),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _nameController,
          builder: (context, value, _) => FilledButton(
            onPressed: value.text.trim().isEmpty
                ? null
                : () => Navigator.of(context).pop(
                      NamedGoal(name: value.text.trim(), priority: _priority),
                    ),
            child: const Text('Salva'),
          ),
        ),
      ],
    );
  }
}

class _MuscleTile extends StatelessWidget {
  final Muscle muscle;
  final GoalsController goals;
  final ProgressController progress;
  final List<Exercise> exercises;

  const _MuscleTile({
    required this.muscle,
    required this.goals,
    required this.progress,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    final activeCount = Ability.values
        .where((a) => goals.weightOf(muscle, a) != GoalWeight.nessuna)
        .length;

    return ExpansionTile(
      title: Text(muscle.label),
      subtitle: activeCount > 0
          ? Text(activeCount == 1 ? '1 obiettivo impostato' : '$activeCount obiettivi impostati')
          : null,
      children: [
        for (final ability in Ability.values)
          _AbilityRow(
            muscle: muscle,
            ability: ability,
            goals: goals,
            progress: progress,
            exercises: exercises,
          ),
      ],
    );
  }
}

class _AbilityRow extends StatelessWidget {
  final Muscle muscle;
  final Ability ability;
  final GoalsController goals;
  final ProgressController progress;
  final List<Exercise> exercises;

  const _AbilityRow({
    required this.muscle,
    required this.ability,
    required this.goals,
    required this.progress,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    final weight = goals.weightOf(muscle, ability);
    final coverage =
        weight == GoalWeight.nessuna ? null : goals.coverageOf(muscle, ability, exercises, progress);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(ability.label)),
              DropdownButton<GoalWeight>(
                value: weight,
                items: [
                  for (final w in GoalWeight.values)
                    DropdownMenuItem(value: w, child: Text(w.label)),
                ],
                onChanged: (value) {
                  if (value != null) goals.setWeight(muscle, ability, value);
                },
              ),
            ],
          ),
          if (weight != GoalWeight.nessuna)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: coverage == null
                  ? const Text(
                      'Nessun esercizio nel catalogo allena questa combinazione',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(value: coverage / 100, minHeight: 6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${coverage.round()}% coperto'),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}
