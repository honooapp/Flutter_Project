#!/usr/bin/env bash
set -euo pipefail

# GitHub's hosted runners do not guarantee that ripgrep is installed. Keep the
# checks fast when it is available, but fall back to portable extended grep so
# this release gate cannot fail only because of the runner image.
if ! command -v rg >/dev/null 2>&1; then
  rg() {
    case "${1:-}" in
      *F*) grep "$@" ;;
      *) grep -E "$@" ;;
    esac
  }
fi

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
migrations_dir="$root_dir/supabase/migrations"

migrations=()
while IFS= read -r migration; do
  migrations+=("$migration")
done < <(find "$migrations_dir" -maxdepth 1 -type f -name '*.sql' -print | sort)
if (( ${#migrations[@]} == 0 )); then
  echo "No Supabase migrations found" >&2
  exit 1
fi

previous=''
for migration in "${migrations[@]}"; do
  name="$(basename "$migration")"
  stamp="${name%%_*}"
  if [[ ! "$stamp" =~ ^([0-9]{8}|[0-9]{14})$ ]]; then
    echo "Invalid migration filename: $name" >&2
    exit 1
  fi
  if [[ -n "$previous" && "$stamp" < "$previous" ]]; then
    echo "Migration order is not monotonic at $name" >&2
    exit 1
  fi
  previous="$stamp"
done

conversation_migration="$migrations_dir/20260301140600_conversation_integrity_enforcement.sql"
if ! rg -q "add column if not exists conversation_id" "$conversation_migration"; then
  echo "conversation_id must be created before the integrity backfill" >&2
  exit 1
fi

if ! rg -q "add table public\.honoo" "$migrations_dir/20260717112000_enable_conversation_realtime.sql" ||
   ! rg -q "add table public\.hinoo" "$migrations_dir/20260717112000_enable_conversation_realtime.sql"; then
  echo "Realtime publication must include both conversation tables" >&2
  exit 1
fi

for bucket in honoo-images hinoo; do
  if ! rg -q "\('$bucket', '$bucket', true\)" "$migrations_dir/20260717143000_create_content_image_buckets.sql"; then
    echo "Missing idempotent storage bucket: $bucket" >&2
    exit 1
  fi
done

safe_alignment="$migrations_dir/20260719120000_safe_production_alignment.sql"
if rg -qi '^\s*(update|delete|drop\s+policy|create\s+policy)\b' "$safe_alignment"; then
  echo "Production-safe alignment must not mutate data or policies" >&2
  exit 1
fi
if ! rg -q "add column if not exists share_modes" "$safe_alignment"; then
  echo "Production-safe alignment must add share_modes idempotently" >&2
  exit 1
fi
if ! rg -q "on conflict \(id\) do nothing" "$safe_alignment"; then
  echo "Production-safe alignment must preserve existing bucket settings" >&2
  exit 1
fi

historical_campanelli="$migrations_dir/20250128094500_create_campanelli_case_invites.sql"
if rg -q 'house_id uuid references public\."case"\(id\)' "$historical_campanelli"; then
  echo "The historical Campanelli migration must create both tables before their circular FK" >&2
  exit 1
fi
if ! rg -q 'add constraint campanelli_house_id_fkey' "$historical_campanelli"; then
  echo "The historical Campanelli migration must add its house FK after both tables exist" >&2
  exit 1
fi

restore_campanelli="$migrations_dir/20260719123000_restore_missing_campanelli.sql"
if ! rg -q "if to_regclass\('public\.campanelli'\) is not null then" "$restore_campanelli" ||
   ! rg -q '^\s*return;' "$restore_campanelli"; then
  echo "Campanelli restoration must be a strict no-op when the table already exists" >&2
  exit 1
fi
for policy in \
  'Campanelli insert own' \
  'Campanelli select own' \
  'Campanelli update own'; do
  if ! rg -q "create policy \"$policy\"" "$restore_campanelli"; then
    echo "Campanelli restoration does not mirror production policy: $policy" >&2
    exit 1
  fi
done

safe_activation="$migrations_dir/20260719130000_safe_production_activation.sql"
if rg -qi '^\s*(update|delete|drop\s+policy|create\s+policy)\b' "$safe_activation"; then
  echo "Production activation must not mutate rows or policies" >&2
  exit 1
fi
for required_fragment in \
  'add column if not exists share_modes' \
  'on conflict (id) do nothing' \
  'create or replace function public.enforce_conversation_integrity()' \
  'alter publication supabase_realtime add table public.honoo' \
  'alter publication supabase_realtime add table public.hinoo' \
  'create or replace view public.moon_public'; do
  if ! rg -Fq "$required_fragment" "$safe_activation"; then
    echo "Production activation is missing: $required_fragment" >&2
    exit 1
  fi
done

fingerprint_hardening="$migrations_dir/20260722100000_strengthen_content_fingerprints.sql"
for required_fragment in \
  'create extension if not exists pgcrypto with schema extensions' \
  'honoo_user_destination_fingerprint_sha256_key' \
  'hinoo_user_type_fingerprint_sha256_key' \
  "digest(fingerprint, 'sha256')" \
  'and indisvalid' \
  'and indisunique'; do
  if ! rg -Fq "$required_fragment" "$fingerprint_hardening"; then
    echo "Fingerprint hardening is missing: $required_fragment" >&2
    exit 1
  fi
done
if rg -qi '^\s*(update|delete)\b' "$fingerprint_hardening"; then
  echo "Fingerprint hardening must not rewrite user content" >&2
  exit 1
fi
honoo_create_line="$(rg -n -m 1 'create unique index if not exists honoo_user_destination_fingerprint_sha256_key' "$fingerprint_hardening" | cut -d: -f1)"
hinoo_create_line="$(rg -n -m 1 'create unique index if not exists hinoo_user_type_fingerprint_sha256_key' "$fingerprint_hardening" | cut -d: -f1)"
honoo_drop_line="$(rg -n -m 1 'drop index if exists public.honoo_user_destination_fingerprint_key' "$fingerprint_hardening" | cut -d: -f1)"
hinoo_drop_line="$(rg -n -m 1 'drop index if exists public.hinoo_user_type_fingerprint_key' "$fingerprint_hardening" | cut -d: -f1)"
if (( honoo_create_line >= honoo_drop_line || hinoo_create_line >= hinoo_drop_line )); then
  echo "SHA-256 fingerprint guards must be created before legacy indexes are removed" >&2
  exit 1
fi

echo "Supabase migration structure checks passed (${#migrations[@]} files)."
