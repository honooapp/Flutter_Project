-- Drop legacy FK to hinoo_moon_public if present

alter table if exists public."case"
  drop constraint if exists case_campanello_hinoo_id_fkey;
