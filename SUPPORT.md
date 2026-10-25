# Support

- **Usage question** — open an issue with the `question` label.
- **Bug** — use the bug report template and paste `./install.sh --check` output.
- **Security issue** — use [private vulnerability reporting](https://github.com/sametcelikbicak/opencode-team/security/advisories/new). Never open a public issue.
- **Feature idea** — use the feature request template.

Before opening an issue:

1. Run `./install.sh --check` and keep the output.
2. Run `ruby scripts/validate.rb`.
3. Search existing issues.

## Common issues

- `opencode: command not found` — install OpenCode 1.x first (`curl -fsSL https://opencode.ai/install | bash`) or rerun `./install.sh --install-opencode`.
- `opencode 2 detected; this release targets OpenCode 1.x` — the team currently targets OpenCode 1.x. OpenCode 1 and 2 cannot coexist; OpenCode 2 support is planned as a separate release.
- `skills/team-* skipped (local)` — a real directory or an external symlink is in the way. Move or remove it, then rerun `./install.sh`.
- `opencode.json: recommended settings not found` — add the snippet printed by `./install.sh --check` to `~/.config/opencode/opencode.json`.
- `--check` fails for a missing link — rerun `./install.sh`.
- `--with-logo-skill` is no longer needed; the brand stage uses the local `team-brand` skill.
