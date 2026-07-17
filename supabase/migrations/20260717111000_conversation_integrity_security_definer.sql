-- Il trigger deve poter risolvere il parent anche quando appartiene al
-- destinatario ed è quindi nascosto al mittente dalle policy RLS.

alter function public.enforce_conversation_integrity() security definer;
alter function public.enforce_conversation_integrity()
  set search_path = public, pg_temp;

revoke all on function public.enforce_conversation_integrity() from public;
