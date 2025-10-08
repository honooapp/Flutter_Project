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