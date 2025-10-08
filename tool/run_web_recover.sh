#!/usr/bin/env bash
set -euo pipefail

# Config
FLUTTER_BIN="/Users/andreea/StudioProjects/development/flutter_honoo/bin/flutter"
EXPORT_PATH="/Users/andreea/StudioProjects/development/flutter_honoo/bin"
HOST="127.0.0.1"
PORT="${PORT:-0}"              # 0 = porta libera automatica
RENDERER="${RENDERER:-html}"   # html | canvaskit
VERBOSE="${VERBOSE:-0}"        # 1 per -v
DEFINE_URL="${SUPABASE_URL:-https://lnuzzrlkcbhxuzxyekbp.supabase.co}"
DEFINE_ANON="${SUPABASE_ANON_KEY:-}"

# Helper: echo step
step() { echo -e "\n=== $* ==="; }

# 0) PATH
export PATH="$EXPORT_PATH:$PATH"

# 0.b) Kill eventuali processi rimasti
step "Killing leftover devtools/flutter_tester (se presenti)"
pkill -f "dart.*devtools" 2>/dev/null || true
pkill -f "flutter_tester" 2>/dev/null || true

# 1) Precache web
step "flutter precache --web"
"$FLUTTER_BIN" precache --web

# 2) Clean & pub get
step "flutter clean"
"$FLUTTER_BIN" clean || true

step "rm -rf .dart_tool build"
rm -rf .dart_tool build

step "flutter pub get -v"
"$FLUTTER_BIN" pub get -v

# 2.b) Abilita web e lista device
step "flutter config --enable-web && flutter devices"
"$FLUTTER_BIN" config --enable-web
"$FLUTTER_BIN" devices

# 3) Run web-server
[[ -z "$DEFINE_ANON" ]] && { echo "⚠️  SUPABASE_ANON_KEY non impostata: proseguo, ma l'app potrebbe fallire sulle chiamate."; }

RUN_FLAGS=( run -d web-server --web-hostname "$HOST" --web-port "$PORT" --web-renderer "$RENDERER"
  --dart-define=SUPABASE_URL="$DEFINE_URL" )

# Passa ANON solo se presente
if [[ -n "$DEFINE_ANON" ]]; then
  RUN_FLAGS+=( --dart-define=SUPABASE_ANON_KEY="$DEFINE_ANON" )
fi

# Verbose?
if [[ "$VERBOSE" == "1" ]]; then
  RUN_FLAGS+=( -v )
fi

step "flutter ${RUN_FLAGS[*]}"
exec "$FLUTTER_BIN" "${RUN_FLAGS[@]}"
