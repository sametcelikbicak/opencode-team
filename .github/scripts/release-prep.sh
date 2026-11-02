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

# Build changelog entries from merged PRs between previous tag and current tag.
# Format: - PR title (#PR) by @author in [#PR](url)
CHANGELOG_ENTRY=""
if [ -n "$PREVIOUS_TAG" ]; then
  # Get all commit messages between previous tag and current tag
  COMMITS=$(git log --format='%s' "${PREVIOUS_TAG}..${TAG}" -- . ':!package-lock.json' ':!docs/.vitepress/cache' ':!docs/.vitepress/dist' 2>/dev/null || true)
  while IFS= read -r commit_msg; do
    # Extract PR number from commit message like "chore: release v0.0.3 (#69)"
    PR_NUMBER=$(echo "$commit_msg" | grep -oE '#[0-9]+' | head -1 | tr -d '#')
    if [ -n "$PR_NUMBER" ]; then
      # Get PR details from GitHub API
      PR_TITLE=$(gh pr view "$PR_NUMBER" --json title --jq '.title' 2>/dev/null || echo "$commit_msg")
      PR_AUTHOR=$(gh pr view "$PR_NUMBER" --json author --jq '.author.login' 2>/dev/null || echo "unknown")
      PR_URL=$(gh pr view "$PR_NUMBER" --json url --jq '.url' 2>/dev/null || echo "")
      if [ -n "$PR_TITLE" ] && [ -n "$PR_AUTHOR" ] && [ -n "$PR_URL" ]; then
        CHANGELOG_ENTRY="${CHANGELOG_ENTRY}- ${PR_TITLE} (#${PR_NUMBER}) by @${PR_AUTHOR} in [#${PR_NUMBER}](${PR_URL})
"
      else
        # Fallback to commit message
        CHANGELOG_ENTRY="${CHANGELOG_ENTRY}- ${commit_msg}
"
      fi
    fi
  done <<< "$COMMITS"
else
  # First release: include all commits
  COMMITS=$(git log --format='%s' "${TAG}" -- . ':!package-lock.json' ':!docs/.vitepress/cache' ':!docs/.vitepress/dist' 2>/dev/null || true)
  while IFS= read -r commit_msg; do
    PR_NUMBER=$(echo "$commit_msg" | grep -oE '#[0-9]+' | head -1 | tr -d '#')
    if [ -n "$PR_NUMBER" ]; then
      PR_TITLE=$(gh pr view "$PR_NUMBER" --json title --jq '.title' 2>/dev/null || echo "$commit_msg")
      PR_AUTHOR=$(gh pr view "$PR_NUMBER" --json author --jq '.author.login' 2>/dev/null || echo "unknown")
      PR_URL=$(gh pr view "$PR_NUMBER" --json url --jq '.url' 2>/dev/null || echo "")
      if [ -n "$PR_TITLE" ] && [ -n "$PR_AUTHOR" ] && [ -n "$PR_URL" ]; then
        CHANGELOG_ENTRY="${CHANGELOG_ENTRY}- ${PR_TITLE} (#${PR_NUMBER}) by @${PR_AUTHOR} in [#${PR_NUMBER}](${PR_URL})
"
      else
        CHANGELOG_ENTRY="${CHANGELOG_ENTRY}- ${commit_msg}
"
      fi
    fi
  done <<< "$COMMITS"
fi

if [ -z "$CHANGELOG_ENTRY" ]; then
  CHANGELOG_ENTRY="- No changes since previous release
"
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
