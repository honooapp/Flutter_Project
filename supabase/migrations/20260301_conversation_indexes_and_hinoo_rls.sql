-- Conversation performance indexes and RLS policy for hinoo answers addressed to current user
-- Idempotent migration: all objects are created with IF NOT EXISTS or guarded via pg_policies

-- 1) Missing indexes for honoo
create index if not exists honoo_created_idx on public.honoo (created_at desc);
create index if not exists honoo_reply_to_idx on public.honoo (reply_to);
create index if not exists honoo_recipient_tag_idx on public.honoo (recipient_tag);
create index if not exists honoo_conv_created_idx on public.honoo (conversation_id, created_at desc);

-- 2) Missing indexes for hinoo
create index if not exists hinoo_reply_to_idx on public.hinoo (reply_to);
create index if not exists hinoo_recipient_tag_idx on public.hinoo (recipient_tag);
create index if not exists hinoo_conv_created_idx on public.hinoo (conversation_id, created_at desc);

-- 3) RLS policy for hinoo answers addressed to the current user (mirrors honoo replies policy)
do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'hinoo'
      and policyname = 'select answers to me'
  ) then
    create policy "select answers to me"
    on public.hinoo
    as permissive
    for select
    to authenticated
    using (
      (type = 'answer'::public.hinoo_type)
      and recipient_tag is not null
      and recipient_tag in (
        select u.address from public.users u where u.auth_id = auth.uid()
      )
    );
  end if;
end
$$;

