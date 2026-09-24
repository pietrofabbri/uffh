import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'session.dart';
import 'session_player.dart';

/// Pilota la riproduzione reale di una [TrainingSession]: avvolge
/// [TrainingSessionPlayer] (motore puro, senza `Timer` — vedi
/// lib/models/session_player.dart) con un `Timer.periodic` vero, la voce
/// (`flutter_tts`, italiano), i toni di sincronizzazione respiro
/// (`audioplayers`, `assets/audio/`) e i comandi avanti/indietro/pausa
/// (vedi docs/ARCHITETTURA.md, sezione 9, decisioni del 2026-09-21).
///
/// Segue lo stesso schema "motore puro + controller con side-effect" di
/// [ProgressController] (lib/models/progress.dart): tutta la logica di
/// "cosa dire e quando" resta testabile in [TrainingSessionPlayer]; qui
/// c'è solo l'orchestrazione degli effetti collaterali e la notifica alla
/// UI (`ChangeNotifier`).
class SessionPlaybackController extends ChangeNotifier {
  /// Frequenza con cui si ricalcola lo stato. Abbastanza fine da non far
  /// percepire ritardo tra un tono di respiro e l'altro (anche nel
  /// pacing "hard", un atto respiratorio ogni 2s), abbastanza larga da
  /// non sprecare risorse.
  static const _tickInterval = Duration(milliseconds: 150);

  /// Soglia sotto la quale "indietro" torna al passo precedente invece
  /// che riavviare quello corrente — comportamento comune nei lettori
  /// multimediali (vedi [skipToPreviousStep]).
  static const _restartCurrentStepThreshold = Duration(seconds: 3);

  final TrainingSessionPlayer _player;
  final FlutterTts _tts;
  final AudioPlayer _tonePlayer;

  /// Tempo trascorso "congelato" da cui riparte [_stopwatch] dopo un
  /// avvio/ripresa/salto. L'elapsed vero è sempre `_baseElapsed +
  /// _stopwatch.elapsed`: questo è ciò che rende [skipToNextStep]/
  /// [skipToPreviousStep] possibili senza un vero "riavvolgimento" di
  /// `Stopwatch` (che misura solo tempo reale trascorso, non è
  /// impostabile a un valore arbitrario).
  Duration _baseElapsed = Duration.zero;
  final Stopwatch _stopwatch = Stopwatch();

  Timer? _timer;
  Duration _lastElapsed = const Duration(milliseconds: -200);
  BreathPhase? _lastBreathPhase;
  SessionPlaybackState? _lastState;
  bool _isPaused = true;
  bool _isDisposed = false;

  SessionPlaybackController(
    TrainingSession session, {
    FlutterTts? tts,
    AudioPlayer? tonePlayer,
  })  : _player = TrainingSessionPlayer(session),
        _tts = tts ?? FlutterTts(),
        _tonePlayer = tonePlayer ?? AudioPlayer() {
    _tts.setLanguage('it-IT');
    _tts.setSpeechRate(0.5);
  }

  Duration get _elapsedNow => _baseElapsed + _stopwatch.elapsed;

  /// Stato corrente. Prima del primo tick coincide con l'inizio sessione.
  SessionPlaybackState get state =>
      _lastState ?? _player.stateAt(Duration.zero);

  bool get isPaused => _isPaused;

  void start() {
    if (!_isPaused) return;
    _isPaused = false;
    _stopwatch.start();
    _timer = Timer.periodic(_tickInterval, (_) => _tick());
    _tick();
  }

  void pause() {
    if (_isPaused) return;
    _isPaused = true;
    _freezeElapsed();
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  /// Salta all'inizio del passo successivo (comando "avanti"). Se il
  /// passo corrente è l'ultimo, porta la sessione in fondo (completata).
  void skipToNextStep() {
    final nextIndex = state.stepIndex + 1;
    _seekTo(
      nextIndex >= _player.session.steps.length
          ? _player.session.totalDuration
          : _player.startOf(nextIndex),
    );
  }

  /// Torna all'inizio del passo corrente, oppure — se siamo nei primi
  /// [_restartCurrentStepThreshold] del passo — a quello precedente
  /// (comando "indietro").
  void skipToPreviousStep() {
    final current = state;
    if (current.elapsedInStep > _restartCurrentStepThreshold ||
        current.stepIndex == 0) {
      _seekTo(_player.startOf(current.stepIndex));
    } else {
      _seekTo(_player.startOf(current.stepIndex - 1));
    }
  }

  void _freezeElapsed() {
    _baseElapsed = _elapsedNow;
    _stopwatch
      ..stop()
      ..reset();
  }

  void _seekTo(Duration elapsed) {
    final wasRunning = !_isPaused;
    _stopwatch
      ..stop()
      ..reset();
    _baseElapsed = elapsed.isNegative ? Duration.zero : elapsed;
    if (wasRunning) _stopwatch.start();

    // Un salto non è un tick continuo: non attraversa le soglie del
    // motore (metà/conto alla rovescia) del tratto saltato, quindi non
    // deve farle "esplodere" tutte insieme. Si riparte da zero: il
    // prossimo tick annuncia solo il passo di arrivo, come al primo tick
    // della sessione.
    _lastElapsed = const Duration(milliseconds: -200);
    _lastBreathPhase = null;
    _tts.stop();

    final current = _player.stateAt(_baseElapsed);
    _lastState = current;
    notifyListeners();
  }

  void _tick() {
    if (_isDisposed) return;
    final elapsed = _elapsedNow;
    final current = _player.stateAt(elapsed);

    for (final message in _player.announcementsBetween(_lastElapsed, elapsed)) {
      _tts.speak(message);
    }
    if (current.breathPhase != null &&
        current.breathPhase != _lastBreathPhase) {
      _playTone(current.breathPhase!);
    }

    _lastElapsed = elapsed;
    _lastBreathPhase = current.breathPhase;
    _lastState = current;
    notifyListeners();

    if (current.isFinished) pause();
  }

  Future<void> _playTone(BreathPhase phase) async {
    final asset = phase == BreathPhase.inspiro
        ? 'audio/inspiro.wav'
        : 'audio/espiro.wav';
    await _tonePlayer.stop();
    await _tonePlayer.play(AssetSource(asset));
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _tts.stop();
    _tonePlayer.dispose();
    super.dispose();
  }
}
