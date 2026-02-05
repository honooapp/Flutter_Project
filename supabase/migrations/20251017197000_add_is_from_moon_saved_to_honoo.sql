alter table public.honoo
add column if not exists is_from_moon_saved boolean not null default false;
