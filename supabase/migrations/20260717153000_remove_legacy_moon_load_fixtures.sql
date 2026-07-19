-- Remove legacy load-test fixtures accidentally left in the public Moon feed.
-- The destination and generated prefix make the cleanup intentionally narrow.
delete from public.honoo
where destination = 'moon'
  and text like 'lt-journey-%';
