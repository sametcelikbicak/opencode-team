#!/usr/bin/env bash
# Self-check for skills/team-memory/memory-compact.sh. No framework, no network.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$ROOT/skills/team-memory/memory-compact.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

emit_entries() {
  local start="$1" end="$2" i
  for ((i = start; i <= end; i++)); do
    printf -- '- 2026-10-%02d | research | fact | entry %d | .team/01-research.md\n' "$(( (i - 1) % 28 + 1 ))" "$i"
  done
}

# An empty log must not print an integer-expression error.
mkdir -p "$WORK/empty/log"
printf '# analyst log\n\n' > "$WORK/empty/log/analyst.md"
if ! out="$(MEMORY_DIR="$WORK/empty" "$SCRIPT" analyst 2>&1)"; then
  printf '%s\n' "$out" >&2
  fail "empty log should succeed"
fi
case "$out" in
  *"integer expression"*) fail "empty log printed an integer-expression error" ;;
esac

# 45 entries -> archive 35, keep 10. A second compaction must not duplicate
# the archive header or lose entries.
mkdir -p "$WORK/logs/log" "$WORK/logs/archive"
{
  echo '# analyst log'
  echo
  emit_entries 1 45
} > "$WORK/logs/log/analyst.md"
MEMORY_DIR="$WORK/logs" "$SCRIPT" analyst >/dev/null
[ "$(grep -c '^- ' "$WORK/logs/log/analyst.md")" -eq 10 ] || fail "expected 10 entries after first compaction"
[ "$(grep -c '^# analyst archive' "$WORK/logs/archive/analyst-2026-10.md")" -eq 1 ] || fail "expected one archive header"

emit_entries 46 80 >> "$WORK/logs/log/analyst.md"
MEMORY_DIR="$WORK/logs" "$SCRIPT" analyst >/dev/null
[ "$(grep -c '^- ' "$WORK/logs/log/analyst.md")" -eq 10 ] || fail "expected 10 entries after second compaction"
[ "$(grep -c '^# analyst archive' "$WORK/logs/archive/analyst-2026-10.md")" -eq 1 ] || fail "archive header was duplicated"
[ "$(grep -c '^- ' "$WORK/logs/archive/analyst-2026-10.md")" -eq 70 ] || fail "expected 70 archived entries"

# Exact duplicate index lines are removed, and the index drops to 60 or fewer.
mkdir -p "$WORK/index-dup"
{
  echo '# Memory Index'
  echo
  echo 'project: test'
  echo 'stage: research (1/12)'
  echo 'stack: bash'
  echo 'facts:'
  for i in $(seq 1 65); do echo "- fact $((i % 20))"; done
  echo 'decisions:'
  echo 'open:'
  echo 'pointers:'
  echo 'updated: 2026-10-27'
} > "$WORK/index-dup/INDEX.md"
MEMORY_DIR="$WORK/index-dup" "$SCRIPT" >/dev/null
[ "$(wc -l < "$WORK/index-dup/INDEX.md")" -le 60 ] || fail "duplicate index lines were not compacted"

# Unique facts over the cap need semantic merging. The script must fail and
# leave the file unchanged instead of silently dropping facts.
mkdir -p "$WORK/index-unique"
{
  echo '# Memory Index'
  echo
  echo 'project: test'
  echo 'stage: research (1/12)'
  echo 'stack: bash'
  echo 'facts:'
  for i in $(seq 1 65); do echo "- unique fact $i"; done
  echo 'decisions:'
  echo 'open:'
  echo 'pointers:'
  echo 'updated: 2026-10-27'
} > "$WORK/index-unique/INDEX.md"
before="$(wc -l < "$WORK/index-unique/INDEX.md")"
if MEMORY_DIR="$WORK/index-unique" "$SCRIPT" >/dev/null 2>&1; then
  fail "unique index over 60 should fail"
fi
[ "$(wc -l < "$WORK/index-unique/INDEX.md")" -eq "$before" ] || fail "failed compaction changed INDEX.md"

# The default memory path is relative to the current project, not this repo.
mkdir -p "$WORK/cwd/.team/memory/log"
{
  echo '# analyst log'
  echo
  emit_entries 1 41
} > "$WORK/cwd/.team/memory/log/analyst.md"
(
  cd "$WORK/cwd"
  "$SCRIPT" analyst >/dev/null
)
[ "$(grep -c '^- ' "$WORK/cwd/.team/memory/log/analyst.md")" -eq 10 ] || fail "default CWD memory path was not used"

echo "memory-compact: OK"
