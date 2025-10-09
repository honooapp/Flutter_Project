#!/usr/bin/env bash
set -euo pipefail

if [ "${SUPABASE_DB_PUSH:-0}" = "1" ]; then
  : "${PROD_DB_URL:?set PROD_DB_URL (es. postgresql://...)}"
  echo "Running supabase db push (PROD_DB_URL provided)."
  supabase db push --db-url "$PROD_DB_URL"
else
  echo "Skip db push (rete DNS non disponibile o SUPABASE_DB_PUSH != 1)."
fi
