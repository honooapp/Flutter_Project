# Postgres upgrade – verification & hardening

- Verify versions:
  - `select version();`
  - `select extname, extversion from pg_extension order by 1;`
- RLS hardening applied via `db/migrations/2025-10-09_supabase_rls_hardening.sql`.
- Views secured via Dashboard Autofix (“Secure your View”) so they respect RLS.
- Indices de-duplicated on `hinoo.user_id` (kept `idx_hinoo_user_id`).
- Canonical user mapping: `users.auth_user_id` (UUID).
- Smoke:
  ```bash
  SUPABASE_URL=... SUPABASE_ANON_KEY=... TEST_EMAIL=... TEST_PASSWORD=... \
  bash tool/db/smoke_postupgrade.sh
  ```
