#!/usr/bin/env bash
set -euo pipefail
PORT="${1:-52110}"
echo "Processi in ascolto sulla porta $PORT:"
lsof -iTCP:$PORT -sTCP:LISTEN -nP || true
echo "Per killare: kill <PID>  oppure  kill -9 <PID>"
