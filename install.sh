#!/usr/bin/env bash
# OpenCode Team — global install
#
# Symlinks the repo into the opencode config directory. The repo stays in git,
# the config directory holds symlinks: edit a file in the repo and it takes
# effect immediately.
#
# Usage:
#   ./install.sh                    # install
#   ./install.sh --install-opencode # install OpenCode 1.x, then the team
#   ./install.sh --check            # show status only
#   ./install.sh --uninstall
#
# The deprecated --with-logo-skill flag is accepted and ignored.

set -euo pipefail

# Targets OpenCode 1.x. OpenCode 2 support needs a separate release.
TARGET_MAJOR=1

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"

MODE="install"
INSTALL_OPENCODE=0
for arg in "$@"; do
  case "$arg" in
    --check|--uninstall) MODE="$arg" ;;
    --install-opencode)  INSTALL_OPENCODE=1 ;;
    --with-logo-skill)
      echo "! --with-logo-skill is no longer needed: the brand stage uses the local team-brand skill."
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 1
      ;;
  esac
done

# True when a readlink result points inside this repo.
target_in_repo() {
  case "$1" in
    "$REPO"/*) return 0 ;;
    *) return 1 ;;
  esac
}

opencode_major() {
  local ver
  ver="$(opencode --version 2>/dev/null || true)"
  printf '%s' "$ver" | sed -n 's/[^0-9]*\([0-9][0-9]*\).*/\1/p' | head -n 1
}

check_version() {
  local major
  major="$(opencode_major)"
  if [ -z "$major" ]; then
    echo "  ! could not determine opencode version; the team targets OpenCode 1.x."
  elif [ "$major" != "$TARGET_MAJOR" ]; then
    echo "  ! opencode $major detected; the team targets OpenCode 1.x. OpenCode 2 support is not available yet."
  fi
}

require_opencode() {
  if command -v opencode >/dev/null 2>&1; then
    return 0
  fi
  echo "OpenCode 1.x is required." >&2
  echo "  curl -fsSL https://opencode.ai/install | bash" >&2
  echo "  Or rerun: ./install.sh --install-opencode" >&2
  echo "  OpenCode 2 support is not available yet." >&2
  exit 1
}

install_opencode() {
  if ! command -v curl >/dev/null 2>&1; then
    echo "  ✗ curl not found. Install OpenCode 1.x manually: https://opencode.ai/docs/" >&2
    exit 1
  fi
  echo "  ! Running the official OpenCode 1.x installer."
  echo "  ! OpenCode 1 and 2 cannot coexist; an existing OpenCode 2 binary will be replaced."
  curl -fsSL https://opencode.ai/install | bash
  if ! command -v opencode >/dev/null 2>&1; then
    echo "  ✗ opencode is still not on PATH. See https://opencode.ai/docs/" >&2
    exit 1
  fi
}

link() {
  local target="$1" name="$2"
  if [ -L "$CONFIG/$name" ]; then
    local current
    current="$(readlink "$CONFIG/$name")"
    if [ "$current" = "$target" ]; then
      echo "  ✓ $name → already linked"
      return
    fi
    # Never clobber a symlink the user points at their own config.
    if ! target_in_repo "$current"; then
      echo "  ✗ $name → $current is outside this repo — left untouched, check manually: $CONFIG/$name" >&2
      return 1
    fi
    rm "$CONFIG/$name"
  elif [ -e "$CONFIG/$name" ]; then
    echo "  ✗ $name already exists (not a symlink) — left untouched, check manually: $CONFIG/$name"
    return 1
  fi
  ln -s "$target" "$CONFIG/$name"
  echo "  ✓ $name → $target"
}

# Skills are never replaced when they are real directories or managed elsewhere.
link_skill() {
  local skill="$1"
  local dest="$CONFIG/skills/$skill"
  local target="$REPO/skills/$skill"
  if [ -L "$dest" ]; then
    local current
    current="$(readlink "$dest")"
    if [ "$current" = "$target" ]; then
      echo "  ✓ skills/$skill → already linked"
    elif target_in_repo "$current"; then
      rm "$dest"
      ln -s "$target" "$dest"
      echo "  ✓ skills/$skill → $target"
    else
      echo "  ○ skills/$skill → skipped (not managed: $current)"
    fi
    return 0
  fi
  if [ -e "$dest" ]; then
    echo "  ○ skills/$skill → skipped (local)"
    return 0
  fi
  ln -s "$target" "$dest"
  echo "  ✓ skills/$skill → $target"
}

