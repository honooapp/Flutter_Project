#!/usr/bin/env bash
set -euo pipefail

# Punta al tuo Flutter SDK locale (adatta se diverso)
export PATH="/Users/andreea/StudioProjects/development/flutter_honoo/bin:$PATH"

# STAGING env: se vuoi, puoi hardcodare qui oppure passare da ENV/CI.
# Esempio con hardcode sicuro (solo url/anon pubblici).
: "${SUPABASE_URL:=https://lnuzzrlkcbhxuzxyekbp.supabase.co}"
: "${SUPABASE_ANON_KEY:?Set SUPABASE_ANON_KEY (staging) first}"
# opzionali se qualche test li usa:
: "${TEST_EMAIL:=}"
: "${TEST_PASSWORD:=}"
: "${TEST_IMAGE_URL:=}"

echo "Running STAGING read-only Supabase tests (no writes)…"
flutter test \
  --concurrency=1 \
  --reporter expanded \
  test/supabase/
