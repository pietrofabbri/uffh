# Architettura — app di allenamento (Flutter)

Documento pensato per essere leggibile e utilizzabile anche senza il contesto
della conversazione originale (chat con Claude, progetto "Attività fisica" su
claude.ai) — include le decisioni prese, il perché, e le fonti pubbliche usate.

## 1. Cos'è e perché è cambiato

Il progetto nasce da un piano di allenamento a corpo libero personale
(3 sedute A/B/C, vedi `docs/piano-allenamento-storico.md` se presente nel
repo) inizialmente pubblicato come pagina web con salvataggio automatico
lato claude.ai. È stato riprogettato da zero come **app Android nativa**
(Flutter) perché:

1. Deve generare/bilanciare l'allenamento a partire da **livello del
   praticante e obiettivi per categoria** (forza, flessibilità, equilibrio,
   muscolo specifico...), non da tre sedute scritte a mano.
2. Attrezzatura reale disponibile: **pavimento, muro, fascia elastica** —
   niente più taniche/bottiglie d'acqua.
3. Deve poter diventare **utilizzabile da chiunque**, non solo cucita su un
   singolo utente (restando comunque perfetta per il caso d'uso originale).
4. I dati generati devono poter **arrivare a Claude** per essere incrociati
   con altri progetti dell'utente (vedi sezione 4).
5. Va tenuta una documentazione rigorosa, pushabile su GitHub fin
   dall'inizio (questo repository).

## 2. Modello dei dati: categorie indipendenti, non un punteggio unico

Ispirato al metodo di valutazione pubblico descritto da
[bodyweighttrainingarena.com](https://bodyweighttrainingarena.com/calisthenics-level-assessment/):
invece di un livello globale, si valutano **categorie indipendenti**, ognuna
con la propria scala — perché la forza/abilità reale di una persona non è
mai uniforme tra un movimento e l'altro ("un punteggio unico nasconde il
divario"). Le categorie usate in questo progetto (`lib/models/category.dart`):

- Spinta (push-up, dip, verticale...)
- Trazione (rematore, trazioni...)
- Core — frontale, laterale, posteriore (tre angolazioni distinte)
- Bodyline (tensione globale, tipo plank)
- Gambe (squat, affondi, verso il pistol squat)
- Flessibilità (loto, spaccate...)
- Equilibrio (verticale, crow, cossack...)

Ogni esercizio (`lib/models/exercise.dart`) appartiene a UNA categoria, ha un
livello relativo (0 = più semplice) e opzionalmente un `prerequisiteId` — lo
stesso pattern "categoria × livelli × prerequisiti" descritto pubblicamente
da [Titans Grip](https://www.titans-grip.com/tools/skill-progression/) per i
loro skill tree (5 categorie × 5 tier, con prerequisiti espliciti tra
skill). I contenuti proprietari di quei tool NON sono stati copiati: solo il
pattern strutturale.

Ispirazione più ampia sul concetto di "obiettivi → attrezzatura → programma
generato automaticamente" viene da [Calistree](https://calistree.com/)
(1.100+ esercizi taggati per muscolo/articolazione/attrezzatura, "skill
tree" di progressioni, routine categorizzate per livello/obiettivo/
attrezzatura) — anche qui, solo il pattern, non i dati.

## 3. Attrezzatura: dalle taniche alla fascia elastica

Con pavimento + muro + fascia elastica restano pienamente allenabili tutte
le categorie sopra. La fascia si usa in due modi (fonti:
[NASM](https://www.nasm.org/resource-center/exercise-library/band-assisted-pull-up),
[Berg Movement](https://www.bergmovement.com/calisthenics-blog/resistance-band-bible-calisthenics-exercises)):

- **Assistenza** (riduce il carico): per chi non è ancora pronto per il
  movimento a corpo libero pieno (es. verso la trazione).
- **Resistenza aggiuntiva**: tenuta in tensione durante l'esercizio (rematore,
  curl, push-up con fascia sulla schiena) — sostituisce le taniche/bottiglie
  senza bisogno di pesi liberi.

## 4. Come i dati arrivano a Claude (senza un backend dedicato)

Decisione presa: **sincronizzazione tramite Google Drive/Sheets**, non un
backend proprietario. L'app scrive periodicamente i dati di progresso
(livelli per esercizio, sedute completate, note) in un file/foglio su
Google Drive dell'utente; un agente Claude con il connettore Google Drive
collegato può leggerlo quando serve incrociare i dati con altri progetti.
Non richiede server da gestire — solo (lato utente) un progetto Google
Cloud con OAuth client configurato per l'app (passo che l'utente deve fare
di persona, Claude non può creare credenziali Google per conto terzi).

Questo è ancora **da implementare** (vedi `docs/ROADMAP.md`): lo scheletro
attuale non ha ancora nessuna dipendenza di rete o di storage.

## 5. Perché Flutter, e come si compila un APK

Scelta: **Flutter**, per poter eventualmente estendere l'app a iOS/web in
futuro con la stessa base di codice, mantenendo un solo linguaggio (Dart) e
un solo albero di widget.

Compilare un APK richiede l'SDK Android — non disponibile nella sandbox
cloud in cui questo scheletro è stato scritto. La build reale avviene
tramite **GitHub Actions** (gratuito: illimitato su repository pubblici,
2.000 minuti/mese sulla free tier per repository privati — una build
Flutter richiede in genere 3-8 minuti, quindi ampiamente sufficiente per un
uso occasionale):

1. **`bootstrap.yml`** — da eseguire UNA VOLTA a mano (tab "Actions" →
   "Bootstrap piattaforma Android" → "Run workflow"): genera la cartella
   `android/` (mancante in questo repo perché nessun ambiente disponibile
   poteva generarla ed è meglio lasciarlo fare al runner GitHub, che ha
   Flutter reale) e la committa nel repository.
2. **`build-apk.yml`** — gira a ogni push su `main` (o manualmente):
   compila un **APK di debug** (nessuna firma di release richiesta,
   installabile via sideload abilitando "fonti sconosciute" su Android) e
   lo allega come artifact scaricabile dalla pagina della run.

Una build APK **firmata per il Play Store** è un passo successivo
volontario (richiede generare un keystore e configurare i secret del
repository) — non necessario per uso personale via sideload.

## 6. Cosa NON è stato copiato / limiti di questa ricerca

- Nessun contenuto testuale o dato proprietario di Calistree/Titans
  Grip/altre app commerciali è stato riprodotto: solo pattern strutturali
  descritti pubblicamente nelle loro pagine di marketing/documentazione.
- Libri di riferimento più rigorosi sulla programmazione calisthenics per
  obiettivo (es. *Overcoming Gravity* di Steven Low, *Convict Conditioning*
  di Paul Wade) non sono liberamente consultabili online: se disponibili
  all'autore del progetto, condividerne indice/estratti aiuterebbe a
  fondare il motore di progressione su basi più rigorose.
- Dataset pubblici di esercizi con media riutilizzabili, individuati ma non
  ancora integrati:
  [free-exercise-db](https://github.com/yuhonas/free-exercise-db) (licenza
  Unlicense/pubblico dominio, 800+ esercizi con immagini) e
  [hasaneyldrm/exercises-dataset](https://github.com/hasaneyldrm/exercises-dataset)
  (1.324 esercizi con GIF animate, ma media © Gym Visual — richiede
  mantenere l'attribuzione e non è adatto a un uso pubblico/commerciale
  senza licenza propria).

## 7. Perché Flutter è pinnato a una versione precisa in CI

`bootstrap.yml` e `build-apk.yml` usano entrambi `flutter-version: '3.24.x'`
(non `channel: stable`, che prende sempre l'ultima release). Motivo:
generando `android/` con una Flutter troppo recente, il template usa Kotlin
DSL (`build.gradle.kts`) invece del classico Groovy (`build.gradle`), e al
momento in cui questo progetto è stato messo in piedi la toolchain
Gradle/Kotlin DSL su GitHub Actions non era abbastanza matura da compilare
senza errori. Pinnare la stessa versione in entrambi i workflow (chi genera
`android/` e chi lo compila) evita il disallineamento.

Questo pinning riguarda solo l'ambiente CI. L'ambiente locale di sviluppo
(vedi sezione 8) può restare su una Flutter più recente — a un costo:
se mai si eseguisse `flutter create`/`flutter run` localmente in un modo
che rigenera `android/` (non capita con il normale `flutter run -d chrome`
o `flutter test`), si rischierebbe di ricommittare un `android/` in Kotlin
DSL generato dalla Flutter locale, reintroducendo lo stesso problema. Se
capita: rigenerare `android/` con `bootstrap.yml` (che usa la Flutter
pinnata) invece che localmente.

## 8. Provare l'app senza scaricare/installare un APK a ogni modifica

Tre modi, in ordine di comodità crescente (e setup iniziale crescente):

1. **Anteprima web (`deploy-web.yml`)** — implementato. Ogni push su
   `main` pubblica una build web su GitHub Pages
   (`https://pietrofabbri.github.io/uffh/`): basta aprire il link nel
   browser del telefono o del computer, nessuna installazione. Richiede
   che in Settings → Pages del repository la "Source" sia impostata su
   "GitHub Actions" (passo manuale una tantum, non automatizzabile da
   YAML).
2. **Ambiente Flutter locale (VS Code)** — implementato per lo sviluppo:
   Flutter installato via `brew install --cask flutter` (che collega da
   solo `flutter`/`dart` al PATH), estensione `Dart-Code.flutter` per VS
   Code, SDK Android riusato dall'installazione Android Studio esistente.
   `flutter run -d chrome` per iterare con hot reload senza toccare il
   telefono; `flutter test` per la suite di test. Non compila ancora per
   Android in locale (richiederebbe allineare la Flutter locale, più
   recente, con quella pinnata in CI — vedi sezione 7 — o accettare di
   rigenerare `android/` in locale con tutti i rischi che comporta).
3. **Telefono via debug wireless (Android 11+)** — opzione futura, non
   ancora impostata: da "Opzioni sviluppatore" abilitare "Debug wireless",
   fare il pairing (`adb pair`) e poi `flutter run` punta al telefono reale
   via Wi-Fi invece che via USB. Utile quando serve testare qualcosa che
   nel browser non si comporta come sul dispositivo vero (notifiche, TTS,
   sensori) — proprio il caso della sessione guidata della sezione 9,
   quindi probabile prossimo passo pratico.

## 9. Sessione guidata a respiro sincronizzato

Deciso con l'utente il 2026-09-19: l'allenamento è una sequenza di passi
(`lib/models/session.dart`) — esecuzione di un esercizio (`ExerciseStep`)
o recupero (`RecoveryStep`) — fatta scorrere da un motore
(`lib/models/session_player.dart`) che guida voce, conteggio e respiro.

**Struttura settimanale**: preferito un flow continuo (mobilità/esercizi
soft come recupero attivo, alternati a esercizi più impegnativi, senza
interruzioni nette) rispetto a blocchi separati mobilità/esercizi/yoga —
coerente con un allenamento in stile vinyasa, dove il respiro lega i
movimenti invece di segmentarli. I 10 minuti di yoga restano un ancoraggio
fisso della sessione (non ancora modellati: la routine yoga varia seduta
per seduta — vedi `docs/ROADMAP.md` punto 7 — quindi non si presta allo
stesso schema `SessionStep` finché non ha una struttura più ripetibile).
Eccezione al respiro scandito: un tentativo vicino al massimale su un
nuovo esercizio dovrebbe restare a respiro libero (`BreathPacing.libero`),
perché forzare il ritmo del respiro in quel caso sarebbe controproducente.

**Respiro scandito da toni** (`assets/audio/inspiro.wav`, `espiro.wav`,
generati come toni sintetici tipo campana/singing-bowl, non registrazioni):
recupero sempre a respiro libero (nessun tono); esercizi "soft" un atto
respiratorio ogni 5 secondi; esercizi "hard" ogni 2 secondi
(`BreathPacing`, `lib/models/breathing.dart`). Il blocco di recupero
avanza da solo dopo una durata suggerita (`RecoveryStep.suggestedDuration`,
30-60s) — decisione esplicita dell'utente: NON aspetta un tocco manuale.

**Voce**: sintesi vocale del telefono in italiano (`flutter_tts`), non un
servizio esterno — coerente con la scelta "niente backend dedicato" della
sezione 4. Annuncia il nome dell'esercizio a ogni cambio passo e i secondi
rimanenti solo nei momenti chiave (a metà passo, per passi più lunghi di
20s, e l'ultimo conto alla rovescia 5-4-3-2-1), non a intervalli fissi, per
non essere invasiva.

**Design del motore**: `TrainingSessionPlayer.stateAt(Duration elapsed)` è
una funzione pura del tempo trascorso, senza `Timer` né stato mutabile —
lo stesso principio di `ProgressController` (sezione 2): è quello che
permette di testare fasi di respiro e annunci con `Duration` arbitrarie in
`test/session_player_test.dart`, senza montare widget né aspettare timer
reali. Il collegamento a un `Timer` vero, alla voce e ai toni vive separato,
in `SessionPlaybackController` (`lib/models/session_playback_controller.dart`)
e nella UI (`lib/screens/session_screen.dart`).

**Non ancora fatto**: `demoFlowSession` (in `lib/models/session.dart`) è
una sessione dimostrativa sui 4 esercizi seed, per provare l'engine
end-to-end — non un vero piano settimanale. Generare sessioni reali dal
database di esercizi (una volta più ampio, vedi `docs/ROADMAP.md` punto 3)
è un passo successivo.

### 9.1 Aggiustamenti dopo la prima prova pratica (2026-09-21)

- **Pacing "soft" accorciato da 5s a 4s per atto respiratorio**
  (`BreathPacing.soft.breathPhaseDuration`): alla prima prova reale il
  ritmo a 5s risultava troppo lento. Il pacing "hard" (2s) resta invariato.
- **Comandi avanti/indietro tra un passo e l'altro**
  (`SessionPlaybackController.skipToNextStep`/`skipToPreviousStep`,
  pulsanti nella `session_screen.dart`): "avanti" salta all'inizio del
  passo successivo; "indietro" torna all'inizio del passo corrente, o a
  quello precedente se siamo nei primi 3 secondi del passo corrente
  (comportamento comune nei lettori multimediali). Un salto azzera gli
  annunci/toni "in sospeso" (non riannuncia soglie del tratto saltato) e
  funziona sia in pausa che durante la riproduzione.
- Per rendere possibili i salti, `SessionPlaybackController` non legge più
  l'elapsed direttamente da `Stopwatch` (che misura solo tempo reale
  trascorso da quando è partito, non è "riavvolgibile"): tiene un
  `_baseElapsed` congelato più uno `Stopwatch` che misura solo il tratto
  dall'ultimo avvio/salto — l'elapsed vero è la somma dei due. Il motore
  puro (`TrainingSessionPlayer`) non cambia: ha solo un nuovo metodo,
  `startOf(stepIndex)`, che dà l'istante di inizio di un passo qualsiasi.

## 10. Punteggi per muscolo/abilità e prerequisiti multipli (obiettivi composti)

Deciso con l'utente il 2026-09-22: oltre a `FitnessCategory` (che resta,
per organizzare le schermate in "Spinta"/"Trazione"/ecc.) e al livello
dentro una categoria, ogni `Exercise` porta ora `scores`: quanto allena
ciascuna combinazione muscolo × abilità (`lib/models/muscle.dart`,
`lib/models/ability.dart`), su una scala 0-3. Le abilità sono forza,
flessibilità, equilibrio, coordinazione — ortogonali alla categoria
("spinta" è un pattern di movimento, "forza" è un tipo di capacità: un
esercizio di spinta può allenare forza E equilibrio insieme, es. la
verticale). L'elenco dei muscoli è allineato alla tassonomia di
free-exercise-db (sezione 3) per facilitare un futuro import.

`ProgressController.abilityScoreFor(muscle, ability, allExercises)` somma
i punteggi tra gli esercizi ACQUISITI — risponde a "quanta forza ho
costruito sulle spalle", indipendentemente da quale categoria/catena ha
portato quel lavoro. `musclesCovered` elenca i muscoli presenti nel
database attuale, per popolare una vista "per muscolo" senza doverli
elencare a mano.

**Prerequisiti**: `Exercise.prerequisiteId` (singolo) è diventato
`Exercise.prerequisiteIds` (un `Set<String>`): un esercizio si sblocca
solo se TUTTI i suoi prerequisiti sono acquisiti (grafo vero — AND fra
prerequisiti — non solo una catena). Motivazione diretta dell'utente: un
obiettivo composto come la verticale libera richiede SIA un prerequisito
di equilibrio (verticale al muro) SIA uno di forza spinta (piegamento
standard) — due catene diverse, anche di categorie diverse, che devono
convergere. `seedExercises` in `exercise.dart` include `verticale-libera`
come esempio concreto di questo pattern.

Non ancora implementato: rilevamento di cicli nel grafo dei prerequisiti
(se mai un dataset importato ne introducesse uno per errore, `isUnlocked`
si limiterebbe a non sbloccare mai quell'esercizio, senza segnalarlo) — da
tenere presente quando si importerà un dataset esterno (punto 1 di
`docs/ROADMAP.md`). Una UI dedicata per esplorare i punteggi per
muscolo/abilità (es. una vista "quanto equilibrio ho sulle gambe") non è
ancora stata costruita: per ora `abilityScoreFor`/`musclesCovered` sono
solo motore, senza schermata.

## 11. Affinamento schema attrezzatura/muscoli/categorie, prima del popolamento (2026-09-22)

Prima di avviare il popolamento vero del database (`docs/ROADMAP.md`
punto 1), l'utente ha rivisto e approvato quattro parametri dello schema
che lo regolano, sulla base della ricerca fonti di
`ricerca-fondamenta-redesign.md` (sezioni 3-4, progetto Claude):

1. **Nuova `FitnessCategory.acrobazie`**: prima non esisteva nessuna
   categoria per l'obiettivo trasversale "acrobazie" (uno dei 4 di
   `piano-allenamento.md`, insieme a loto/verticale/spaccate). A
   differenza di equilibrio/flessibilità, coordinazione era presente solo
   come `Ability` (punteggio), senza una propria catena propedeutica: ora
   ha una `FitnessCategory` dedicata, coerente col trattamento delle
   altre skill trasversali.
2. **`Muscle.dorsaliMedi`**: aggiunto per separare "lats" (`dorsali`,
   trazioni verticali) da "middle back" (romboidi/trapezio medio, lavoro
   dei rematori orizzontali) — due valori distinti nello schema di
   free-exercise-db (verificato su `schema.json` il 2026-09-22), prima
   collassati insieme su `dorsali`.
3. **`Equipment` semplificato**: rimosso `Equipment.corpoLibero`. Il
   corpo è sempre disponibile per chiunque, quindi non è mai un vincolo
   di filtro reale — tenerlo come valore esplicito produceva incoerenze
   (alcuni esercizi a corpo libero lo includevano nel set, altri no, es.
   `rematore-fascia` prima del fix). Ora un insieme vuoto significa "solo
   corpo libero"; `Equipment` elenca solo `muro` e `fasciaElastica`, le
   uniche due voci che restringono davvero cosa è allenabile.
4. **Import in due livelli**: dato che free-exercise-db non ha alcun
   concetto di `scores` (muscolo × abilità) né di `prerequisiteIds` —
   solo `primaryMuscles`/`secondaryMuscles`, `equipment`, `level`
   assoluto (beginner/intermediate/expert, non convertibile nel nostro
   `level` relativo alla catena) — l'import automatico può popolare in
   massa un **catalogo** (id/nome/muscoli/attrezzatura/istruzioni,
   navigabile ma non usato per generare sedute), mentre `scores` e
   `prerequisiteIds` restano curatela manuale per il sottoinsieme
   **programmato** che entra davvero nel motore/nelle sedute generate.
   Decisione esplicita dell'utente per evitare un motore che sembra
   "intelligente" su punteggi in realtà non verificati.

Questi 4 punti erano gli unici parametri dello schema considerati aperti
prima del popolamento vero del database — la struttura di fondo
(categoria × livello × prerequisiti-grafo, muscolo × abilità) resta
quella descritta in sezione 10.

## 12. Popolamento del database: catene curate + script di import (2026-09-22)

Eseguito il piano approvato in sezione 11 (punto 4), con un adattamento
pratico scoperto durante l'esecuzione.

**Catene curate a mano, complete dalla base al traguardo** (in
`seedExercises`, `lib/models/exercise.dart`), con `scores`/
`prerequisiteIds` reali:

- **Verticale** (`FitnessCategory.equilibrio`): wall walk → verticale al
  muro → tap alle spalle al muro → kick-up al muro → verticale libera (5
  esercizi, gli ultimi due preesistenti sono stati ricollegati alla nuova
  catena — `verticale-libera` ora dipende da `verticale-kick-up-al-muro`
  invece che direttamente da `verticale-al-muro`).
- **Loto** (`FitnessCategory.flessibilita`): 90/90 transitions → half
  lotus passivo → half lotus attivo senza mani → lotus assistito → lotus
  completo (5 esercizi), trascritta da `piano-allenamento.md`.
- **Spaccate** (stessa categoria, catena parallela): affondo/half split →
  isometrie → range più profondo → spaccata assistita → spaccata
  completa (5 esercizi), trascritta da `piano-allenamento.md`.
- **Acrobazie** (`FitnessCategory.acrobazie`, nuova): animal flow →
  cartwheel prep → kick-up laterale → ruota completa (4 esercizi),
  costruita da zero (non c'era una fonte scritta da Pietro per questa,
  solo il blocco "Prima acrobazia" della seduta C in
  `piano-allenamento.md`) — l'ultimo step porta un avviso esplicito a non
  provarlo da soli senza supervisione.

Totale `seedExercises`: 22 (5 preesistenti + 17 nuovi). Spinta/trazione/
gambe restano ridotte a pochi esempi: quel volume è compito del catalogo
sotto, non di questa lista curata.

**Import "catalogo" — bloccato dall'ambiente di Claude, spostato in uno
script che esegui tu**: il piano prevedeva un import meccanico diretto da
free-exercise-db. In pratica, sia gli strumenti di lettura web di Claude
(troncano/non filtrano in modo affidabile un file JSON di ~870 elementi)
sia l'accesso di rete dell'ambiente cloud dove gira Claude (proxy che
blocca `raw.githubusercontent.com`, verificato con un test diretto) non
permettono di scaricare ed elaborare l'intero dataset da qui. Soluzione:
- **`lib/models/catalog_exercise.dart`**: nuova classe `CatalogExercise`
  (id/nome/muscoli/attrezzatura/istruzioni, NIENTE `scores`/
  `prerequisiteIds` — la fonte non li ha) — non entra nel motore di
  progressione, solo per una futura schermata di consultazione libera.
- **`tool/import_free_exercise_db.dart`**: script Dart pronto
  (`dart run tool/import_free_exercise_db.dart`) che scarica
  `exercises.json`, filtra `equipment` su `body only`/`bands`, mappa i
  muscoli sulla nostra tassonomia e scrive `lib/data/catalog_exercises.dart`.
  Va eseguito da un terminale con Internet vero (il tuo Mac), non da qui.
  Richiede il pacchetto `http` (aggiunto ai `dev_dependencies`).
- **`lib/data/catalog_exercises.dart`**: per ora un placeholder (lista
  vuota), così il progetto compila anche prima di lanciare lo script;
  verrà sovrascritto dallo script stesso quando lo esegui.

Prossimo passo pratico per Pietro: `flutter pub get` (per scaricare
`http`), poi `dart run tool/import_free_exercise_db.dart` dal proprio
terminale.

## 13. Generazione reale delle sessioni (2026-09-22)

Sostituito `demoFlowSession` come sessione lanciata dall'app
(`lib/screens/home_screen.dart`) con `generateSession`
(`lib/models/session_generator.dart`), che compone una `TrainingSession`
vera dal database di esercizi (`seedExercises`, ora 22 — sezione 12) e
dai progressi correnti (`ProgressController`), invece di una sequenza
fissa. `demoFlowSession` resta in `session.dart` come esempio/fixture, non
più collegata all'app.

**Algoritmo (funzione pura, testata in `test/session_generator_test.dart`,
stesso principio di `TrainingSessionPlayer.stateAt`)**: scorre le
categorie in un ordine pensato per alternare lavoro hard e soft (non a
blocchi separati, coerente con la sezione 9), e per ciascuna chiede a
`ProgressController.nextStepFor` il prossimo esercizio sbloccato-non-
acquisito; le categorie ancora senza esercizi (coreFrontale/coreLaterale/
corePosteriore/bodyline/gambe) vengono saltate senza errori. Ogni
esercizio scelto diventa un `ExerciseStep` (hard, 40s, tranne
flessibilità che è soft, 60s), con un `RecoveryStep` tra un esercizio e
il successivo. Se un giro completo delle categorie non basta a
raggiungere la durata target (default 20', coerente con "20' sostanza"
di `piano-allenamento.md`), rifà un altro giro — ripetere lo stesso
esercizio è normale (un secondo "set") — fino a un tetto di round per
evitare loop quando il database non ha abbastanza contenuto sbloccato.

**Numeri non ancora tarati su una prova pratica** (a differenza del
pacing del respiro, sezione 9.1): 40s/60s per esercizio e l'ordine delle
categorie sono ipotesi ragionevoli di partenza, non richieste
esplicitamente da Pietro — da aggiustare dopo che li prova sul
dispositivo, con lo stesso processo già usato per il pacing (5s→4s).

**Non ancora affrontato**: uno "scheduling" settimanale vero (quante
sessioni a settimana, giorni di riposo) — `generateSession` produce UNA
sessione bilanciata al momento della chiamata, non un calendario. Per ora
l'utente rilancia la generazione ogni volta che si allena (il pulsante in
`home_screen.dart` la rigenera a ogni tocco, riflettendo i progressi nel
frattempo).

## 14. Grafo dei prerequisiti, disegnato nell'app (2026-09-22)

Su richiesta di Pietro ("mettiamola direttamente nell'applicativo"),
aggiunta una schermata che disegna per davvero il grafo dei prerequisiti
di tutti i `seedExercises` insieme (non filtrato per categoria: serve
proprio a mostrare gli obiettivi composti che attraversano più categorie,
es. `verticale-libera`), raggiungibile dall'icona 🔗 nella app bar della
home.

- **`lib/models/graph_layout.dart`** (`computeGraphLayout`, funzione
  pura, testata in `test/graph_layout_test.dart`): calcola un layout "a
  livelli", non force-directed. La colonna di un esercizio è la sua
  profondità nel grafo dei prerequisiti (0 = nessun prerequisito,
  altrimenti 1 + la profondità massima — non minima — tra i suoi
  prerequisiti: un obiettivo composto va oltre il PIÙ profondo dei suoi
  prerequisiti). Dentro una colonna, i nodi sono ordinati per categoria
  poi nome, per un risultato deterministico. Protezione difensiva contro
  cicli (gap noto, sezione 10): un ciclo tronca la ricorsione invece di
  entrare in loop infinito, senza diagnosticarlo esplicitamente.
- **`lib/screens/graph_screen.dart`** (`GraphScreen`): disegna nodi
  (`Card` posizionate con `Positioned` dentro uno `Stack`) e archi
  (`CustomPainter`, curve di Bézier con una piccola freccia), dentro un
  `InteractiveViewer` per pan/zoom — nessuna libreria esterna di grafi.
  Bordo colorato = stato di progressione (locked/unlocked/mastered,
  stessa logica di `CategoryScreen`); pallino colorato = categoria.
  Toccando un nodo si apre un pannello con dettagli (livello,
  prerequisiti per nome, cue, tips).

Le coordinate pixel dei nodi e degli archi sono calcolate dalla STESSA
formula in entrambi i punti (colonna/riga → offset), non da geometria
letta a runtime da widget già disegnati: evita per costruzione il classico
bug "la linea non combacia con la casella".

## 15. Nuove skill: planche, pistol squat, L-sit/dragon flag, crow/elbow lever, HSPU, ponte (2026-09-23)

Decisioni prese con Pietro il 2026-09-23 (dettaglio completo in
`ricerca-fondamenta-redesign.md` del progetto Claude, sezione 8), poi
implementate lo stesso giorno: 30 nuovi esercizi curati a mano aggiunti a
`seedExercises` (`lib/models/exercise.dart`), portando il totale da 22 a
52. Nessuna modifica al modello dati: stesso schema `Exercise` di sempre
(`category`, `equipment`, `level`, `prerequisiteIds`, `scores`, `cue`,
`tips`).

**Vincolo attrezzatura confermato**: front lever, back lever, muscle-up,
one-arm pull-up e human flag restano escluse dal catalogo — richiedono
una sbarra o anelli per appendersi, non presenti nell'`Equipment` attuale
(solo `muro` e `fasciaElastica`). Se in futuro si aggiungesse una sbarra,
andrebbe prima esteso l'enum `Equipment`.

**Nuove catene, per categoria**:

- **`FitnessCategory.spinta`** (prima 2 esercizi, ora 10): due catene si
  diramano entrambe da `pushup-standard` — planche (`planche-lean` →
  `planche-tuck` → `planche-tuck-avanzata` → `planche-straddle` →
  `planche-completa`) e handstand push-up (`pike-pushup` →
  `hspu-negativa` → `hspu-completa`). `hspu-negativa` è un altro esempio
  di obiettivo composto (sezione 10): richiede sia `pike-pushup`
  (spinta) sia `verticale-al-muro` (equilibrio).
- **`FitnessCategory.gambe`** (prima vuota, ora 5 esercizi): prima catena
  della categoria, pistol squat (`squat-assistito` → `squat-bulgaro` →
  `pistol-squat-assistito` → `pistol-squat-negativo` →
  `pistol-squat-completo`).
- **`FitnessCategory.coreFrontale`** (prima vuota, ora 7 esercizi): prima
  catena della categoria — L-sit (`l-sit-tuck-hold` → `l-sit-una-gamba`
  → `l-sit-completo`), da cui si diramano `v-sit` e la catena dragon flag
  (`dragon-flag-negativa` → `dragon-flag-ginocchia-piegate` →
  `dragon-flag-completo`).
- **`FitnessCategory.equilibrio`** (prima 5 esercizi, ora 10): prosegue
  oltre la catena verticale con `crow-pose-assistito` (prerequisito
  incrociato da `pushup-standard`, indipendente dalla catena verticale)
  → `crow-pose-completo`, da cui si diramano `crane-pose` e la catena
  elbow lever (`elbow-lever-assistito` → `elbow-lever-completo`).
- **`FitnessCategory.corePosteriore`** (prima vuota, ora 5 esercizi):
  prima catena della categoria, ponte/wheel pose (`ponte-spalle` →
  `ponte-testa` → `ponte-completo` → `ponte-a-muro` →
  `ponte-avanzato`).

Restano vuote/ridotte `trazione` (1 esercizio), `coreLaterale` e
`bodyline` (0): non toccate in questo giro, fuori dallo scope delle 8
skill approvate da Pietro il 2026-09-23.

**Nota su `nextStepFor` e catene multiple nella stessa categoria**
(`lib/models/progress.dart`): quando una categoria contiene più diramazioni
allo stesso livello di prerequisito (es. `v-sit` e `dragon-flag-negativa`,
entrambi sbloccati da `l-sit-completo`), `nextStepFor` propone quello con
`level` più basso tra i due — non un errore, ma una scelta di priorità:
i numeri di `level` dentro una categoria ora ordinano anche tra
diramazioni parallele, non solo dentro una singola catena lineare.

## 16. Legenda del grafo e grado di maturazione per esercizio (2026-09-23)

Decisioni prese con Pietro il 2026-09-23 (dettaglio completo in
`ricerca-fondamenta-redesign.md` del progetto Claude, sezione 8d), poi
implementate lo stesso giorno.

### Legenda del grafo

`GraphScreen` (sezione 14) ha ora un'icona informazioni nella barra
superiore che apre una `DraggableScrollableSheet` con: un pallino
colorato per ciascun `FitnessCategory` (stesso colore usato per i nodi,
`Colors.primaries[category.index % Colors.primaries.length]`), un
pallino per ciascuno dei tre stati (`ExerciseStatus.locked/unlocked/
mastered`, stesso colore del bordo dei nodi), e una spiegazione testuale
del layout (colonne = profondità di prerequisito, frecce = direzione
"prerequisito di"). Nessuna modifica al calcolo del layout o ai dati:
solo lettura degli enum esistenti.

### Grado di maturazione: un segnale continuo, separato dallo stato binario

Fino a oggi il progresso su un esercizio era binario:
`ExerciseStatus.locked/unlocked/mastered` (`lib/models/progress.dart`),
impostato a mano da chi usa l'app. Pietro ha chiesto un segnale più
fine, alimentato dall'uso reale: ogni volta che un esercizio viene
allenato, in base a come è andato, guadagna o perde punti in un "grado
di maturazione" percentuale (0-100%), finché non si è pronti per un
salto di difficoltà.

**Scelta deliberata**: questo grado di maturazione è un asse
*indipendente* da `ExerciseStatus.mastered`, non un rimpiazzo. Portare
un esercizio al 100% di maturazione NON lo marca automaticamente
`mastered` e non cambia da solo la rotazione di `generateSession` —
serve invece a proporre una scelta esplicita a chi si allena (vedi
sotto "Il momento della scelta"). Questo era un requisito esplicito di
Pietro: il sistema deve *chiedere*, non decidere da solo.

**Nuovo enum** (`lib/models/progress.dart`):

```dart
enum ExerciseOutcome { andataBene, cosiCosi, nonAncora }

extension ExerciseOutcomeDelta on ExerciseOutcome {
  double get maturityDelta => switch (this) {
    ExerciseOutcome.andataBene => 25,
    ExerciseOutcome.cosiCosi => 8,
    ExerciseOutcome.nonAncora => -15,
  };
}
```

I tre esiti e i relativi delta sono una prima taratura ragionevole (4
sessioni "andata bene" di fila portano da 0 a 100%; un "non ancora"
pesa più di un "così così" per scoraggiare di correre troppo) — numeri
da rivedere con l'uso reale, non un valore definitivo.

**Nuovo stato in `ProgressController`**: due mappe parallele a quelle
già esistenti per lo stato bloccato/sbloccato/acquisito —
`_maturity: Map<String, double>` (grado 0-100 per id esercizio) e
`_challengeLevel: Map<String, int>` (livello di sfida accumulato per id
esercizio). Nuovi metodi:

- `maturityOf(Exercise)` — grado attuale (0 se mai registrato).
- `recordOutcome(String exerciseId, ExerciseOutcome outcome)` — applica
  `maturityDelta`, clampato a [0, 100]. Chiamato dal recap di fine
  sessione (vedi sotto).
- `hasPendingUpgrade(Exercise)` — true solo se la maturazione è a 100%
  E l'esercizio non è già `mastered` a mano: è il segnale che fa
  scattare la richiesta pre-sessione.
- `challengeLevelOf(Exercise)` — livello di sfida accumulato, usato da
  `generateSession` per allungare la durata (vedi sotto).
- `resolveUpgrade(String exerciseId, {required bool moveToNext})` —
  risolve la richiesta pendente. Se `moveToNext` è true, marca
  l'esercizio `mastered` (si passa al prossimo della catena, la
  rotazione normale se ne occupa da qui). Se è false, incrementa
  `challengeLevelOf` di uno (si resta sullo stesso esercizio ma più
  impegnativo). In entrambi i casi la maturazione torna a 0: il
  ciclo di acquisizione riparte da capo, sia sul nuovo esercizio sia
  sulla versione più difficile dello stesso.

### Il momento della scelta: prima della sessione, non durante

Per rispettare la richiesta di Pietro ("prima di mettere play... mi
viene richiesto se voglio aumentare il numero di ripetizioni/sostituire
con un esercizio più impegnativo"), la richiesta di upgrade non appare
a fine sessione insieme al recap, ma **subito prima** di generare la
sessione successiva: `HomeScreen._startSession` controlla
`hasPendingUpgrade` su tutti gli esercizi sbloccati, e se ce ne sono
mostra un dialogo (`_askUpgradeChoice`) per ciascuno, uno alla volta,
prima di chiamare `generateSession`. Solo dopo aver risolto ogni
richiesta pendente la sessione viene generata e mostrata.

### Effetto sulla sessione generata: livello di sfida → più durata

Il modello attuale di `SessionStep`/`ExerciseStep` è basato sul tempo
(durata per esercizio), non sulle ripetizioni — introdurre un vero
conteggio di ripetizioni sarebbe un cambio di schema più ampio, non
richiesto per ora. Come approssimazione dichiarata, `generateSession`
(`lib/models/session_generator.dart`) allunga la durata base assegnata
a un esercizio di 15 secondi per ogni livello di sfida accumulato
(`Duration(seconds: 15 * progress.challengeLevelOf(next))`, sommati
alla durata di pacing già calcolata). Non è un rimpiazzo del modello a
ripetizioni che si potrà introdurre in futuro, solo un modo per far
sentire l'effetto del livello di sfida da subito.

### Raccolta dell'esito: recap di fine sessione

`SessionScreen` (sezione 9) ora richiede anche un `progress:
ProgressController`. Al termine della sessione, `_SessionComplete`
(schermata statica) è stato sostituito da `_SessionRecap`, che elenca
gli esercizi distinti affrontati nella sessione appena conclusa e
chiede per ciascuno, con tre pulsanti, come è andato
(`ExerciseOutcome`), chiamando `progress.recordOutcome` alla
pressione. Coerente con la preferenza di Pietro ("tutto alla fine con
un recap... domanda rapida è ok") invece che un'interruzione durante
ogni esercizio.

### Nuova schermata "Cosa so fare"

`lib/screens/maturity_screen.dart` (`MaturityScreen`), raggiungibile
dalla home con un'icona dedicata nella barra superiore: elenca TUTTI
gli esercizi del catalogo, raggruppati per categoria e ordinati per
livello — inclusi quelli ancora bloccati, a differenza di
`CategoryScreen` che mostra solo quelli sbloccabili/sbloccati. Per
ogni esercizio mostra il pallino di stato, una barra di progresso con
il grado di maturazione, ed eventuale livello di sfida raggiunto o
segnalazione "pronto per il prossimo passo". Le due schermate sono
complementari: il grafo (sezione 14) risponde a "cosa sblocca cosa",
"Cosa so fare" risponde a "quanto sono solido su quello che ho già
sbloccato".

### Copertura di test

`test/progress_test.dart`: nuovo gruppo con 8 test su `maturityOf`,
`recordOutcome` (esiti positivi/negativi, clamping a [0,100]),
`hasPendingUpgrade` (vero solo a maturazione piena e non già
`mastered` a mano) e `resolveUpgrade` (entrambi i percorsi
`moveToNext: true/false`, accumulo del livello di sfida su più cicli).
`test/session_generator_test.dart`: un test verifica che un livello di
sfida 1 allunghi la durata assegnata di 15s rispetto alla base.

## 17. Rifinitura granularità delle 8 catene (planche, pistol squat, L-sit/dragon flag, crow/elbow lever, HSPU, ponte) (2026-09-23)

Pietro ha chiesto esplicitamente, dopo la prima tranche di nuove skill
(sezione 15), di aggiungere altri step intermedi anche a quelle 8 catene,
non solo a quelle future ("Rivedi anche le 8 appena fatte"). 12 nuovi
esercizi curati a mano aggiunti a `seedExercises`, portando il totale da
52 a 64. Nessuna modifica al modello dati: stesso schema `Exercise`,
stessi enum. Livelli (`Exercise.level`) rinumerati all'interno di ogni
categoria toccata per tenere una progressione leggibile — `level` resta
un valore puramente relativo/di visualizzazione (vedi la docstring della
classe `Exercise`), quindi la rinumerazione non ha effetti sul motore di
sblocco, che si basa solo su `prerequisiteIds`.

**Nuovi step, per catena**:

- **Planche** (`FitnessCategory.spinta`): `planche-lean-avanzata` tra
  `planche-lean` e `planche-tuck` (stessa posizione del lean, più
  inclinata e tenuta più a lungo, senza una forma nuova da imparare);
  `planche-una-gamba` tra `planche-tuck-avanzata` e `planche-straddle`
  (una gamba distesa dalla advanced tuck, passaggio classico prima di
  aprire entrambe le gambe in straddle).
- **Handstand push-up** (`FitnessCategory.spinta`): `pike-pushup-rialzato`
  tra `pike-pushup` e `hspu-negativa` (piedi su un rialzo, avvicina
  gradualmente l'angolo a quello della verticale); `hspu-parziale` tra
  `hspu-negativa` e `hspu-completa` (risalita parziale dalla parte più
  facile del movimento, vicino alla verticale).
- **Pistol squat** (`FitnessCategory.gambe`): `pistol-squat-su-rialzo`
  (box pistol) tra `squat-bulgaro` e `pistol-squat-assistito` (stessa
  meccanica del pistol assistito ma senza mani, sedendosi su un rialzo
  che si abbassa nel tempo); `pistol-squat-parziale` tra
  `pistol-squat-assistito` e `pistol-squat-negativo` (range parziale
  senza supporto, prima della negativa completa).
- **L-sit / dragon flag** (`FitnessCategory.coreFrontale`):
  `hollow-body-hold` come nuovo esercizio base della categoria (prima di
  `l-sit-tuck-hold`, che ora lo richiede come prerequisito) — la tenuta
  di base che serve a quasi tutti gli esercizi della categoria, non
  c'era ancora un passo dedicato solo a quella; `dragon-flag-tenuta-parziale`
  tra `dragon-flag-negativa` e `dragon-flag-ginocchia-piegate` (tenuta
  isometrica a metà percorso, spesso il punto più debole della discesa).
- **Crow/crane pose ed elbow lever** (`FitnessCategory.equilibrio`):
  `crow-pose-su-rialzo` prima di `crow-pose-assistito` (mani su un
  rialzo basso, accorcia la distanza da percorrere in avanti con il
  peso); `elbow-lever-una-gamba` tra `elbow-lever-assistito` ed
  `elbow-lever-completo` (una gamba distesa alla volta, come già fatto
  per `planche-una-gamba`).
- **Ponte/wheel pose** (`FitnessCategory.corePosteriore`):
  `estensione-spalle-a-muro` come nuovo esercizio base della categoria
  (prima di `ponte-spalle`, che ora la richiede come prerequisito) — una
  mobilizzazione di spalle/schiena al muro, non un vero ponte, pensata
  per preparare la mobilità richiesta più avanti nella catena;
  `ponte-testa-mani-vicine` tra `ponte-testa` e `ponte-completo`
  (cammina con le mani più vicine ai piedi, riducendo gradualmente il
  peso portato dalla testa).

**Numerazione dei livelli aggiornata** per le cinque categorie toccate
(`spinta` limitatamente ai rami planche/HSPU, `gambe`, `coreFrontale`,
`equilibrio` limitatamente al ramo crow/elbow lever, `corePosteriore`):
i valori di `level` sono stati rinumerati per intero per restare
contigui e leggibili nella schermata "Cosa so fare" (sezione 16) e nel
grafo (sezione 14), che ordinano/dispongono per livello. Nessun altro
esercizio fuori da queste catene è stato toccato.

## 18. Checkup di maturazione obbligatorio, periodico e in ordine fisso (2026-09-23)

Decisione presa con Pietro il 2026-09-23, subito dopo la rifinitura di
granularità (sezione 17): il sistema di maturazione (sezione 16) da solo
non basta, perché aggiorna la maturità solo degli esercizi che compaiono
in una sessione generata — non ricontrolla mai, di sua iniziativa, se una
skill già acquisita è ancora solida. Pietro ha chiesto due cose precise:
un checkup **obbligatorio e periodico**, e che i suoi esercizi **non
vengano mai eseguiti in ordine sparso**, per non disperdere energie
saltando da una catena all'altra.

Chiarito con Pietro (via domande dirette) prima di implementare:
periodicità basata su un numero di sessioni normali completate (non sul
calendario), vincolo "obbligatorio" realizzato bloccando la prossima
sessione normale finché il checkup non è fatto, ed esecuzione reale degli
esercizi (non solo domande) — ma **nella loro forma minima**, per non
stancare troppo ("nella forma minima, sennò ci si stanca"): il checkup
verifica le basi degli esercizi già acquisiti, non ripete la variante più
impegnativa raggiunta nel tempo.

### Periodicità e vincolo (`lib/models/progress.dart`)

`ProgressController` tiene un contatore `_sessionsSinceCheckup`,
incrementato da `recordSessionCompleted()` a ogni sessione NORMALE
portata a termine (chiamato una sola volta, dal `initState` del recap di
`SessionScreen` quando `isCheckup` è falso). Quando il contatore raggiunge
`ProgressController.checkupIntervalSessions` (valore di partenza: 6,
NON ancora tarato su una prova pratica, stesso spirito delle altre
costanti numeriche di questo file), `isCheckupDue` diventa vero.

`HomeScreen._startSession` controlla `isCheckupDue` PRIMA di generare la
sessione normale richiesta dal tocco su "Inizia sessione": se è dovuto,
genera ed avvia invece una sessione di checkup (`generateCheckupSession`),
e la sessione normale richiesta non parte in quel tocco — occorre toccare
di nuovo "Inizia sessione" una volta chiuso il checkup. Questo è il
meccanismo che rende il checkup "obbligatorio" (non un promemoria
ignorabile): non c'è un modo per avviare una sessione normale mentre un
checkup è dovuto, a parte completarlo. Se non c'è ancora nulla di
acquisito (utente ai primissimi passi), `exercisesForCheckup` è vuoto e il
checkup si chiude da solo senza interrompere nessuno
(`ProgressController.completeCheckup()` chiamato subito).

### Cosa include il checkup, e in che ordine

`ProgressController.exercisesForCheckup` restituisce SOLO gli esercizi
già acquisiti (`isMastered`) — non quelli ancora in costruzione, che sono
già coperti dal recap di fine sessione normale (sezione 16). Ordinati per
`FitnessCategory` (nell'ordine di dichiarazione dell'enum, che raggruppa
schemi di movimento simili: spinta, trazione, core-*, bodyline, gambe,
flessibilità, equilibrio, acrobazie) e poi per `level` crescente — MAI
nell'ordine (sparso) in cui sono stati acquisiti nel tempo. Questo ordine
è deliberatamente DIVERSO da quello di `generateSession`
(`_categoryOrder`, sezione 13), che alterna apposta categorie "hard" e
"soft" per il flow di una sessione vera: nel checkup l'obiettivo opposto
— restare il più possibile sullo stesso schema di movimento prima di
cambiare — è proprio quello che evita di disperdere energie.

`generateCheckupSession` (`lib/models/session_generator.dart`) genera una
`TrainingSession` da questa lista: un `ExerciseStep` per esercizio (mai
ripetuto, a differenza di `generateSession` che può fare più "giri"),
sempre con la durata di BASE di `_durationForPacing` — MAI il bonus per
`challengeLevelOf` che invece `generateSession` applica: e' la "forma
minima" richiesta da Pietro. Un `RecoveryStep` tra un esercizio e il
successivo, come nelle sessioni normali.

### Esito del checkup: più diretto del recap normale

`SessionScreen` accetta ora un flag `isCheckup`. Nel recap di fine
sessione, se `isCheckup` è vero: il titolo diventa "Checkup completato",
la valutazione di OGNI esercizio è obbligatoria per poter tornare alla
home (il pulsante resta nascosto finché non sono stati valutati tutti —
diversamente dal recap normale, dove restava facoltativo), e ogni voto
chiama `ProgressController.recordCheckupOutcome` invece di
`recordOutcome`:

- **Andata bene**: la base regge, `maturityOf` torna al 100%, resta
  acquisito.
- **Così così**: resta acquisito (non si perde la skill), ma `maturityOf`
  scende al 50% — un segnale visibile in "Cosa so fare" (sezione 16) che
  serve un ripasso, senza conseguenze automatiche più dure.
- **Non ancora**: l'esercizio viene tolto da `isMastered` (torna
  `unlocked`, rientra nella rotazione di `generateSession` come un
  esercizio qualsiasi da riallenare) con `maturityOf` a 30% — una
  competenza residua, non si riparte da zero assoluto. Effetto a cascata
  VOLUTO: se altri esercizi avevano questo come prerequisito
  (`Exercise.prerequisiteIds`), tornano `ExerciseStatus.locked` finché non
  viene riacquisito — conseguenza diretta di `isUnlocked`, nessuna logica
  nuova da scrivere per questo.

Al termine del checkup (tutti valutati, o nessun esercizio da valutare),
`ProgressController.completeCheckup()` azzera `sessionsSinceCheckup`.

### Nota su persistenza e abbandono a metà

Come il resto di `ProgressController` (sezione "Persistenza non ancora
implementata" nella docstring della classe), `sessionsSinceCheckup` vive
solo in memoria: si azzera a ogni riavvio dell'app, non solo a checkup
completato — da rivedere quando la persistenza locale (`docs/ROADMAP.md`)
verrà affrontata. Se l'utente abbandona un checkup a metà (tasto indietro
prima di valutare tutto), `completeCheckup()` non viene mai chiamato: al
prossimo tocco su "Inizia sessione" il checkup ripropone semplicemente
tutti gli esercizi acquisiti (comprese le valutazioni già date in quel
tentativo, che restano registrate) — non è stata aggiunta una schermata di
conferma o un blocco della navigazione per impedire l'abbandono, il
vincolo "obbligatorio" agisce solo all'avvio della prossima sessione
normale.

## 19. Obiettivi generali di allenamento (2026-09-23)

Prima di suddividere l'allenamento in tre sessioni settimanali A/B/C da
max 30 minuti (non ancora costruite, vedi `docs/ROADMAP.md`), serve un
posto dove registrare COSA si vuole raggiungere: `lib/models/goals.dart`
(`GoalsController`) e `lib/screens/goals_screen.dart` (`GoalsScreen`,
raggiungibile dall'icona "Obiettivi" nell'AppBar di `HomeScreen`).

Deliberatamente DISACCOPPIATO dalla generazione delle sessioni: impostare
un obiettivo qui non genera ancora nessuna sessione A/B/C, né cambia
`generateSession`/`generateCheckupSession` (`session_generator.dart`).
Serve solo a registrare gli obiettivi; il lavoro di usarli per generare
sessioni mirate resta futuro.

### Due forme di obiettivo

Ispirato al vecchio piano scritto a mano (progetto Claude,
`claude/piano-allenamento.md`), che usava sia obiettivi nominati con
priorità ("loto (priorità 1)", "verticale (priorità 2)") sia enfasi per
gruppo muscolare ("spalle (priorità 1 forza)"):

1. **Pesi muscolo×abilità** (`GoalWeight`: nessuna/bassa/media/alta, per
   coppia `Muscle`×`Ability`): "quanto conta allenare la forza sulle
   spalle". A differenza di `Exercise.scores` (scala 0-3, usata per
   descrivere COSA allena un esercizio) questa scala descrive quanto
   IMPORTA all'utente allenare quella combinazione — due assi distinti
   che si incontrano solo nel calcolo di copertura.
2. **Obiettivi specifici** (`NamedGoal`: nome + priorità intera, 1 =
   massima): traguardi puntuali come "Loto" o "Verticale" che non hanno
   un corrispettivo diretto in una singola coppia muscolo/abilità.
   Nessuna copertura calcolabile per questi: manca ancora un modo di
   collegare un nome libero a una catena di esercizi specifica (idea per
   un lavoro futuro, fuori da questo giro).

### Copertura (`GoalsController.coverageOf`)

Per ogni coppia muscolo/abilità con un peso impostato, la schermata
mostra quanto del catalogo esercizi per quella combinazione è già
acquisito: per ogni esercizio con `scores[muscle][ability] > 0`, il
proprio punteggio conta nel denominatore ("possibile") e nel numeratore
("raggiunto") solo se `ProgressController.isMastered` è vero. Pesare per
lo score (non contare semplicemente "N esercizi su M") evita che un
esercizio marginale (punteggio 1) pesi quanto uno centrale (punteggio 3)
per quella combinazione.

Deliberatamente NON usa `ProgressController.maturityOf`: quel segnale
riparte da 0 ogni volta che si passa al prossimo esercizio della catena
(`resolveUpgrade`, sezione 16) — usarlo per la copertura farebbe
apparire la copertura in calo proprio quando si progredisce, il
contrario dell'intento. `isMastered` invece resta vero finché
l'esercizio non viene esplicitamente smontato dal checkup di
maturazione (sezione 18).

Ritorna `null`, non `0%`, quando nessun esercizio nel catalogo allena
quella combinazione: "non calcolabile" è un'informazione diversa da "0%
coperto", e la UI le distingue (messaggio dedicato invece di una barra a
zero). `overallCoverage` media solo le combinazioni con un peso impostato
E copertura calcolabile, per lo stesso motivo.

### Stato e persistenza

`GoalsController extends ChangeNotifier`, istanziato in `main.dart`
accanto a `ProgressController` e passato a `HomeScreen`/`GoalsScreen`
come parametro esplicito (stesso schema di `ProgressController`, nessun
`Provider`/`InheritedWidget` nel progetto). Stato solo in memoria: non
sopravvive alla chiusura dell'app, stesso caveat già presente per
`ProgressController.sessionsSinceCheckup` — da rivedere quando arriverà
la persistenza locale (`docs/ROADMAP.md`).
