alter table public.hinoo
add column if not exists reply_to uuid references public.hinoo(id);
