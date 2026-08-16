-- La stessa composizione personale può essere pubblicata sulla Luna più volte.
-- La deduplica resta attiva solo nello Scrigno, dove salvare ripetutamente una
-- copia proveniente dalla Luna deve continuare a produrre un solo elemento.
create extension if not exists pgcrypto with schema extensions;

drop index if exists public.honoo_user_destination_fingerprint_sha256_key;
drop index if exists public.hinoo_user_type_fingerprint_sha256_key;

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
      create unique index if not exists honoo_user_chest_fingerprint_sha256_key
        on public.honoo (
          user_id,
          %I.digest(fingerprint, 'sha256')
        )
        where fingerprint is not null
          and destination = 'chest'
    $index$,
    crypto_schema
  );

  execute format(
    $index$
      create unique index if not exists hinoo_user_personal_fingerprint_sha256_key
        on public.hinoo (
          user_id,
          %I.digest(fingerprint, 'sha256')
        )
        where fingerprint is not null
          and type = 'personal'
    $index$,
    crypto_schema
  );
end;
$$;

do $$
begin
  if not exists (
    select 1
    from pg_index
    where indexrelid = 'public.honoo_user_chest_fingerprint_sha256_key'::regclass
      and indisvalid
      and indisunique
  ) then
    raise exception 'Honoo chest SHA-256 fingerprint index is not valid';
  end if;

  if not exists (
    select 1
    from pg_index
    where indexrelid = 'public.hinoo_user_personal_fingerprint_sha256_key'::regclass
      and indisvalid
      and indisunique
  ) then
    raise exception 'Hinoo personal SHA-256 fingerprint index is not valid';
  end if;
end;
$$;
