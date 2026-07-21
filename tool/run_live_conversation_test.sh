#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tool/load_live_env.sh
source "$script_dir/load_live_env.sh"

: "${HONOO_SUPABASE_URL:?Set HONOO_SUPABASE_URL}"
: "${HONOO_SUPABASE_ANON_KEY:?Set HONOO_SUPABASE_ANON_KEY}"
: "${HONOO_TEST_IMAGE_URL:?Set HONOO_TEST_IMAGE_URL}"
: "${HONOO_TEST_USER_A_EMAIL:?Set HONOO_TEST_USER_A_EMAIL}"
: "${HONOO_TEST_USER_B_EMAIL:?Set HONOO_TEST_USER_B_EMAIL}"

for live_secret_name in HONOO_TEST_USER_A_PASSWORD HONOO_TEST_USER_B_PASSWORD; do
  if [[ -z "${!live_secret_name:-}" ]]; then
    echo "Configurazione live incompleta: manca $live_secret_name." >&2
    exit 1
  fi
done
unset live_secret_name

if [[ "${HONOO_LIVE_RUN:-false}" != "true" ]]; then
  echo "HONOO_LIVE_RUN deve essere true per il test live." >&2
  exit 1
fi

echo "Esecuzione test conversazioni live (credenziali nascoste)."
flutter_runner=(fvm flutter)
if [[ "${CI:-}" == "true" ]]; then
  flutter_runner=(flutter)
fi
"${flutter_runner[@]}" test \
  --reporter=expanded \
  test/live/live_conversation_flow_test.dart \
  --dart-define=HONOO_LIVE_RUN=true \
  --dart-define=HONOO_SUPABASE_URL="$HONOO_SUPABASE_URL" \
  --dart-define=HONOO_SUPABASE_ANON_KEY="$HONOO_SUPABASE_ANON_KEY" \
  --dart-define=HONOO_TEST_IMAGE_URL="$HONOO_TEST_IMAGE_URL" \
  --dart-define=HONOO_TEST_USER_A_EMAIL="$HONOO_TEST_USER_A_EMAIL" \
  --dart-define=HONOO_TEST_USER_A_PASSWORD="$HONOO_TEST_USER_A_PASSWORD" \
  --dart-define=HONOO_TEST_USER_B_EMAIL="$HONOO_TEST_USER_B_EMAIL" \
  --dart-define=HONOO_TEST_USER_B_PASSWORD="$HONOO_TEST_USER_B_PASSWORD"
