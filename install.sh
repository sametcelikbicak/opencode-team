#!/usr/bin/env bash
# OpenCode Team — global install
#
# Symlinks the repo into the opencode config directory. The repo stays in git,
# the config directory holds symlinks: edit a file in the repo and it takes
# effect immediately.
#
# Usage:
#   ./install.sh                    # install (logo-design skill is optional)
#   ./install.sh --with-logo-skill  # install and clone the optional logo-design skill
#   ./install.sh --check            # show status only
#   ./install.sh --uninstall

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"

# External skill, installed separately (not vendored into the repo)
LOGO_SKILL_REPO="https://github.com/kaankiziltug/logo-design-skill.git"
LOGO_SKILL_DIR="$CONFIG/skills/logo-design"

MODE="install"
WITH_LOGO=0
for arg in "$@"; do
  case "$arg" in
    --check|--uninstall) MODE="$arg" ;;
    --with-logo-skill)   WITH_LOGO=1 ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 1
      ;;
  esac
done

link() {
  local target="$1" name="$2"
  if [ -L "$CONFIG/$name" ]; then
    local current
    current="$(readlink "$CONFIG/$name")"
    if [ "$current" = "$target" ]; then
      echo "  ✓ $name → already linked"
      return
    fi
    rm "$CONFIG/$name"
  elif [ -e "$CONFIG/$name" ]; then
    echo "  ✗ $name already exists (not a symlink) — left untouched, check manually: $CONFIG/$name"
    return 1
  fi
  ln -s "$target" "$CONFIG/$name"
  echo "  ✓ $name → $target"
}

check() {
  local ok=0
  for pair in "agents:agents" "commands:commands" "team.yaml:team.yaml" "team/AGENTS.md:team/AGENTS.md"; do
    local target="$CONFIG/${pair%%:*}" name="${pair##*:}"
    if [ -L "$target" ]; then
      echo "  ✓ $name → $(readlink "$target")"
    else
      echo "  ✗ $name not linked"
      ok=1
    fi
  done
  # skills are linked one by one
  local missing=0
  for skill_dir in "$REPO"/skills/team-*/; do
    local skill
    skill="$(basename "$skill_dir")"
    if [ -L "$CONFIG/skills/$skill" ]; then
      echo "  ✓ skills/$skill"
    else
      echo "  ✗ skills/$skill not linked"
      missing=1
    fi
  done
  [ "$missing" -eq 0 ] || ok=1
  if [ -f "$LOGO_SKILL_DIR/SKILL.md" ]; then
    echo "  ✓ logo-design skill → installed ($(find "$LOGO_SKILL_DIR/assets/library/svg" -name '*.svg' 2>/dev/null | wc -l | tr -d ' ') reference logos)"
  else
    echo "  ○ logo-design skill → not installed (optional: --with-logo-skill)"
  fi
  if grep -q '"default_agent"' "$CONFIG/opencode.json" 2>/dev/null; then
    echo "  ✓ opencode.json: default_agent set"
  else
    echo "  ✗ opencode.json: default_agent missing"
    ok=1
  fi
  return $ok
}

install_skills() {
  mkdir -p "$CONFIG/skills"
  for skill_dir in "$REPO"/skills/team-*/; do
    local skill
    skill="$(basename "$skill_dir")"
    link "$REPO/skills/$skill" "skills/$skill"
  done
}

install_logo_skill() {
  if [ -f "$LOGO_SKILL_DIR/SKILL.md" ]; then
    echo "  ✓ logo-design skill → already installed"
    return
  fi
  echo "  → cloning logo-design skill (13 MB, one time)"
  local tmp
  tmp="$(mktemp -d)"
  git clone --depth 1 --quiet "$LOGO_SKILL_REPO" "$tmp/logo-design-skill"
  mkdir -p "$CONFIG/skills"
  cp -r "$tmp/logo-design-skill/skills/logo-design" "$LOGO_SKILL_DIR"
  rm -rf "$tmp"
  echo "  ✓ logo-design skill → $LOGO_SKILL_DIR"
}

case "$MODE" in
  --check)
    echo "Status ($CONFIG):"
    check
    ;;
  --uninstall)
    for name in agents commands team.yaml team/AGENTS.md; do
      if [ -L "$CONFIG/$name" ]; then rm "$CONFIG/$name"; echo "  ✓ $name removed"; fi
    done
    for skill_dir in "$REPO"/skills/team-*/; do
      skill="$(basename "$skill_dir")"
      if [ -L "$CONFIG/skills/$skill" ]; then rm "$CONFIG/skills/$skill"; echo "  ✓ skills/$skill removed"; fi
    done
    ;;
  install)
    echo "Installing ($CONFIG):"
    # Only create directories that must stay real directories. agents/ and
    # commands/ become symlinks; pre-creating them makes link() refuse to replace them.
    mkdir -p "$CONFIG/skills" "$CONFIG/team"
    link "$REPO/agents"      "agents"
    link "$REPO/commands"    "commands"
    link "$REPO/team.yaml"   "team.yaml"
    link "$REPO/team/AGENTS.md" "team/AGENTS.md"
    install_skills
    if [ "$WITH_LOGO" -eq 1 ]; then
      install_logo_skill
    else
      echo "  ○ logo-design skill → skipped (optional: --with-logo-skill)"
    fi
    echo
    echo "Done. Restart opencode."
    ;;
  *)
    echo "Unknown argument: $MODE" >&2
    exit 1
    ;;
esac
