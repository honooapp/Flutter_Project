Supabase Live Tests (staging/prod)

Questa repo include test live verso Supabase che usano chiamate REST (Dart puro, http 0.13.x) per evitare plugin Flutter e blocchi HTTP dei widget test.
I test sono divisi tra:

Read-only (sempre sicuri): auth, SELECT, storage pubblico.

CRUD (scritture controllate): INSERT → UPDATE → SELECT → DELETE su tabella di test, disabilitati di default.

⚠️ Le scritture si attivano solo quando setti esplicitamente ENABLE_WRITE_TESTS=1.

Struttura & script

Read-only (staging): ./tool/run_supabase_readonly_staging.sh
→ esegue i test live di lettura su Staging (no scritture).

Read-only (prod): ./tool/run_supabase_readonly_prod.sh
→ stessi test live su Produzione (no scritture).

CRUD (staging): ./tool/run_supabase_crud_staging.sh
→ abilita ENABLE_WRITE_TESTS=1 e lancia i test CRUD su Staging.

I test stanno in test/supabase/ e leggono le credenziali da env o --dart-define.

Variabili richieste
Variabile	Dove	Note
SUPABASE_URL	Staging/Prod	es. https://<ref>.supabase.co
SUPABASE_ANON_KEY	Staging/Prod	chiave anon (mai service_role nell’app)
TEST_EMAIL	Staging (opz)	utente di test valido
TEST_PASSWORD	Staging (opz)	password utente di test
TEST_IMAGE_URL	Staging (opz)	URL asset pubblico se test storage abilitato
ENABLE_WRITE_TESTS=1	Solo CRUD	attiva scritture; ometti per disattivarle
Come eseguire (locale)
1) Read-only su Staging (sicuro)
   ./tool/run_supabase_readonly_staging.sh

2) Read-only su Prod (passa le env prima)
   SUPABASE_URL="https://<prod>.supabase.co" \
   SUPABASE_ANON_KEY="<prod-anon>" \
   ./tool/run_supabase_readonly_prod.sh

3) CRUD su Staging (solo quando serve)
# lo script imposta ENABLE_WRITE_TESTS=1
./tool/run_supabase_crud_staging.sh

Load test (stress Supabase)
---------------------------

Per simulare carichi concorrenti sulle principali rotte Supabase è disponibile
lo script `tool/supabase_load_test.dart` (wrapper: `./tool/run_supabase_load_test.sh`).
Usa le stesse variabili d'ambiente (`SUPABASE_URL`, `SUPABASE_ANON_KEY`,
`TEST_EMAIL`, `TEST_PASSWORD`). Esempi:

```
# Page view Moon (solo letture)
./tool/run_supabase_load_test.sh --scenario=fetch-moon --vus=20 --duration=90s --pause=120-220

# Login hammer test
./tool/run_supabase_load_test.sh --scenario=login --vus=10 --duration=45s

# Draft save burst (scrive e sovrascrive hinoo_drafts)
./tool/run_supabase_load_test.sh --scenario=draft-upsert --vus=15 --duration=2m --pause=150-300

# Inserimento+delete honoo (pulizia automatica) – usare solo su staging
./tool/run_supabase_load_test.sh --scenario=honoo-cycle --vus=8 --duration=60s --pause=200-400
```

Lo script importa automaticamente `.env.supabase` (puoi cambiare file con
`SUPABASE_ENV_FILE`) e popola le variabili d'ambiente mancanti.

Scenari disponibili:

- `fetch-moon`: replica la Moon page (SELECT su `honoo` e `hinoo`, limit
  configurabile con `--read-limit`).
- `login`: misura la tenuta del password grant (GoTrue). Ogni iterazione esegue
  un login completo; al termine il token viene scartato.
- `draft-upsert`: effettua upsert rapidi su `hinoo_drafts` con payload simile a
  quello dell'app (sovrascrive sempre lo stesso utente di test).
- `honoo-cycle`: inserisce un record nello scrigno e lo elimina per testare
  l'intero round-trip.
- `honoo-write-chest`: inserisce un honoo destination=chest; se non vuoi tenere
  i dati aggiungi `--keep-data`.
- `honoo-duplicate-to-moon`: salva nello scrigno e duplica su Luna (nuova
  insert destination=moon).
- `honoo-update-to-moon`: salva nello scrigno e aggiorna la destination a
  `moon` (PATCH PostgREST).
- `hinoo-publish`: pubblica un hinoo personale (`type=personal`).
- `hinoo-duplicate-to-moon`: inserisce prima un hinoo personale e poi la copia
  `type=moon` con fingerprint dedicato.
- `honoo-user-journey`: percorre un flusso completo (consulta la Luna, legge lo
  scrigno, salva e talvolta pubblica sulla Luna).

Esecuzioni rapide (vedi `--keep-data` se vuoi lasciare i record per analisi):

```
./tool/run_supabase_load_test.sh --scenario=fetch-moon --vus=5 --duration=45s --pause=120-220 --keep-data
./tool/run_supabase_load_test.sh --scenario=login --vus=5 --duration=45s --login-reuse-session --login-refresh-every=30 --keep-data
./tool/run_supabase_load_test.sh --scenario=draft-upsert --vus=5 --duration=60s --pause=150-300 --keep-data
./tool/run_supabase_load_test.sh --scenario=honoo-cycle --vus=5 --duration=45s --pause=180-300 --keep-data
./tool/run_supabase_load_test.sh --scenario=honoo-write-chest --vus=5 --duration=45s --pause=180-300 --keep-data
./tool/run_supabase_load_test.sh --scenario=honoo-duplicate-to-moon --vus=5 --duration=45s --pause=200-320 --keep-data
./tool/run_supabase_load_test.sh --scenario=honoo-update-to-moon --vus=5 --duration=45s --pause=200-320 --keep-data
./tool/run_supabase_load_test.sh --scenario=hinoo-publish --vus=5 --duration=45s --pause=180-300 --keep-data
./tool/run_supabase_load_test.sh --scenario=hinoo-duplicate-to-moon --vus=5 --duration=45s --pause=200-320 --keep-data
./tool/run_supabase_load_test.sh --scenario=honoo-user-journey --vus=5 --duration=45s --pause=250-400 --keep-data
```

