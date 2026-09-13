# Allenamento

App Android (Flutter) per allenamento a corpo libero (calisthenics), con
motore di progressione per categoria (spinta, trazione, core, gambe,
flessibilità, equilibrio) invece di un piano fisso. Pensata per pavimento,
muro e fascia elastica.

Stato: **scheletro iniziale**, non ancora una app funzionante — vedi
[`docs/ROADMAP.md`](docs/ROADMAP.md) per cosa manca e
[`docs/ARCHITETTURA.md`](docs/ARCHITETTURA.md) per le decisioni prese e il
perché.

## Come ottenere un APK installabile

Questo repository non contiene la cartella `android/` (va generata con
l'SDK Flutter reale, non disponibile nell'ambiente in cui questo scheletro
è stato scritto). Per compilare un APK:

1. Apri la tab **Actions** di questo repository su GitHub.
2. Esegui una volta il workflow **"Bootstrap piattaforma Android"**
   (pulsante "Run workflow") — genera `android/` e lo committa nel repo.
   Va rifatto solo se in futuro serve rigenerare `android/` da zero.
3. Ogni push su `main` (o un altro "Run workflow" manuale) fa partire
   **"Build APK"**: al termine, apri la run e scarica l'artifact
   `allenamento-debug-apk` dalla sezione in fondo alla pagina.
4. L'APK è di **debug** (non firmato per il Play Store): per installarlo sul
   telefono serve abilitare "Installa da fonti sconosciute" per il file
   scaricato.

Nessun Android Studio richiesto: tutta la compilazione avviene sui runner
GitHub Actions, gratuiti per questo volume di build.

## Sviluppo locale (opzionale)

Se in futuro si preferisce compilare in locale invece che via CI, serve
Flutter installato (`flutter doctor` per verificare), poi:

```
flutter pub get
flutter run       # su un dispositivo/emulatore connesso
flutter build apk --debug
```

## Struttura del progetto

```
lib/
  main.dart              punto di ingresso dell'app
  models/
    category.dart        categorie di fondamenta + attrezzatura disponibile
    exercise.dart         modello Esercizio + alcuni esercizi di esempio
  screens/
    home_screen.dart      elenco categorie
    category_screen.dart  elenco esercizi di una categoria
docs/
  ARCHITETTURA.md         decisioni prese, fonti pubbliche usate, perché
  ROADMAP.md              cosa è fatto, cosa manca, in che ordine
.github/workflows/
  bootstrap.yml           genera android/ (da eseguire una volta a mano)
  build-apk.yml           compila l'APK a ogni push
```
