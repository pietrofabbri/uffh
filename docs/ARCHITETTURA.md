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
