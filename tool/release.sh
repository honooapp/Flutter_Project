#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 \"commit message\" vYYYY-MM-DD[.N]" >&2
  exit 1
fi

commit_message="$1"
tag="$2"

if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
  echo "Tag '$tag' already exists." >&2
  exit 1
fi

git add -A

if git diff --cached --quiet; then
  echo "No changes to commit. Tagging current HEAD."
else
  git commit -m "$commit_message"
fi

git tag "$tag"
git push
git push origin "$tag"
