-- Riconosce retroattivamente le copie personali salvate dalla Luna tramite il
-- collegamento stabile alla riga pubblica originale. Il confronto del contenuto
-- evita di classificare come salvataggi eventuali radici con id riutilizzati.

update public.honoo as saved
set is_from_moon_saved = true
from public.honoo as original
where saved.destination = 'chest'
  and coalesce(saved.is_from_moon_saved, false) = false
  and saved.conversation_id = original.id::text
  and original.destination = 'moon'
  and saved.user_id <> original.user_id
  and saved.text = original.text
  and coalesce(saved.image_url, '') = coalesce(original.image_url, '');

update public.hinoo as saved
set is_from_moon_saved = true
from public.hinoo as original
where saved.type = 'personal'
  and coalesce(saved.is_from_moon_saved, false) = false
  and saved.conversation_id = original.id::text
  and original.type = 'moon'
  and saved.user_id <> original.user_id
  and saved.pages = original.pages;
