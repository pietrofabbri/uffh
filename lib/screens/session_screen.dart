import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../models/progress.dart';
import '../models/session.dart';
import '../models/session_playback_controller.dart';
import '../models/session_player.dart';

/// Riproduce una [TrainingSession] a schermo intero: nome/passo corrente,
/// secondi rimanenti, indicatore del respiro (inspira/espira, quando il
/// passo ne ha uno scandito) e comandi avanti/pausa-riprendi/indietro. La
/// voce e i toni suonano tramite [SessionPlaybackController]; questa
/// classe si limita a disegnare il suo stato. A sessione finita mostra
/// [_SessionRecap] invece del semplice "completata": un modo rapido e
/// facoltativo per dire com'e' andato ciascun esercizio, che alimenta
/// [ProgressController.recordOutcome] (docs/ARCHITETTURA.md sezione 16).
class SessionScreen extends StatefulWidget {
  final TrainingSession session;
  final ProgressController progress;

  /// True quando questa e' una sessione di CHECKUP di maturazione
  /// (docs/ARCHITETTURA.md sezione 18, generata da
  /// `generateCheckupSession`) invece di una sessione normale: cambia
  /// come [_SessionRecap] registra gli esiti (vedi
  /// [ProgressController.recordCheckupOutcome]) e rende la valutazione
  /// di ogni esercizio obbligatoria prima di poter uscire, invece che
  /// facoltativa.
  final bool isCheckup;

  const SessionScreen({
    super.key,
    required this.session,
    required this.progress,
    this.isCheckup = false,
  });

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late final SessionPlaybackController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SessionPlaybackController(widget.session);
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.session.name)),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final state = _controller.state;
          if (state.isFinished) {
            return _SessionRecap(
              session: widget.session,
              progress: widget.progress,
              isCheckup: widget.isCheckup,
            );
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Passo ${state.stepIndex + 1} di '
                    '${widget.session.steps.length}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.step.announcement,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 32),
                  _BreathIndicator(phase: state.breathPhase),
                  const SizedBox(height: 32),
                  Text(
                    '${state.remainingInStep.inSeconds}s',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: state.step.duration.inMilliseconds == 0
                        ? 0
                        : state.elapsedInStep.inMilliseconds /
                            state.step.duration.inMilliseconds,
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        onPressed: _controller.skipToPreviousStep,
                        icon: const Icon(Icons.skip_previous),
                        tooltip: 'Indietro',
                      ),
                      const SizedBox(width: 16),
                      FilledButton.icon(
                        onPressed: () {
                          _controller.isPaused
                              ? _controller.start()
                              : _controller.pause();
                        },
                        icon: Icon(
                          _controller.isPaused
                              ? Icons.play_arrow
                              : Icons.pause,
                        ),
                        label: Text(_controller.isPaused ? 'Riprendi' : 'Pausa'),
                      ),
                      const SizedBox(width: 16),
                      IconButton.filledTonal(
                        onPressed: _controller.skipToNextStep,
                        icon: const Icon(Icons.skip_next),
                        tooltip: 'Avanti',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BreathIndicator extends StatelessWidget {
  final BreathPhase? phase;

  const _BreathIndicator({required this.phase});

  @override
  Widget build(BuildContext context) {
    if (phase == null) {
      return Text(
        'Respiro libero',
        style: Theme.of(context).textTheme.titleMedium,
      );
    }

    final isInspiro = phase == BreathPhase.inspiro;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: isInspiro ? 140 : 90,
      height: isInspiro ? 140 : 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      alignment: Alignment.center,
      child: Text(
        isInspiro ? 'Inspira' : 'Espira',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

class _SessionRecap extends StatefulWidget {
  final TrainingSession session;
  final ProgressController progress;
  final bool isCheckup;

  const _SessionRecap({
    required this.session,
    required this.progress,
    required this.isCheckup,
  });

  @override
  State<_SessionRecap> createState() => _SessionRecapState();
}

class _SessionRecapState extends State<_SessionRecap> {
  // Esercizi distinti della sessione, nell'ordine in cui compaiono per
  // la prima volta -- una sessione puo' ripetere lo stesso esercizio in
  // piu' round (docs/ARCHITETTURA.md sezione 13), ma il recap chiede il
  // suo esito una volta sola.
  late final List<Exercise> _exercises = {
    for (final step in widget.session.steps)
      if (step is ExerciseStep) step.exercise.id: step.exercise,
  }.values.toList();

  final Set<String> _rated = {};

  bool get _allRated => _rated.length == _exercises.length;

  @override
  void initState() {
    super.initState();
    if (widget.isCheckup) {
      // Nessun esercizio da valutare (nulla ancora acquisito): il
      // checkup non ha contenuto, si chiude da solo -- vedi
      // ProgressController.exercisesForCheckup.
      if (_exercises.isEmpty) widget.progress.completeCheckup();
    } else {
      // Fa avanzare il conto verso il prossimo checkup obbligatorio
      // (docs/ARCHITETTURA.md sezione 18) -- una volta sola, quando la
      // sessione normale arriva davvero in fondo.
      widget.progress.recordSessionCompleted();
    }
  }

  void _rate(String exerciseId, ExerciseOutcome outcome) {
    if (widget.isCheckup) {
      widget.progress.recordCheckupOutcome(exerciseId, outcome);
    } else {
      widget.progress.recordOutcome(exerciseId, outcome);
    }
    setState(() => _rated.add(exerciseId));
    if (widget.isCheckup && _allRated) {
      widget.progress.completeCheckup();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              widget.isCheckup ? 'Checkup completato' : 'Sessione completata',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (_exercises.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.isCheckup
                    ? "Com'è andato ogni esercizio? Valutali tutti per "
                        'chiudere il checkup.'
                    : "Com'è andato ogni esercizio? (facoltativo)",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              for (final exercise in _exercises)
                _RecapRow(
                  exercise: exercise,
                  rated: _rated.contains(exercise.id),
                  onRate: (outcome) => _rate(exercise.id, outcome),
                ),
            ],
            const SizedBox(height: 24),
            if (!widget.isCheckup || _allRated)
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Torna alla home'),
              )
            else
              Text(
                'Vota tutti gli esercizi per completare il checkup',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

class _RecapRow extends StatelessWidget {
  final Exercise exercise;
  final bool rated;
  final ValueChanged<ExerciseOutcome> onRate;

  const _RecapRow({
    required this.exercise,
    required this.rated,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(exercise.name, overflow: TextOverflow.ellipsis),
          ),
          if (rated)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.check, color: Colors.green, size: 20),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.sentiment_very_satisfied),
              tooltip: 'Andata bene',
              onPressed: () => onRate(ExerciseOutcome.andataBene),
            ),
            IconButton(
              icon: const Icon(Icons.sentiment_neutral),
              tooltip: 'Così così',
              onPressed: () => onRate(ExerciseOutcome.cosiCosi),
            ),
            IconButton(
              icon: const Icon(Icons.sentiment_dissatisfied),
              tooltip: 'Non ancora',
              onPressed: () => onRate(ExerciseOutcome.nonAncora),
            ),
          ],
        ],
      ),
    );
  }
}
