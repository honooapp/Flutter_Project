#!/usr/bin/env bash
set -euo pipefail

project_ref="${1:-}"
sql_file="$(dirname "$0")/check_supabase.sql"

if ! command -v supabase >/dev/null; then
  echo "supabase CLI not found. Install: https://supabase.com/docs/guides/cli" >&2
  exit 1
fi

if [[ -n "$project_ref" ]]; then
  echo "Linking project $project_ref..."
  supabase link --project-ref "$project_ref"
fi

tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

supabase db dump --schema-only > "$tmp_file"

check_function() {
  local fn="$1"
  if grep -q "function public.$fn" "$tmp_file"; then
    echo "✅ function $fn"
  else
    echo "❌ function $fn"
  fi
}

check_table() {
  local table="$1"
  if grep -q "create table public.$table" "$tmp_file"; then
    echo "✅ table $table"
  else
    echo "❌ table $table"
  fi
}

check_columns() {
  local table="$1"
  shift
  local block
  block=$(awk -v tbl="$table" '
    tolower($0) ~ "create table public." tolower(tbl) {inblock=1}
    inblock {print}
    inblock && /^\);/ {inblock=0}
  ' "$tmp_file")
  if [[ -z "$block" ]]; then
    echo "❌ columns for $table (table missing)"
    return
  fi
  for col in "$@"; do
    if echo "$block" | grep -q "\b$col\b"; then
      echo "✅ column $table.$col"
    else
      echo "❌ column $table.$col"
    fi
  done
}

echo "\nRPC checks"
check_function "claim_house_invite_by_email"
check_function "increment_site_visit"

echo "\nTable checks"
check_table "house_invites"
check_table "honoo"
check_table "hinoo"

echo "\nColumn checks"
check_columns "honoo" "destination" "reply_to" "recipient_tag"
check_columns "hinoo" "type" "reply_to" "recipient_tag"

echo "\nSQL version (manual): $sql_file"