install_skills() {
  mkdir -p "$CONFIG/skills"
  local skill_dir skill
  for skill_dir in "$REPO"/skills/team-*/; do
    [ -d "$skill_dir" ] || continue
    skill="$(basename "$skill_dir")"
    link_skill "$skill"
  done
}

remove_managed() {
  local path="$1" name="$2"
  if [ -L "$path" ]; then
    local current
    current="$(readlink "$path")"
    if target_in_repo "$current"; then
      rm "$path"
      echo "  ✓ $name removed"
    else
      echo "  ○ $name skipped (not managed: $current)"
    fi
  fi
}

has_default_agent() {
  grep -q '"default_agent"[[:space:]]*:[[:space:]]*"orchestrator"' "$CONFIG/opencode.json" 2>/dev/null
}

print_config_snippet() {
  cat <<'JSON'
{
  "$schema": "https://opencode.ai/config.json",
  "default_agent": "orchestrator",
  "instructions": [
    "~/.config/opencode/team/AGENTS.md",
    "~/.config/opencode/team.yaml"
  ]
}
JSON
}

check() {
  local ok=0 ver pair target name missing skill_dir skill

  if command -v opencode >/dev/null 2>&1; then
    ver="$(opencode --version 2>/dev/null || true)"
    echo "  ✓ opencode ${ver:-installed}"
    check_version
  else
    echo "  ✗ opencode not found"
    ok=1
  fi

  for pair in "agents:agents" "commands:commands" "team.yaml:team.yaml" "team/AGENTS.md:team/AGENTS.md"; do
    target="$CONFIG/${pair%%:*}"
    name="${pair##*:}"
    if [ -L "$target" ] && target_in_repo "$(readlink "$target")"; then
      echo "  ✓ $name → $(readlink "$target")"
    else
      echo "  ✗ $name not linked"
      ok=1
    fi
  done

  missing=0
  for skill_dir in "$REPO"/skills/team-*/; do
    [ -d "$skill_dir" ] || continue
    skill="$(basename "$skill_dir")"
    if [ -L "$CONFIG/skills/$skill" ]; then
      if target_in_repo "$(readlink "$CONFIG/skills/$skill")"; then
        echo "  ✓ skills/$skill"
      else
        echo "  ○ skills/$skill (not managed)"
      fi
    elif [ -e "$CONFIG/skills/$skill" ]; then
      echo "  ○ skills/$skill (local)"
    else
      echo "  ✗ skills/$skill not linked"
      missing=1
    fi
  done
  [ "$missing" -eq 0 ] || ok=1

  if has_default_agent; then
    echo "  ✓ opencode.json: default_agent is orchestrator"
  else
    echo "  ○ opencode.json: recommended settings not found"
    echo "    Add to $CONFIG/opencode.json:"
    print_config_snippet | sed 's/^/    /'
  fi

  return $ok
}

case "$MODE" in
  --check)
    echo "Status ($CONFIG):"
    check
    ;;
  --uninstall)
    for name in agents commands team.yaml team/AGENTS.md; do
      remove_managed "$CONFIG/$name" "$name"
    done
    for path in "$CONFIG"/skills/team-*; do
      [ -L "$path" ] || continue
      remove_managed "$path" "skills/$(basename "$path")"
    done
    echo
    echo "opencode.json was not modified."
    ;;
  install)
    echo "Installing ($CONFIG):"
    if [ "$INSTALL_OPENCODE" -eq 1 ]; then
      install_opencode
    fi
    require_opencode
    check_version
    # Only create directories that must stay real directories. agents/ and
    # commands/ become symlinks; pre-creating them makes link() refuse to replace them.
    mkdir -p "$CONFIG/skills" "$CONFIG/team"
    link "$REPO/agents"      "agents"
    link "$REPO/commands"    "commands"
    link "$REPO/team.yaml"   "team.yaml"
    link "$REPO/team/AGENTS.md" "team/AGENTS.md"
    install_skills
    echo
    if has_default_agent; then
      echo "  ✓ opencode.json: default_agent is orchestrator"
    else
      echo "Add this to $CONFIG/opencode.json:"
      print_config_snippet
    fi
    echo
    echo "Restart opencode."
    ;;
  *)
    echo "Unknown argument: $MODE" >&2
    exit 1
    ;;
esac
