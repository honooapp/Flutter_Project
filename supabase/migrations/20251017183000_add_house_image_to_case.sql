alter table public.case
add column if not exists house_image_url text,
add column if not exists bg_transform jsonb;
