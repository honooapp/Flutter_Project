#!/usr/bin/env bash
set -euo pipefail

echo "== Honoo local checks: inviti casa + messaggi =="

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter non trovato nel PATH." >&2
  exit 1
fi

echo "Flutter: $(flutter --version | head -n 1)"

echo "\n[1/4] flutter analyze"
flutter analyze

echo "\n[2/4] flutter test (opzionale)"
if [ "${SKIP_TESTS:-0}" = "1" ]; then
  echo "SKIP_TESTS=1 -> test saltati"
else
  flutter test
fi

echo "\n[3/4] Verifica migrazioni Supabase"
if command -v supabase >/dev/null 2>&1; then
  echo "Supabase CLI trovato. Per applicare migrazioni:"
  echo "  supabase db push"
else
  echo "Supabase CLI non trovato. Applica le migrazioni dal tuo ambiente CI/staging."
fi

cat <<'EOF'

[4/4] Verifica manuale (richiede credenziali/staging)
1) Admin -> Menu Admin -> invito utente
2) Utente invitato -> login -> Home -> dialog 'Crea il campanello'
3) Risposta da Luna -> Scrigno -> thread con risposta sopra e originale sotto

Note: Le notifiche sono in-app (dialog Home). Non inviamo email/push.
EOF
