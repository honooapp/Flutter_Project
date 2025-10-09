create table if not exists public.auth_otp_attempts (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  ip inet,
  created_at timestamptz not null default now()
);
-- RLS: vietiamo insert da client; solo service_role.
alter table public.auth_otp_attempts enable row level security;
create policy "select_auth_otp_attempts" on public.auth_otp_attempts
  for select to authenticated using (true);
-- niente policy di insert/update/delete per ruoli normali
