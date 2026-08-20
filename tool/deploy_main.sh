#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

if [ -n "$(git status --porcelain)" ]; then
  echo "Deploy annullato: salva tutte le modifiche in un commit prima di continuare."
  exit 1
fi

release_sha="$(git rev-parse HEAD)"

git fetch origin main

if ! git merge-base --is-ancestor origin/main "$release_sha"; then
  echo "Deploy annullato: il commit non parte dall'ultimo origin/main."
  echo "Aggiorna il ramo senza sovrascrivere la cronologia e riprova."
  exit 1
fi

echo "Pubblicazione di $release_sha su main..."
git push origin "$release_sha:refs/heads/main"

echo "Push completato. Il workflow Safe production release eseguirà analisi e test."
echo "Il sito verrà pubblicato solo se tutti i controlli saranno verdi."
