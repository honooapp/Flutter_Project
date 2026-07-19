-- Ripara le risposte storiche che conservano conversazione e destinatario,
-- ma hanno perso reply_to (e in alcuni casi anche la classificazione).
-- conversation_id identifica la radice stabile del thread.

update public.hinoo
set reply_to = conversation_id::uuid,
    type = 'answer'
where reply_to is null
  and conversation_id is not null
  and conversation_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
  and recipient_tag is not null
  and coalesce(is_from_moon_saved, false) = false;

update public.honoo
set reply_to = conversation_id::uuid,
    destination = 'reply'
where reply_to is null
  and conversation_id is not null
  and conversation_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
  and recipient_tag is not null
  and coalesce(is_from_moon_saved, false) = false;
