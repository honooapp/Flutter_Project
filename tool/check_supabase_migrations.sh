#!/usr/bin/env bash
set -euo pipefail

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

echo "Supabase migration structure checks passed (${#migrations[@]} files)."
