#!/usr/bin/env bash
# Release preparation script for OpenCode Team npm package.
# Updates CHANGELOG.md and package.json version for a given tag.
#
# Usage: bash .github/scripts/release-prep.sh v0.0.2

set -euo pipefail

TAG="${1:?usage: release-prep.sh <tag>}"
VERSION="${TAG#v}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHANGELOG="$REPO_ROOT/CHANGELOG.md"
PACKAGE_JSON="$REPO_ROOT/package.json"

echo "Preparing release $TAG (version $VERSION)"

# --- Update package.json version ---
if command -v node >/dev/null 2>&1; then
  node -e "
    const fs = require('fs');
    const p = JSON.parse(fs.readFileSync('$PACKAGE_JSON', 'utf-8'));
    p.version = '$VERSION';
    fs.writeFileSync('$PACKAGE_JSON', JSON.stringify(p, null, 2) + '\n');
  "
  echo "  package.json version set to $VERSION"
else
  echo "  ! node not found; skipping package.json version update" >&2
fi

# --- Update CHANGELOG.md ---
PREVIOUS_TAG=""
if git tag --list | grep -q '^v'; then
  PREVIOUS_TAG="$(git tag --list 'v*' --sort=-version:refname | grep -v "^${TAG}$" | head -n 1)"
fi

if [ -n "$PREVIOUS_TAG" ]; then
  LOG_RANGE="${PREVIOUS_TAG}..${TAG}"
else
  LOG_RANGE="${TAG}"
fi

CHANGELOG_ENTRY=$(git log --format='- %s (%h)' "$LOG_RANGE" -- . ':!package-lock.json' ':!docs/.vitepress/cache' ':!docs/.vitepress/dist' 2>/dev/null || true)

if [ -z "$CHANGELOG_ENTRY" ]; then
  CHANGELOG_ENTRY="- No changes since previous release"
fi

TODAY="$(date +%Y-%m-%d)"
NEW_ENTRY="## [$VERSION] - $TODAY

$CHANGELOG_ENTRY

"

if [ -f "$CHANGELOG" ]; then
  # Insert new entry after the first line (# Changelog)
  TMPFILE="$(mktemp)"
  {
    head -n 1 "$CHANGELOG"
    echo ""
    echo "$NEW_ENTRY"
    tail -n +2 "$CHANGELOG"
  } > "$TMPFILE"
  mv "$TMPFILE" "$CHANGELOG"
else
  cat > "$CHANGELOG" << EOF
# Changelog

All notable changes to the OpenCode Team npm package are documented in this file.

$NEW_ENTRY
EOF
fi

echo "  CHANGELOG.md updated with $VERSION entry"
echo "Done."
