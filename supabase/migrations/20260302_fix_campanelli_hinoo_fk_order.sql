-- Fix order for campanelli.hinoo_id FK relative to public.hinoo creation
-- Idempotent, safe: drops existing FK (if any) and re-applies it only when public.hinoo exists

do $$
begin
  -- 1) Drop existing FK if present
  if exists (
    select 1
    from pg_constraint
    where conname = 'campanelli_hinoo_id_fkey'
      and conrelid = 'public.campanelli'::regclass
  ) then
    alter table public.campanelli
      drop constraint campanelli_hinoo_id_fkey;
  end if;

  -- 2) Re-create FK only if hinoo table exists and FK is missing
  if exists (
    select 1 from pg_class
    where relname = 'hinoo' and relnamespace = 'public'::regnamespace
  ) and not exists (
    select 1
    from pg_constraint
    where conname = 'campanelli_hinoo_id_fkey'
      and conrelid = 'public.campanelli'::regclass
  ) then
    alter table public.campanelli
      add constraint campanelli_hinoo_id_fkey
      foreign key (hinoo_id) references public.hinoo(id);
  end if;
end
$$;

