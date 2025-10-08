#!/usr/bin/env bash
set -euo pipefail

# Path Flutter SDK (adatta se diverso)
export PATH="/Users/andreea/StudioProjects/development/flutter_honoo/bin:$PATH"

# --- CONFIG STAGING (env) ---
export SUPABASE_URL="https://lnuzzrlkcbhxuzxyekbp.supabase.co"
export SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxudXp6cmxrY2JoeHV6eHlla2JwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk4NDk5MDAsImV4cCI6MjA3NTQyNTkwMH0.702f03BMEJTyUfM6O4P-zFpAezQ8Nq0bqaD_KWuWphI"
export TEST_EMAIL="honoo-ci@example.com"
export TEST_PASSWORD="a-tua-password"

# Abilita scritture SOLO in staging
export ENABLE_WRITE_TESTS=1

# --- Run ---
echo "Running Supabase REST CRUD tests on staging..."
flutter test \
  --concurrency=1 \
  --reporter expanded \
  test/supabase/supabase_rest_crud_test.dart
