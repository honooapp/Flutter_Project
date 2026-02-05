alter table public.house_access
add column if not exists honoo_id uuid references public.honoo(id);
