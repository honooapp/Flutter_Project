-- Controllo RPC richieste
select proname
from pg_proc
join pg_namespace n on n.oid = pg_proc.pronamespace
where n.nspname = 'public'
  and proname in ('claim_house_invite_by_email', 'increment_site_visit');

-- Controllo tabelle richieste
select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in ('house_invites', 'honoo', 'hinoo');

-- Controllo colonne chiave per reply/inviti
select column_name
from information_schema.columns
where table_schema = 'public'
  and table_name = 'honoo'
  and column_name in ('destination', 'reply_to', 'recipient_tag');

select column_name
from information_schema.columns
where table_schema = 'public'
  and table_name = 'hinoo'
  and column_name in ('type', 'reply_to', 'recipient_tag');
