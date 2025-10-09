-- RLS hardening & policy consolidation after Postgres upgrade
-- Idempotent where possible.

----------------------------
-- Ensure RLS ON (no-op if already enabled)
----------------------------
ALTER TABLE IF EXISTS public.hinoo               ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.hinoo_drafts       ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.hinoo_moon_public  ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.hinoo_public       ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.hinoo_storage_refs ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.users              ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.honoo              ENABLE ROW LEVEL SECURITY;

----------------------------
-- Consolidate SELECT on hinoo
----------------------------
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_schema='public' AND table_name='hinoo' AND column_name='is_public') THEN
    -- drop legacy/select duplicates if exist
    PERFORM 1 FROM pg_policies WHERE schemaname='public' AND tablename='hinoo' AND policyname='hinoo public read moon';
    IF FOUND THEN EXECUTE 'DROP POLICY IF EXISTS "hinoo public read moon" ON public.hinoo'; END IF;

    PERFORM 1 FROM pg_policies WHERE schemaname='public' AND tablename='hinoo' AND policyname='hinoo select own';
    IF FOUND THEN EXECUTE 'DROP POLICY IF EXISTS "hinoo select own" ON public.hinoo'; END IF;

    -- create consolidated
    BEGIN
      EXECUTE '
        CREATE POLICY "hinoo: select public_or_owner"
        ON public.hinoo FOR SELECT TO authenticated
        USING ( COALESCE(is_public,false) OR user_id = (SELECT auth.uid()) )
      ';
    EXCEPTION WHEN duplicate_object THEN
      -- ensure USING is correct if policy already exists
      EXECUTE '
        ALTER POLICY "hinoo: select public_or_owner" ON public.hinoo
        USING ( COALESCE(is_public,false) OR user_id = (SELECT auth.uid()) )
      ';
    END;
  ELSE
    -- no is_public column: owner-only
    PERFORM 1 FROM pg_policies WHERE schemaname='public' AND tablename='hinoo' AND policyname='hinoo public read moon';
    IF FOUND THEN EXECUTE 'DROP POLICY IF EXISTS "hinoo public read moon" ON public.hinoo'; END IF;

    PERFORM 1 FROM pg_policies WHERE schemaname='public' AND tablename='hinoo' AND policyname='hinoo select own';
    IF FOUND THEN EXECUTE 'DROP POLICY IF EXISTS "hinoo select own" ON public.hinoo'; END IF;

    BEGIN
      EXECUTE '
        CREATE POLICY "hinoo: select owner_only"
        ON public.hinoo FOR SELECT TO authenticated
        USING ( user_id = (SELECT auth.uid()) )
      ';
    EXCEPTION WHEN duplicate_object THEN
      EXECUTE '
        ALTER POLICY "hinoo: select owner_only" ON public.hinoo
        USING ( user_id = (SELECT auth.uid()) )
      ';
    END;
  END IF;
END$$;

----------------------------
-- Consolidate SELECT on honoo (optional, same pattern if table exists)
----------------------------
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='honoo') THEN
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema='public' AND table_name='honoo' AND column_name='is_public') THEN
      -- Try drop legacy duplicates (best-effort)
      EXECUTE 'DROP POLICY IF EXISTS "honoo public read" ON public.honoo';
      EXECUTE 'DROP POLICY IF EXISTS "honoo select own" ON public.honoo';
      -- Create/align consolidated
      BEGIN
        EXECUTE '
          CREATE POLICY "honoo: select public_or_owner"
          ON public.honoo FOR SELECT TO authenticated
          USING ( COALESCE(is_public,false) OR user_id = (SELECT auth.uid()) )
        ';
      EXCEPTION WHEN duplicate_object THEN
        EXECUTE '
          ALTER POLICY "honoo: select public_or_owner" ON public.honoo
          USING ( COALESCE(is_public,false) OR user_id = (SELECT auth.uid()) )
        ';
      END;
    ELSE
      EXECUTE 'DROP POLICY IF EXISTS "honoo public read" ON public.honoo';
      EXECUTE 'DROP POLICY IF EXISTS "honoo select own" ON public.honoo';
      BEGIN
        EXECUTE '
          CREATE POLICY "honoo: select owner_only"
          ON public.honoo FOR SELECT TO authenticated
          USING ( user_id = (SELECT auth.uid()) )
        ';
      EXCEPTION WHEN duplicate_object THEN
        EXECUTE '
          ALTER POLICY "honoo: select owner_only" ON public.honoo
          USING ( user_id = (SELECT auth.uid()) )
        ';
      END;
    END IF;
  END IF;
