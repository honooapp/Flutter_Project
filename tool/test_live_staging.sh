#!/usr/bin/env bash
set -euo pipefail

: "${SUPABASE_URL:?Set SUPABASE_URL first}"
: "${SUPABASE_ANON_KEY:?Set SUPABASE_ANON_KEY first}"
: "${TEST_EMAIL:?Set TEST_EMAIL first}"
: "${TEST_PASSWORD:?Set TEST_PASSWORD first}"
: "${TEST_IMAGE_URL:?Set TEST_IMAGE_URL first}"

fvm flutter test \
  --concurrency=1 \
  --reporter=expanded \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=TEST_EMAIL="$TEST_EMAIL" \
  --dart-define=TEST_PASSWORD="$TEST_PASSWORD" \
  --dart-define=TEST_IMAGE_URL="$TEST_IMAGE_URL" \
  test/supabase/
