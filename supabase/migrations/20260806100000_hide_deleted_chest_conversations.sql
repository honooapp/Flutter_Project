create table if not exists public.chest_hidden_conversations (
  user_id uuid not null references auth.users(id) on delete cascade,
  conversation_id text not null,
  hidden_at timestamptz not null default now(),
  primary key (user_id, conversation_id)
);

alter table public.chest_hidden_conversations enable row level security;

create policy "users read their hidden chest conversations"
on public.chest_hidden_conversations
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "users hide their chest conversations"
on public.chest_hidden_conversations
for insert
to authenticated
with check ((select auth.uid()) = user_id);

create policy "users update their hidden chest conversations"
on public.chest_hidden_conversations
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "users restore their hidden chest conversations"
on public.chest_hidden_conversations
for delete
to authenticated
using ((select auth.uid()) = user_id);