Simulazione di picco (≈300 utenti attivi):

```
# Percorso completo con session reuse
./tool/run_supabase_load_test.sh --scenario=honoo-user-journey --vus=60 --duration=300s --pause=400-700 --login-reuse-session --login-refresh-every=30 --keep-data

# Letture Moon in parallelo
./tool/run_supabase_load_test.sh --scenario=fetch-moon --vus=60 --duration=300s --pause=250-500 --keep-data

# Salvataggi rapidi nello scrigno (attenzione a RLS/limiti)
./tool/run_supabase_load_test.sh --scenario=honoo-write-chest --vus=40 --duration=240s --pause=350-600 --keep-data

# Pubblicazione Hinoo con duplicazione
./tool/run_supabase_load_test.sh --scenario=hinoo-duplicate-to-moon --vus=30 --duration=240s --pause=350-600 --keep-data

# Login reale ogni tanto (evita rate limit)
./tool/run_supabase_load_test.sh --scenario=login --vus=30 --duration=300s --pause=500-800 --login-reuse-session --login-refresh-every=60 --keep-data
```

Opzioni principali:

- `--vus=<n>` utenti virtuali (default 5)
- `--duration=<30s|2m>` durata totale del test
- `--pause=<min-max>` think time tra le iterazioni (ms)
- `--timeout=<s>` timeout per singola richiesta (default 10)
- `--verbose` per loggare gli errori in tempo reale
- `--url`, `--anon-key`, `--email`, `--password` per override ponctuale delle
  credenziali
- `--keep-data` per lasciare nel database le righe inserite durante il test
- `--login-reuse-session` e `--login-refresh-every=<n>` per controllare la
  frequenza dei login (utile con molti utenti simultanei)

Output: report finale con success rate, latenza media/p50/p95/max ed errori più
frequenti. Riparti con carichi piccoli (es. 3-5 VU), aumenta progressivamente e
confronta i risultati con gli obiettivi (es. p95 < 500 ms). Durante i test
monitora anche la dashboard Supabase (CPU, connessioni, rate limits) per
identificare colli di bottiglia lato backend.

CI (GitHub Actions)

Workflow: .github/workflows/supabase-tests.yml

Read-only: gira sempre su push/PR (analyze + test di lettura su Staging).

CRUD manuale: vai su Actions → Supabase Tests → Run workflow e imposta run_crud = true.

Secrets da impostare in GitHub

STAGING_SUPABASE_URL

STAGING_SUPABASE_ANON_KEY

STAGING_TEST_EMAIL

STAGING_TEST_PASSWORD

STAGING_TEST_IMAGE_URL (se usi il test storage)

(Per Prod usa secrets analoghi in uno script/profilo separato. Lo script prod non abilita mai le scritture.)

RLS consigliata per CRUD di test (staging)

Tabella di test: e2e_items (flag is_test=true, ownership per utente).

create table if not exists public.e2e_items (
id uuid primary key default gen_random_uuid(),
user_id uuid not null default auth.uid(),
label text not null,
is_test boolean not null default true,
created_at timestamptz not null default now()
);
alter table public.e2e_items enable row level security;

create policy "e2e_read_own_tests"   on public.e2e_items for select using (auth.uid() = user_id and is_test = true);
create policy "e2e_insert_own_tests" on public.e2e_items for insert with check (auth.uid() = user_id and is_test = true);
create policy "e2e_update_own_tests" on public.e2e_items for update using (auth.uid() = user_id and is_test = true) with check (auth.uid() = user_id and is_test = true);
create policy "e2e_delete_own_tests" on public.e2e_items for delete using (auth.uid() = user_id and is_test = true);

Troubleshooting rapido

401 Invalid API key → Controlla SUPABASE_URL e anon key dell’ambiente giusto.

401/403 in INSERT/UPDATE → RLS/policy non consentono la scrittura per l’utente di test. Crea/adegua policy come sopra.

Timeout → Verifica rete/URL. Prova prima i read-only.

Scritture accidentali → Assicurati di non esportare ENABLE_WRITE_TESTS. Gli script read-only non lo impostano.

Note di compatibilità

Toolchain attuale: Flutter 3.9 beta / Dart 3.0.0-beta.

Dipendenze test REST: http 0.13.6 (compatibile).

In futuro, se/quando aggiorni a Flutter/Dart stabile recente, potrai migrare al client supabase ^2.x; i test REST esistenti continueranno comunque a funzionare.

NOTE: La migrazione db/migrations/2025-10-09_supabase_rls_hardening.sql è già stata applicata manualmente in Prod dopo l’upgrade Postgres. Rimane nel repo per garantire idempotenza e replicabilità; verrà pushata quando la CI o una shell con rete ok sarà disponibile.

Per evitare errori in CI finché la rete non risolve i domini Supabase, usa `tool/db/push_prod.sh`. Solo quando `SUPABASE_DB_PUSH=1` e `PROD_DB_URL` sono impostati il push verrà eseguito; altrimenti lo script stamperà "Skip db push".
