# Roadmap

Scritto per essere ripreso da chiunque (umano o AI) senza contesto pregresso.

## Fatto

- [x] Struttura progetto Flutter (`pubspec.yaml`, `lib/`), poi completata con
      `android/`/`web/` generati da `flutter create` via `bootstrap.yml`
      (`docs/ARCHITETTURA.md` sezione 5).
- [x] Pipeline CI (`.github/workflows/`) validata: `bootstrap.yml` genera e
      committa `android/`+`web/`, `build-apk.yml` produce un APK di debug
      scaricabile e installabile via sideload a ogni push, `deploy-web.yml`
      pubblica un'anteprima web su GitHub Pages a ogni push
      (`docs/ARCHITETTURA.md` sezioni 7-8).
- [x] Ambiente di sviluppo locale (Flutter + VS Code) impostato e verificato
      con `flutter run -d chrome` (`docs/ARCHITETTURA.md` sezione 8).
- [x] Modello dati minimo: categorie di fondamenta (`lib/models/category.dart`),
      esercizio con prerequisiti/livello/punteggi muscolo-abilità
      (`lib/models/exercise.dart`), 5 esercizi di esempio (`seedExercises`).
- [x] Motore di progressione (`lib/models/progress.dart`,
      `ProgressController`): sblocco per prerequisiti (un esercizio può
      averne più di uno, TUTTI richiesti — grafo, non solo catena), livello
      per categoria, prossimo passo consigliato, punteggio per
      muscolo/abilità (`abilityScoreFor`) — coperto da
      `test/progress_test.dart`. Vedi `docs/ARCHITETTURA.md` sezione 10.
      Persistenza non ancora presente: vive solo in memoria (vedi punto 3
      sotto).
- [x] Schermate: elenco categorie con livello/prossimo passo → elenco
      esercizi espandibile con stato bloccato/sbloccato/acquisito
      (`lib/screens/`).
- [x] Motore della sessione guidata a respiro sincronizzato
      (`lib/models/session.dart`, `session_player.dart`,
      `session_playback_controller.dart`, `lib/screens/session_screen.dart`):
      voce (italiano, `flutter_tts`), conteggio ai momenti chiave, toni di
      sincronizzazione respiro (`assets/audio/`) — vedi
      `docs/ARCHITETTURA.md` sezione 9 per il design e le decisioni prese.
      Coperto da `test/session_player_test.dart`. `demoFlowSession` è una
      sessione dimostrativa sui 4 esercizi seed, non un piano reale (vedi
      punto 2 sotto).

## Da fare, in ordine ragionevole

