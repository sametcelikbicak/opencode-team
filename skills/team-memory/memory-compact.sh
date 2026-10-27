#!/usr/bin/env bash
# Compact project-local agent memory: archive old log entries and shrink INDEX.md.
# Usage: skills/team-memory/memory-compact.sh [role]
#   With no role argument, compacts all role logs and INDEX.md.
# Run from the project root; memory defaults to $PWD/.team/memory.
set -euo pipefail

MEMORY_DIR="${MEMORY_DIR:-$PWD/.team/memory}"

# Count log entries (lines starting with "- " after the header).
log_entry_count() {
  local log="$1"
  [ -f "$log" ] || { echo 0; return; }
  awk '/^-[[:space:]]/ { n++ } END { print n + 0 }' "$log"
}

# Archive old entries from a single role log.
compact_log() {
  local role="$1"
  local log="$MEMORY_DIR/log/$role.md"
  [ -f "$log" ] || return 0
  mkdir -p "$MEMORY_DIR/archive"

  local count
  count="$(log_entry_count "$log")"
  [ "$count" -gt 40 ] || return 0

  # Read all entry lines into an indexed array.
  local -a entries=()
  local line
  while IFS= read -r line; do
    entries+=("$line")
  done < <(grep '^-[[:space:]]' "$log" 2>/dev/null || true)

  local total="${#entries[@]}"
  local keep=10
  local archive_count=$((total - keep))

  # Split entries by month into temp files.
  local tmpdir
  tmpdir="$(mktemp -d)"
  local entry date month i
  for ((i = 0; i < archive_count; i++)); do
    entry="${entries[$i]}"
    date="${entry#- }"
    date="${date%% |*}"
    month="${date:0:7}" # YYYY-MM
    printf '%s\n' "$entry" >> "$tmpdir/$month"
  done

  # Write archive files from temp files.
  local m
  for m in "$tmpdir"/*; do
    [ -f "$m" ] || continue
    local month_name
    month_name="$(basename "$m")"
    local archive_file="$MEMORY_DIR/archive/$role-$month_name.md"
    if [ ! -f "$archive_file" ]; then
      {
        echo "# $role archive — $month_name"
        echo
      } >> "$archive_file"
    fi
    cat "$m" >> "$archive_file"
  done
  rm -rf "$tmpdir"

  # Keep last 10 entries in the log.
  {
    head -n 2 "$log"   # header + blank line
    for ((i = archive_count; i < total; i++)); do
      printf '%s\n' "${entries[$i]}"
    done
  } > "$log.tmp"
  mv "$log.tmp" "$log"

  echo "compacted $role: archived $archive_count entries, kept $keep"
}

# Remove exact duplicate lines from INDEX.md. Semantic merging is the
# orchestrator's job: if unique lines still exceed 60, stop and report instead
# of dropping facts or open questions.
compact_index() {
  local index="$MEMORY_DIR/INDEX.md"
  [ -f "$index" ] || return 0

  local count
  count="$(wc -l < "$index")"
  [ "$count" -gt 60 ] || return 0

  local tmp
  tmp="$(mktemp)"
  awk '!seen[$0]++' "$index" > "$tmp"

  local new_count
  new_count="$(wc -l < "$tmp")"
  if [ "$new_count" -gt 60 ]; then
    echo "INDEX.md is $new_count lines after removing duplicates; merge facts, move detail to a decision file, or shorten open questions, then rerun." >&2
    rm -f "$tmp"
    return 1
  fi

  mv "$tmp" "$index"
  echo "compacted INDEX.md: $count -> $new_count lines"
}

main() {
  if [ $# -gt 0 ]; then
    compact_log "$1"
  else
    for role in analyst pm po ux brand architect fe be qa security docs devops marketing orchestrator; do
      compact_log "$role"
    done
  fi
  compact_index
}

main "$@"
