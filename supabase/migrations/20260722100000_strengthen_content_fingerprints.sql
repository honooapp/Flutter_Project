-- Replace MD5-based deduplication keys with SHA-256 while preserving the
-- existing raw fingerprints used by the client and maintenance tooling.
create extension if not exists pgcrypto with schema extensions;

do $$
declare
  crypto_schema text;
begin
  select namespace.nspname
  into strict crypto_schema
  from pg_extension as extension
  join pg_namespace as namespace
    on namespace.oid = extension.extnamespace
  where extension.extname = 'pgcrypto';

  execute format(
    $index$
      create unique index if not exists honoo_user_destination_fingerprint_sha256_key
        on public.honoo (
          user_id,
          destination,
          %I.digest(fingerprint, 'sha256')
        )
        where fingerprint is not null
          and destination in ('chest', 'moon')
    $index$,
    crypto_schema
  );

  execute format(
    $index$
      create unique index if not exists hinoo_user_type_fingerprint_sha256_key
        on public.hinoo (
          user_id,
          type,
          %I.digest(fingerprint, 'sha256')
        )
        where fingerprint is not null
          and type in ('personal', 'moon')
    $index$,
    crypto_schema
  );
end;
$$;

-- Create and validate both replacements before removing either legacy guard.
do $$
begin
  if not exists (
    select 1
    from pg_index
    where indexrelid = 'public.honoo_user_destination_fingerprint_sha256_key'::regclass
      and indisvalid
      and indisunique
  ) then
    raise exception 'Honoo SHA-256 fingerprint index is not valid';
  end if;

  if not exists (
    select 1
    from pg_index
    where indexrelid = 'public.hinoo_user_type_fingerprint_sha256_key'::regclass
      and indisvalid
      and indisunique
  ) then
    raise exception 'Hinoo SHA-256 fingerprint index is not valid';
  end if;
end;
$$;

drop index if exists public.honoo_user_destination_fingerprint_key;
drop index if exists public.hinoo_user_type_fingerprint_key;