END$$;

----------------------------
-- Wrap auth.uid() via subselect in write policies (perf)
----------------------------
-- hinoo_drafts
ALTER POLICY IF EXISTS "hinoo_drafts select own"
  ON public.hinoo_drafts
  USING ( user_id = (SELECT auth.uid()) );

ALTER POLICY IF EXISTS "hinoo_drafts update own"
  ON public.hinoo_drafts
  USING      ( user_id = (SELECT auth.uid()) )
  WITH CHECK ( user_id = (SELECT auth.uid()) );

ALTER POLICY IF EXISTS "hinoo_drafts upsert own"
  ON public.hinoo_drafts
  WITH CHECK ( user_id = (SELECT auth.uid()) );

-- hinoo
ALTER POLICY IF EXISTS "hinoo delete own"
  ON public.hinoo
  USING ( user_id = (SELECT auth.uid()) );

ALTER POLICY IF EXISTS "hinoo insert own"
  ON public.hinoo
  WITH CHECK ( user_id = (SELECT auth.uid()) );

ALTER POLICY IF EXISTS "hinoo update own"
  ON public.hinoo
  USING      ( user_id = (SELECT auth.uid()) )
  WITH CHECK ( user_id = (SELECT auth.uid()) );

-- honoo
ALTER POLICY IF EXISTS "update own"
  ON public.honoo
  USING      ( user_id = (SELECT auth.uid()) )
  WITH CHECK ( user_id = (SELECT auth.uid()) );

----------------------------
-- Users: canonical auth_user_id (uuid)
----------------------------
ALTER TABLE IF EXISTS public.users
  ADD COLUMN IF NOT EXISTS auth_user_id uuid;

-- migrate from legacy auth_id if present
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='users' AND column_name='auth_id'
  ) THEN
    EXECUTE '
      UPDATE public.users
      SET auth_user_id = auth_id
      WHERE auth_user_id IS NULL AND auth_id IS NOT NULL
    ';
  END IF;
END$$;

-- switch policies to auth_user_id
ALTER POLICY IF EXISTS "select own user"
  ON public.users
  USING ( auth_user_id = (SELECT auth.uid()) );

ALTER POLICY IF EXISTS "insert own user"
  ON public.users
  WITH CHECK ( auth_user_id = (SELECT auth.uid()) );

ALTER POLICY IF EXISTS "update own user"
  ON public.users
  USING      ( auth_user_id = (SELECT auth.uid()) )
  WITH CHECK ( auth_user_id = (SELECT auth.uid()) );

-- drop legacy column auth_id if no policy depends on it
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='users' AND column_name='auth_id'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_policies
      WHERE schemaname='public' AND tablename='users'
        AND (qual ILIKE '%auth_id%' OR with_check ILIKE '%auth_id%')
    ) THEN
      EXECUTE 'ALTER TABLE public.users DROP COLUMN IF EXISTS auth_id';
    END IF;
  END IF;
END$$;

----------------------------
-- Indexes (idempotent) & dedupe
----------------------------
CREATE INDEX IF NOT EXISTS idx_hinoo_user_id         ON public.hinoo(user_id);
CREATE INDEX IF NOT EXISTS idx_hinoo_drafts_user_id  ON public.hinoo_drafts(user_id);
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='hinoo' AND column_name='is_public') THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_hinoo_is_public ON public.hinoo(is_public)';
  END IF;
END$$;
CREATE INDEX IF NOT EXISTS idx_users_auth_user_id    ON public.users(auth_user_id);

-- drop duplicated index on hinoo (keep idx_hinoo_user_id)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname='public' AND tablename='hinoo' AND indexname='hinoo_user_idx'
  ) THEN
    EXECUTE 'DROP INDEX IF EXISTS public.hinoo_user_idx';
  END IF;
END$$;

-- NOTE:
-- Views "Secure your View" handled via Dashboard autofix to ensure RLS-respecting behavior.
