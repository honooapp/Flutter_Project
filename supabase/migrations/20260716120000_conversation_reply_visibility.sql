-- Consente a un destinatario autenticato di leggere le risposte indirizzate a
-- lui, usando UUID auth (formato corrente) o address (compatibilità legacy).

drop policy if exists "select replies to me" on public.honoo;
create policy "select replies to me"
on public.honoo
as permissive
for select
to authenticated
using (
  destination = 'reply'
  and recipient_tag is not null
  and (
    recipient_tag = auth.uid()::text
    or recipient_tag in (
      select u.address from public.users u where u.auth_id = auth.uid()
    )
  )
);

drop policy if exists "hinoo select replies to me" on public.hinoo;
create policy "hinoo select replies to me"
on public.hinoo
as permissive
for select
to authenticated
using (
  type = 'answer'
  and recipient_tag is not null
  and (
    recipient_tag = auth.uid()::text
    or recipient_tag in (
      select u.address from public.users u where u.auth_id = auth.uid()
    )
  )
);