1. **Popolare il database di esercizi.** Stato al 2026-09-22
   (`docs/ARCHITETTURA.md` sezione 12):
   - [x] b) Catena verticale completa (wall walk → ... → verticale
     libera), curata a mano con `scores`/`prerequisiteIds` reali.
   - [x] c) Catene loto e spaccate trascritte da `piano-allenamento.md`,
     curate a mano.
   - [x] Catena acrobazie (categoria nuova) costruita da zero, 4 esercizi.
   - [x] Nuove skill aggiunte il 2026-09-23 (`docs/ARCHITETTURA.md`
     sezione 15): planche e handstand push-up (spinta), pistol squat
     (gambe, prima catena), L-sit/V-sit/dragon flag (core frontale,
     prima catena), crow/crane pose ed elbow lever (equilibrio), ponte/
     wheel pose (core posteriore, prima catena). Totale `seedExercises`
     ora 52. Restano escluse front lever, back lever, muscle-up,
     one-arm pull-up e human flag: richiedono una sbarra/anelli non
     presenti nell'attrezzatura attuale.
   - [ ] a) Import "catalogo" da
     [free-exercise-db](https://github.com/yuhonas/free-exercise-db)
     (pubblico dominio): **non eseguibile dall'ambiente cloud di
     Claude** (proxy di rete blocca `raw.githubusercontent.com`, e gli
     strumenti di lettura web di Claude non filtrano in modo affidabile
     un file di ~870 elementi). Pronto invece uno script da eseguire tu:
     `dart run tool/import_free_exercise_db.dart` (dopo `flutter pub
     get`), da un terminale con Internet vero. Genera
     `lib/data/catalog_exercises.dart` (classe `CatalogExercise`,
     `lib/models/catalog_exercise.dart`) — un catalogo di sola
     consultazione, senza `scores`/`prerequisiteIds`, non collegato al
     motore di progressione. Per ora `lib/data/catalog_exercises.dart` è
     un placeholder vuoto.
   Dettaglio fonti in `ricerca-fondamenta-redesign.md` (progetto Claude),
   sezioni 3-4.
2. **[x] Generare sessioni reali dal database di esercizi.** Fatto il
   2026-09-22: `generateSession` (`lib/models/session_generator.dart`,
   `docs/ARCHITETTURA.md` sezione 13) sostituisce `demoFlowSession` in
   `home_screen.dart`, componendo una sessione bilanciata tra le
   categorie con esercizi disponibili a partire dai progressi correnti.
   Numeri (durata per esercizio, ordine categorie) da tarare dopo una
   prova pratica sul dispositivo, come già fatto per il pacing del
   respiro. Resta aperto: uno scheduling settimanale vero (quante sedute
   a settimana, giorni di riposo) — oggi si rigenera una sessione a ogni
   tocco, non un calendario.
3. **Persistenza locale**: scegliere e integrare uno storage locale
   (`sqflite` o `drift`) per salvare progressi (`ProgressController`),
   sedute di allenamento completate, note.
4. **Valutazione iniziale del livello per categoria**: un questionario o
   pochi test guidati (ispirato al modello a 9 categorie citato in
   `docs/ARCHITETTURA.md`), per posizionare l'utente su ciascuna categoria
   invece di partire sempre da 0.
5. **Sincronizzazione con Google Drive/Sheets** (vedi
   `docs/ARCHITETTURA.md` sezione 4): richiede che l'utente crei un progetto
   Google Cloud con OAuth client per l'app (passo manuale, non delegabile),
   poi integrare un package Flutter per l'autenticazione Google e la
   scrittura su Drive/Sheets.
6. **Routine yoga**: da strutturare quando l'utente la descrive (varia da
   seduta a seduta) — non forzarla nello stesso schema fisso delle
   categorie/`SessionStep` sopra finché non è chiaro se ha una
   progressione ripetibile o resta libera. I 10 minuti di yoga vanno
   comunque sempre inclusi nella sessione (decisione presa, vedi
   `docs/ARCHITETTURA.md` sezione 9), anche prima di essere modellati.
7. **Debug wireless verso il telefono reale** (`docs/ARCHITETTURA.md`
   sezione 8, punto 3): utile in particolare per provare la sessione
   guidata (voce, toni) sul dispositivo vero invece che nel browser.
8. **Valutare l'apertura pubblica del repository**: la decisione presa è
   "parti privato, progetta in modo incrementale verso il pubblico" — prima
   di rendere il repo pubblico, ricontrollare la sezione licenze in
   `docs/ARCHITETTURA.md` (in particolare il dataset con attribuzione Gym
   Visual, se mai integrato, va trattato con più cautela in un contesto
   pubblico) e aggiungere un file `LICENSE` esplicito.
9. **[x] Grafo dei prerequisiti, visualizzato nell'app.** Fatto il
   2026-09-22: `computeGraphLayout` (`lib/models/graph_layout.dart`) e
   `GraphScreen` (`lib/screens/graph_screen.dart`, `docs/ARCHITETTURA.md`
   sezione 14) mostrano tutti gli esercizi come grafo pan/zoom
   (`InteractiveViewer`), colonne per livello di prerequisito (profondità
   massima tra i prerequisiti, non minima, per gestire correttamente gli
   obiettivi composti come la verticale libera), frecce disegnate tra le
   card con la stessa formula di posizionamento usata per le card stesse.
   Apribile dalla home tramite l'icona a forma di grafo nell'app bar.
   Tap su una card mostra livello, prerequisiti risolti, cue e tips.

10. **[x] Legenda del grafo e grado di maturazione per esercizio.** Fatto
    il 2026-09-23 (`docs/ARCHITETTURA.md` sezione 16): `GraphScreen` ha
    una legenda (colori categoria/stato, spiegazione layout) dietro
    un'icona informazioni. Nuovo segnale di progresso continuo (0-100%)
    per esercizio, alimentato da un recap a fine sessione
    (`ExerciseOutcome`: andata bene/così così/non ancora), separato dal
    flag binario acquisito/non acquisito: a maturazione piena non
    scatta da sola una modifica alla rotazione, viene invece chiesto
    prima della sessione successiva se aumentare la difficoltà (livello
    di sfida, +15s di durata per livello) o passare all'esercizio
    successivo. Nuova schermata "Cosa so fare"
    (`lib/screens/maturity_screen.dart`) mostra tutti gli esercizi,
    anche bloccati, con il proprio grado di maturazione.
