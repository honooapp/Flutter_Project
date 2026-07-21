#!/usr/bin/env bash

# Carica la configurazione live senza stampare valori sensibili.
# Le variabili già presenti nell'ambiente hanno sempre precedenza.
live_env_file="${LIVE_ENV_FILE:-live.env}"

_set_live_value_from_json() {
  local variable_name="$1"
  if [[ -n "${!variable_name:-}" ]]; then
    return
  fi
  local variable_value
  variable_value="$(jq -r --arg key "$variable_name" '.[$key] // empty | tostring' "$live_env_file")"
  if [[ -n "$variable_value" ]]; then
    printf -v "$variable_name" '%s' "$variable_value"
    export "$variable_name"
  fi
}

if [[ -f "$live_env_file" ]]; then
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq è richiesto per leggere $live_env_file" >&2
    return 1 2>/dev/null || exit 1
  fi
  for live_variable in \
    HONOO_LIVE_CLEANUP \
    HONOO_LIVE_EMAIL \
    HONOO_LIVE_PASSWORD \
    HONOO_LIVE_RUN \
    HONOO_SUPABASE_ANON_KEY \
    HONOO_SUPABASE_URL \
    HONOO_TEST_IMAGE_URL \
    HONOO_TEST_USER_A_EMAIL \
    HONOO_TEST_USER_A_PASSWORD \
    HONOO_TEST_USER_B_EMAIL \
    HONOO_TEST_USER_B_PASSWORD; do
    _set_live_value_from_json "$live_variable"
  done
  echo "Configurazione live caricata da $live_env_file (valori nascosti)."
fi

if [[ -z "${SUPABASE_URL:-}" && -n "${HONOO_SUPABASE_URL:-}" ]]; then
  export SUPABASE_URL="$HONOO_SUPABASE_URL"
fi
if [[ -z "${SUPABASE_ANON_KEY:-}" && -n "${HONOO_SUPABASE_ANON_KEY:-}" ]]; then
  export SUPABASE_ANON_KEY="$HONOO_SUPABASE_ANON_KEY"
fi

unset live_variable
unset -f _set_live_value_from_json
