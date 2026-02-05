alter table public.house_access
add column if not exists created_at timestamptz not null default now(),
add column if not exists hinoo_id uuid references public.hinoo(id);
