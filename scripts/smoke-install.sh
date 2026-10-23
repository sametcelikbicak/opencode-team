#!/usr/bin/env bash
# End-to-end install smoke test. Uses a throwaway OPENCODE_CONFIG_DIR and no network.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
CFG="$WORK/opencode"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$CFG"
printf '{"default_agent":"orchestrator"}\n' > "$CFG/opencode.json"

run() { OPENCODE_CONFIG_DIR="$CFG" "$@"; }

echo "install"
run "$REPO/install.sh" >/dev/null

echo "install (idempotent)"
run "$REPO/install.sh" >/dev/null

echo "check"
run "$REPO/install.sh" --check >/dev/null

echo "uninstall"
run "$REPO/install.sh" --uninstall >/dev/null

echo "check after uninstall must fail"
if run "$REPO/install.sh" --check >/dev/null 2>&1; then
  echo "expected --check to fail after uninstall" >&2
  exit 1
fi

echo "smoke: OK"
