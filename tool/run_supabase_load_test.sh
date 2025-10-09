#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_dir/.." && pwd)"

# Carica env predefinito se presenta e se le variabili non sono già settate
env_file="${SUPABASE_ENV_FILE:-$project_root/.env.supabase}"
if [ -f "$env_file" ]; then
  for var in SUPABASE_URL SUPABASE_ANON_KEY TEST_EMAIL TEST_PASSWORD TEST_IMAGE_URL; do
    if [ -z "${!var:-}" ]; then
      # shellcheck source=/dev/null
      source "$env_file"
      break
    fi
  done
fi

DART_BIN="${DART_BIN:-dart}"

if ! command -v "$DART_BIN" >/dev/null 2>&1; then
  FALLBACK_DART="/Users/andreea/StudioProjects/development/flutter_3.24.3/bin/dart"
  if command -v "$FALLBACK_DART" >/dev/null 2>&1; then
    DART_BIN="$FALLBACK_DART"
  else
    echo "dart non trovato (setta DART_BIN o aggiungi dart al PATH)" >&2
    exit 127
  fi
fi

cd "$project_root"

"$DART_BIN" run tool/supabase_load_test.dart "$@"
