#!/usr/bin/env bash
set -euo pipefail

# Usa FVM per rispettare la versione dichiarata in `.fvmrc`.
FLUTTER_BIN="${FLUTTER_BIN:-fvm flutter}"

DRIVER="integration_test/driver/device_driver.dart"
TARGET="${1:-integration_test/smoke_app_starts_test.dart}"

# Lista dispositivi/selettori (override con INTEGRATION_DEVICES="macos chrome" ecc.)
DEVICES="${INTEGRATION_DEVICES:-chrome}"

: "${SUPABASE_URL:?Set SUPABASE_URL for the integration environment}"
: "${SUPABASE_ANON_KEY:?Set SUPABASE_ANON_KEY for the integration environment}"

for device in $DEVICES; do
  echo "==> flutter drive -d $device ($TARGET)"
  read -r -a flutter_command <<< "$FLUTTER_BIN"
  "${flutter_command[@]}" drive \
    --driver "$DRIVER" \
    --target "$TARGET" \
    -d "$device" \
    --dart-define=SUPABASE_URL="$SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
    --dart-define=HONOO_LIVE_RUN="${HONOO_LIVE_RUN:-false}" \
    --dart-define=HONOO_SUPABASE_URL="${HONOO_SUPABASE_URL:-$SUPABASE_URL}" \
    --dart-define=HONOO_SUPABASE_ANON_KEY="${HONOO_SUPABASE_ANON_KEY:-$SUPABASE_ANON_KEY}" \
    --dart-define=HONOO_LIVE_EMAIL="${HONOO_LIVE_EMAIL:-}" \
    --dart-define=HONOO_LIVE_PASSWORD="${HONOO_LIVE_PASSWORD:-}" \
    --dart-define=HONOO_TEST_IMAGE_URL="${HONOO_TEST_IMAGE_URL:-}" \
    --dart-define=HONOO_TEST_USER_A_EMAIL="${HONOO_TEST_USER_A_EMAIL:-}" \
    --dart-define=HONOO_TEST_USER_A_PASSWORD="${HONOO_TEST_USER_A_PASSWORD:-}" \
    --dart-define=HONOO_TEST_USER_B_EMAIL="${HONOO_TEST_USER_B_EMAIL:-}" \
    --dart-define=HONOO_TEST_USER_B_PASSWORD="${HONOO_TEST_USER_B_PASSWORD:-}"
  echo ""
 done
