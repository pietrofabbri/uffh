/// Il ritmo di respirazione imposto durante un passo della sessione
/// guidata (vedi docs/ARCHITETTURA.md, sezione 9): una coppia di toni
/// (inspiro/espiro, in `assets/audio/`) scandisce quanto dura ogni atto
/// respiratorio, cosi' il respiro si sincronizza al movimento invece di
/// essere lasciato libero.
///
/// Decisioni prese con l'utente: il recupero e' sempre a respiro libero
/// (mai scandito), gli esercizi "soft" (mobilita', recupero attivo) hanno
/// un atto respiratorio ogni 4 secondi (inizialmente 5, accorciato di 1s
/// dopo la prima prova pratica del 2026-09-21 — troppo lento), quelli
/// "hard" (impegnativi) ogni 2 secondi.
enum BreathPacing {
  /// Nessun ritmo imposto: respiro libero. Usato nei blocchi di recupero
  /// ([RecoveryStep]) e, volendo, nei tentativi vicini al massimale dove
  /// forzare il respiro sarebbe controproducente.
  libero,

  /// Esercizi soft/mobilita': un atto respiratorio (inspiro OPPURE
  /// espiro) ogni 4 secondi.
  soft,

  /// Esercizi impegnativi: un atto respiratorio ogni 2 secondi.
  hard,
}

extension BreathPacingTiming on BreathPacing {
  /// Durata di un singolo atto respiratorio (un inspiro, oppure un
  /// espiro) per questo [BreathPacing], o `null` se il respiro è libero e
  /// non va scandito da nessun tono.
  Duration? get breathPhaseDuration {
    switch (this) {
      case BreathPacing.libero:
        return null;
      case BreathPacing.soft:
        return const Duration(seconds: 4);
      case BreathPacing.hard:
        return const Duration(seconds: 2);
    }
  }
}
