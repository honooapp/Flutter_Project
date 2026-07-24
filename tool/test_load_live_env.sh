#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fixture="$(mktemp)"
trap 'rm -f "$fixture"' EXIT

printf '%s\n' \
  '{' \
  '  "HONOO_LIVE_RUN": true,' \
  '  "HONOO_SUPABASE_URL": "https://example.supabase.co",' \
  '  "HONOO_SUPABASE_ANON_KEY": "fixture-key",' \
  '  "HONOO_LIVE_EMAIL": "fixture@example.com"' \
  '}' > "$fixture"

export LIVE_ENV_FILE="$fixture"
export HONOO_LIVE_EMAIL="environment@example.com"
# shellcheck source=tool/load_live_env.sh
source "$script_dir/load_live_env.sh"

[[ "$HONOO_LIVE_RUN" == "true" ]]
[[ "$SUPABASE_URL" == "https://example.supabase.co" ]]
[[ "$SUPABASE_ANON_KEY" == "fixture-key" ]]
[[ "$HONOO_LIVE_EMAIL" == "environment@example.com" ]]

echo "Live environment loader checks passed."
