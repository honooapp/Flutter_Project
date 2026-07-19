-- A reply target is the authoritative signal that an Hinoo is an answer.
-- Normalize legacy rows created before the reply flow was unified.
update public.hinoo
set type = 'answer'
where reply_to is not null
  and type <> 'answer';
