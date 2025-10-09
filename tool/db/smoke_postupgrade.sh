#!/usr/bin/env bash
set -euo pipefail

: "${SUPABASE_URL:?set SUPABASE_URL}"
: "${SUPABASE_ANON_KEY:?set SUPABASE_ANON_KEY}"
: "${TEST_EMAIL:?set TEST_EMAIL}"
: "${TEST_PASSWORD:?set TEST_PASSWORD}"

echo "▶ version()"
curl -s "$SUPABASE_URL/rest/v1/rpc/version" -H "apikey: $SUPABASE_ANON_KEY" || true

echo "▶ anon read (hinoo public)"
curl -s "$SUPABASE_URL/rest/v1/hinoo?select=*&limit=1" -H "apikey: $SUPABASE_ANON_KEY" | jq . || true

echo "▶ user JWT"
USER_JWT=$(curl -s -X POST "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $SUPABASE_ANON_KEY" -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}" | jq -r .access_token)
test -n "$USER_JWT" || { echo "No JWT"; exit 1; }

echo "▶ user read (hinoo_drafts owner-only)"
curl -s "$SUPABASE_URL/rest/v1/hinoo_drafts?select=*&limit=1" \
  -H "apikey: $SUPABASE_ANON_KEY" -H "Authorization: Bearer $USER_JWT" | jq . || true

echo "OK"
