#!/usr/bin/env bash
set -euo pipefail

: "${SUPABASE_URL:?Set SUPABASE_URL (staging) first}"
: "${SUPABASE_ANON_KEY:?Set SUPABASE_ANON_KEY (staging) first}"
: "${TEST_EMAIL:?Set TEST_EMAIL (staging) first}"
: "${TEST_PASSWORD:?Set TEST_PASSWORD (staging) first}"

# Abilita scritture esclusivamente sul progetto staging indicato dalle env.
export ENABLE_WRITE_TESTS=1

echo "Running Supabase REST CRUD tests on staging..."
fvm flutter test \
  --concurrency=1 \
  --reporter expanded \
  test/supabase/supabase_rest_crud_test.dart
