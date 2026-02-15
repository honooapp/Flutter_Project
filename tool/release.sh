#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 \"commit message\" vYYYY-MM-DD[.N] [release notes]" >&2
  exit 1
fi

commit_message="$1"
tag="$2"
release_notes="${3:-}"

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

if command -v gh >/dev/null; then
  if [[ -n "$release_notes" ]]; then
    gh release create "$tag" --title "$tag" --notes "$release_notes"
  else
    gh release create "$tag" --title "$tag" --generate-notes
  fi
else
  echo "gh CLI not found. Skipping GitHub Release creation." >&2
fi
