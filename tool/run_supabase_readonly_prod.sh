#!/usr/bin/env bash
set -euo pipefail

# Punta al tuo Flutter SDK locale (adatta se diverso)
export PATH="/Users/andreea/StudioProjects/development/flutter_honoo/bin:$PATH"

# PROD env: NON hardcodare qui; inietta da ENV/CI.
: "${SUPABASE_URL:?Set SUPABASE_URL (prod) first}"
: "${SUPABASE_ANON_KEY:?Set SUPABASE_ANON_KEY (prod) first}"
# opzionali:
: "${TEST_EMAIL:=}"
: "${TEST_PASSWORD:=}"
: "${TEST_IMAGE_URL:=}"

echo "Running PROD read-only Supabase tests (no writes)…"
flutter test \
  --concurrency=1 \
  --reporter expanded \
  test/supabase/
