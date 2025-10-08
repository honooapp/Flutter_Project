#!/usr/bin/env bash
set -euo pipefail

export PATH="/Users/andreea/StudioProjects/development/flutter_honoo/bin:$PATH"
export SUPABASE_URL="https://lnuzzrlkcbhxuzxyekbp.supabase.co"
export SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxudXp6cmxrY2JoeHV6eHlla2JwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk4NDk5MDAsImV4cCI6MjA3NTQyNTkwMH0.702f03BMEJTyUfM6O4P-zFpAezQ8Nq0bqaD_KWuWphI"
export TEST_EMAIL="honoo-ci@example.com"
export TEST_PASSWORD="a-tua-password"
export TEST_IMAGE_URL="https://lnuzzrlkcbhxuzxyekbp.supabase.co/storage/v1/object/public/test-assets/sample.png"

flutter test \
  --concurrency=1 \
  --reporter=expanded \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=TEST_EMAIL="$TEST_EMAIL" \
  --dart-define=TEST_PASSWORD="$TEST_PASSWORD" \
  --dart-define=TEST_IMAGE_URL="$TEST_IMAGE_URL" \
  test/supabase/
