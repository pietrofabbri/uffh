# Roadmap

Scritto per essere ripreso da chiunque (umano o AI) senza contesto pregresso.
Stato attuale: **scheletro minimo**, sufficiente solo a validare che la
pipeline di build produca un APK installabile. Nessuna logica di
allenamento reale, nessuna persistenza, nessuna sincronizzazione.

## Fatto

- [x] Struttura progetto Flutter (`pubspec.yaml`, `lib/`) scritta a mano
      (senza `flutter create`, perché l'SDK Flutter non era disponibile
      nell'ambiente di scrittura — vedi `docs/ARCHITETTURA.md` sezione 5).
- [x] Modello dati minimo: categorie di fondamenta (`lib/models/category.dart`),
      esercizio con prerequisito/livello (`lib/models/exercise.dart`), 4
      esercizi di esempio (`seedExercises`).
- [x] Schermate placeholder: elenco categorie → elenco esercizi espandibile
      (`lib/screens/`).
- [x] Pipeline CI (`.github/workflows/`) per bootstrap della piattaforma
      Android e build di un APK di debug scaricabile da ogni push.

## Da fare, in ordine ragionevole

1. **Eseguire `bootstrap.yml` una volta** dalla tab Actions del repository,
   verificare che generi `android/` e lo committi, poi verificare che
   `build-apk.yml` produca un APK scaricabile e installabile sul telefono.
   Questo valida l'intera pipeline PRIMA di investire tempo nella logica
   dell'app.
2. **Motore di progressione**: dato un livello per categoria (0 se mai
   valutato) e un `prerequisiteId`, calcolare quali esercizi sono "sbloccati"
   e quale sarebbe il prossimo passo ragionevole per categoria. Ispirarsi al
   pattern descritto in `docs/ARCHITETTURA.md` sezione 2 (categoria × livelli
   × prerequisiti), non copiare da app commerciali.
3. **Popolare il database di esercizi** oltre ai 4 di esempio, coerente con
   pavimento + muro + fascia elastica. Valutare se importare/adattare
   [free-exercise-db](https://github.com/yuhonas/free-exercise-db)
   (pubblico dominio, include immagini) per gli esercizi generici, e
   scrivere a mano quelli specifici per fascia elastica/muro che il dataset
   non copre bene.
4. **Valutazione iniziale del livello per categoria**: un questionario o
   pochi test guidati (ispirato al modello a 9 categorie citato in
   `docs/ARCHITETTURA.md`), per posizionare l'utente su ciascuna categoria
   invece di partire sempre da 0.
5. **Persistenza locale**: scegliere e integrare uno storage locale
   (`sqflite` o `drift` sono le scelte comuni in Flutter) per salvare
   livelli, sedute completate, note — non ancora presente nello scheletro.
6. **Sincronizzazione con Google Drive/Sheets** (vedi
   `docs/ARCHITETTURA.md` sezione 4): richiede che l'utente crei un progetto
   Google Cloud con OAuth client per l'app (passo manuale, non delegabile),
   poi integrare un package Flutter per l'autenticazione Google e la
   scrittura su Drive/Sheets.
7. **Routine yoga**: da strutturare quando l'utente la descrive (varia da
   seduta a seduta, stile Anukalana) — non forzarla nello stesso schema
   fisso delle categorie sopra finché non è chiaro se ha una progressione
   ripetibile o resta libera.
8. **Valutare l'apertura pubblica del repository**: la decisione presa è
   "parti privato, progetta in modo incrementale verso il pubblico" — prima
   di rendere il repo pubblico, ricontrollare la sezione licenze in
   `docs/ARCHITETTURA.md` (in particolare il dataset con attribuzione Gym
   Visual, se mai integrato, va trattato con più cautela in un contesto
   pubblico) e aggiungere un file `LICENSE` esplicito.

## Note per chi riprende questo lavoro

- Nessun file in questo repo è mai stato compilato/testato in un ambiente
  Flutter reale (l'SDK non era disponibile in fase di scrittura): la build
  GitHub Actions (punto 1 sopra) è la prima verifica reale — se fallisce,
  correggere lì prima di aggiungere altre funzionalità.
- Le decisioni architetturali (Flutter, GitHub Actions per la build,
  Google Drive/Sheets come ponte dati verso Claude, scope privato-poi-
  pubblico) sono state prese in una conversazione con l'utente il
  2026-09-12 — vedi `docs/ARCHITETTURA.md` per il "perché" dietro ciascuna.
