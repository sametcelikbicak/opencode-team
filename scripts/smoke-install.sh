#!/usr/bin/env bash
# End-to-end install smoke test. Uses a throwaway OPENCODE_CONFIG_DIR and no network.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
CFG="$WORK/opencode"
trap 'rm -rf "$WORK"' EXIT

# Fake opencode so the installer's presence and version checks pass offline.
mkdir -p "$WORK/bin"
cat > "$WORK/bin/opencode" <<'EOF'
#!/usr/bin/env bash
echo "1.19.4"
EOF
chmod +x "$WORK/bin/opencode"
export PATH="$WORK/bin:$PATH"

mkdir -p "$CFG"
printf '{"default_agent":"orchestrator"}\n' > "$CFG/opencode.json"

run() { OPENCODE_CONFIG_DIR="$CFG" "$@"; }

echo "install"
run "$REPO/install.sh" >/dev/null

echo "install (idempotent)"
run "$REPO/install.sh" >/dev/null

echo "new local skills are linked into the repo"
for skill in team-backlog team-build team-brand; do
  link="$CFG/skills/$skill"
  if [ ! -L "$link" ]; then
    echo "expected $link to be a symlink" >&2
    exit 1
  fi
  target="$(readlink "$link")"
  case "$target" in
    "$REPO"/*) ;;
    *)
      echo "expected $link to point into $REPO, got $target" >&2
      exit 1
      ;;
  esac
done

echo "check"
run "$REPO/install.sh" --check >/dev/null

echo "uninstall"
run "$REPO/install.sh" --uninstall >/dev/null

echo "check after uninstall must fail"
if run "$REPO/install.sh" --check >/dev/null 2>&1; then
  echo "expected --check to fail after uninstall" >&2
  exit 1
fi

# A real skills/team-build directory belongs to the user and must survive install.
CFG2="$WORK/opencode-collision"
mkdir -p "$CFG2/skills/team-build"
printf 'keep me\n' > "$CFG2/skills/team-build/marker"
printf '{"default_agent":"orchestrator"}\n' > "$CFG2/opencode.json"
run2() { OPENCODE_CONFIG_DIR="$CFG2" "$@"; }

echo "install with a local team-build skill"
if ! out="$(run2 "$REPO/install.sh" 2>&1)"; then
  printf '%s\n' "$out" >&2
  echo "expected install to succeed with a local team-build skill" >&2
  exit 1
fi
if ! printf '%s\n' "$out" | grep -q 'skills/team-build.*skipped (local)'; then
  printf '%s\n' "$out" >&2
  echo "expected install output to mention the local team-build skip" >&2
  exit 1
fi
[ -f "$CFG2/skills/team-build/marker" ] || {
  echo "expected the local team-build marker to survive install" >&2
  exit 1
}
[ ! -L "$CFG2/skills/team-build" ] || {
  echo "expected the local team-build directory to stay a real directory" >&2
  exit 1
}

echo "install relinks a symlink that points elsewhere in the repo"
ln -sfn "$REPO/team" "$CFG2/agents"
run2 "$REPO/install.sh" >/dev/null
[ "$(readlink "$CFG2/agents")" = "$REPO/agents" ] || {
  echo "expected the in-repo agents symlink to be relinked" >&2
  exit 1
}

# A symlink the user points outside the repo must not be replaced.
CFG3="$WORK/opencode-external"
EXTERNAL="$WORK/external-agents"
mkdir -p "$EXTERNAL" "$CFG3"
printf 'keep me\n' > "$EXTERNAL/marker"
ln -s "$EXTERNAL" "$CFG3/agents"
printf '{"default_agent":"orchestrator"}\n' > "$CFG3/opencode.json"
run3() { OPENCODE_CONFIG_DIR="$CFG3" "$@"; }

echo "install with an agents symlink outside the repo"
if out="$(run3 "$REPO/install.sh" 2>&1)"; then
  printf '%s\n' "$out" >&2
  echo "expected install to fail for an external agents symlink" >&2
  exit 1
fi
if ! printf '%s\n' "$out" | grep -q 'outside this repo'; then
  printf '%s\n' "$out" >&2
  echo "expected install output to mention the external agents symlink" >&2
  exit 1
fi
[ -L "$CFG3/agents" ] || {
  echo "expected the external agents symlink to survive install" >&2
  exit 1
}
[ "$(readlink "$CFG3/agents")" = "$EXTERNAL" ] || {
  echo "expected the external agents symlink to be untouched" >&2
  exit 1
}
[ -f "$EXTERNAL/marker" ] || {
  echo "expected the external agents target to be untouched" >&2
  exit 1
}

echo "smoke: OK"
