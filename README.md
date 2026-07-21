# honoo

honoo è una piattaforma narrativa multimediale Flutter: permette di creare e condividere **honoo** (una breve composizione di 144 caratteri e un'immagine quadrata) e **hinoo** (immagine di sfondo e testo libero), conservarli nello Scrigno, pubblicarli sulla Luna e costruire conversazioni. L'Isola delle Storie aggiunge percorsi ed esercizi narrativi.

Il client usa Supabase per autenticazione, PostgreSQL, Storage e Realtime. Il target principale è Flutter Web; il progetto mantiene anche gli scaffold mobile e desktop.

## Toolchain

- Flutter 3.19.6
- Dart 3.3.4
- Supabase Flutter 1.10.25

La versione Flutter è fissata in `.fvmrc` e nei workflow GitHub Actions.

```bash
fvm install
fvm flutter pub get
fvm flutter analyze
fvm flutter test
```

## Avvio web

```bash
fvm flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

Nel client va usata esclusivamente la chiave anon. Le operazioni privilegiate devono restare in RPC protette o codice server-side.

## Test

```bash
# Unit e widget test
fvm flutter test

# Verifiche REST staging in sola lettura (richiedono env)
./tool/run_supabase_readonly_staging.sh

# Integration test su Chrome; target predefinito: smoke_app_starts_test.dart
./tool/run_integration_tests.sh

# Test live di conversazioni, RLS e Realtime su staging
cp live.env.example live.env
# Compilare live.env, poi abilitare esplicitamente le scritture live
HONOO_LIVE_RUN=true ./tool/run_live_conversation_test.sh
```

I test live leggono variabili d'ambiente o il file JSON locale `live.env`; le variabili d'ambiente hanno precedenza. `live.env` è ignorato da Git: non inserire credenziali reali negli script o nel repository. Il workflow `Live Supabase E2E` esegue ogni giorno su staging i controlli CRUD, RLS e Realtime; il flusso UI è attivabile manualmente.

## Build e rilascio

Il deploy GitHub Pages è esclusivamente manuale tramite il workflow `Deploy to GitHub Pages`. Richiede la conferma `DEPLOY`, valida che il commit scelto appartenga a `main`, applica opzionalmente le migrazioni Supabase e pubblica solo dopo il loro successo. Il workflow usa l'environment GitHub `production`, che deve avere approvazioni e secret configurati.

```bash
fvm flutter build web --release \
  --web-renderer canvaskit \
  --dart-define=SUPABASE_URL=<url> \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

I tag restano utili per identificare le versioni, ma non avviano automaticamente una pubblicazione. Per il flusso locale di commit e tag è disponibile `tool/release.sh`.

Le attività editoriali e tecniche ancora aperte sono raccolte in [TODO.md](TODO.md).
