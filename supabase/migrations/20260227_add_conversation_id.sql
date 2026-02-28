-- Add conversation_id to honoo and hinoo, plus indexes
alter table if exists public.honoo add column if not exists conversation_id text;
create index if not exists honoo_conversation_id_idx on public.honoo(conversation_id);

alter table if exists public.hinoo add column if not exists conversation_id text;
create index if not exists hinoo_conversation_id_idx on public.hinoo(conversation_id);

