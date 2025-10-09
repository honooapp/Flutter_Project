#!/usr/bin/env bash
set -euo pipefail
echo "[guard] scanning for forbidden password-based auth calls..."
PATTERNS=(
  "auth\\.signUp\\s*\\(.*password\\s*:"
  "auth\\.updateUser\\s*\\(.*password\\s*:"
  "resetPassword"
)
FAIL=0
for P in "${PATTERNS[@]}"; do
  if rg -n --glob '!**/build/**' --glob '!**/.dart_tool/**' -e "$P" lib/ test/ > /dev/null; then
    echo "❌ Found forbidden pattern: $P"
    rg -n --glob '!**/build/**' --glob '!**/.dart_tool/**' -e "$P" lib/ test/ || true
    FAIL=1
  fi
done
if [[ $FAIL -eq 1 ]]; then
  echo "✖ guard_no_password_flows failed. Remove password-based flows."
  exit 1
fi
echo "✔ guard_no_password_flows passed."