11. **[x] Rifinire la granularità delle 8 catene create il 2026-09-23**
    (planche, pistol squat, L-sit/dragon flag, crow/elbow lever, HSPU,
    ponte). Fatto lo stesso giorno (`docs/ARCHITETTURA.md` sezione 17):
    12 nuovi esercizi curati a mano (`seedExercises` da 52 a 64) inseriti
    come step intermedi nelle catene esistenti — nessuna modifica al
    modello dati, solo rinumerazione dei `level` nelle categorie
    toccate per restare leggibili.
12. **Grafo dedicato al singolo esercizio/skill** (stile Calistree):
    approccio deciso con Pietro il 2026-09-23 (dettaglio in
    `ricerca-fondamenta-redesign.md` del progetto Claude, sezione 8b) —
    riuso di `computeGraphLayout`/`GraphScreen` filtrato alla sola
    componente connessa dell'esercizio toccato, nessuna modifica al
    modello dati. Non ancora implementato.
13. **Bilanciamento dell'allenamento per muscolo/abilità/percentuale**:
    approccio deciso con Pietro il 2026-09-23 (dettaglio in
    `ricerca-fondamenta-redesign.md` del progetto Claude, sezione 8c) —
    nessuna estensione del modello dati necessaria (`Exercise.scores`
    già copre muscolo × abilità), il lavoro è sull'algoritmo di
    `generateSession` per selezionare in base a un profilo target
    pesato invece della sola rotazione per categoria. Resta da
    progettare come Pietro esprime il profilo target (probabile nuova
    schermata dedicata). Non ancora implementato.

14. **[x] Checkup di maturazione obbligatorio, periodico e in ordine
    fisso.** Fatto il 2026-09-23 (`docs/ARCHITETTURA.md` sezione 18):
    ogni `ProgressController.checkupIntervalSessions` sessioni normali
    completate (valore di partenza: 6), la prossima sessione richiesta
    da "Inizia sessione" viene sostituita da un checkup che rimette alla
    prova, nella loro forma minima, tutti gli esercizi già acquisiti —
    sempre nello stesso ordine (categoria poi livello, mai sparso). Un
    esito "non ancora" toglie l'acquisizione (e riblocca a cascata chi
    ne dipendeva), "così così" segnala solo bisogno di ripasso, "andata
    bene" conferma. Persistenza del contatore ancora da fare (punto 3
    sopra): oggi si azzera a ogni riavvio dell'app come il resto di
    `ProgressController`.

15. **[x] Schermata "Obiettivi" per i traguardi generali di
    allenamento.** Fatto il 2026-09-23 (`docs/ARCHITETTURA.md` sezione
    19, `lib/models/goals.dart`, `lib/screens/goals_screen.dart`): pesi
    muscolo×abilità (con copertura calcolata dal catalogo esercizi) e
    obiettivi specifici con nome e priorità, ispirati al vecchio piano
    scritto a mano. Deliberatamente NON collegata alla generazione delle
    sessioni: le sessioni A/B/C settimanali (punto 16 sotto) restano da
    costruire.

16. **[ ]** Sessioni A/B/C settimanali (max 30 minuti ciascuna), con
    check iniziale dello stato attuale (3 check per tipo di allenamento
    la prima volta) e check occasionali successivi per ciascuna delle 3
    sessioni — distinti dal checkup di maturazione globale del punto 14.
    Deliberatamente NON iniziato: l'utente ha chiesto di costruire prima
    solo gli obiettivi generali (punto 15).

## Note per chi riprende questo lavoro

- Le decisioni architetturali (Flutter, GitHub Actions per la build,
  Google Drive/Sheets come ponte dati verso Claude, scope privato-poi-
  pubblico) sono state prese in una conversazione con l'utente il
  2026-09-12 — vedi `docs/ARCHITETTURA.md` per il "perché" dietro ciascuna.
- Le decisioni sulla sessione guidata a respiro sincronizzato (struttura a
  flow continuo, pacing dei toni, timer di recupero, voce, annunci ai
  momenti chiave) sono state prese il 2026-09-19 — vedi
  `docs/ARCHITETTURA.md` sezione 9.
