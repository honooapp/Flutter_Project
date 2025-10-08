#!/usr/bin/env bash
set -euo pipefail

echo "Checking web-compat in lib/…"

FAIL=0

# 1) Platform.environment check (excluding allowed loader files)
PLATFORM_MATCHES=$(grep -R -nF "Platform.environment" lib/ || true)
if [[ -n "$PLATFORM_MATCHES" ]]; then
  FILTERED=$(echo "$PLATFORM_MATCHES" | grep -v "lib/env/env_io.dart" | grep -v "lib/env/env.dart" || true)
  if [[ -n "$FILTERED" ]]; then
    echo "❌ Found Platform.environment in lib/ (usa readEnv da lib/env/env.dart)"
    echo "$FILTERED"
    FAIL=1
  fi
fi

# 2) String.fromEnvironment check (allow env_web.dart and env_io.dart + known const holders)
STRING_MATCHES=$(grep -R -nF "String.fromEnvironment(" lib/ || true)
if [[ -n "$STRING_MATCHES" ]]; then
  FILTERED=$(echo "$STRING_MATCHES" |
    grep -v "lib/env/env_web.dart" |
    grep -v "lib/env/env_io.dart" |
    grep -v "lib/testing/live_config.dart" || true)
  if [[ -n "$FILTERED" ]]; then
    echo "❌ Found direct String.fromEnvironment(...) in lib/ (solo top-level const consentiti)"
    echo "$FILTERED"
    FAIL=1
  fi
fi

if [[ "$FAIL" -eq 1 ]]; then
  echo "❌ Web-compat check FAILED."
  exit 1
fi

echo "✅ Web-compat check OK."
