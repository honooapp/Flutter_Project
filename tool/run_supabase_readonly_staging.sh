#!/usr/bin/env bash
set -euo pipefail

: "${SUPABASE_URL:?Set SUPABASE_URL (staging) first}"
: "${SUPABASE_ANON_KEY:?Set SUPABASE_ANON_KEY (staging) first}"
# opzionali se qualche test li usa:
: "${TEST_EMAIL:=}"
: "${TEST_PASSWORD:=}"
: "${TEST_IMAGE_URL:=}"

echo "Running STAGING read-only Supabase tests (no writes)…"
flutter_runner=(fvm flutter)
if [[ "${CI:-}" == "true" ]]; then
  flutter_runner=(flutter)
fi
"${flutter_runner[@]}" test \
  --concurrency=1 \
  --reporter expanded \
  test/supabase/
