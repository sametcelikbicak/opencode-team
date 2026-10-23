# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v1.0.0] — 2026-10-23

### Added

- Self-contained local `team-*` skills under `skills/`: `team-architecture`, `team-backlog`, `team-brand`, `team-build`, `team-docs`, `team-market-research`, `team-marketing`, `team-prd`, `team-qa`, `team-release`, `team-security-review`, `team-ux`. No external skill is cloned or required.
- `team-build` adapted from the MIT-licensed test-driven development skill (Matt Pocock).
- `team-backlog` adapted from the MIT-licensed ticket-writing skill (Matt Pocock).
- `team-brand` adapted from the MIT-licensed logo and brand design skill (Kaan Kızıltuğ).
- `THIRD_PARTY_NOTICES.md` with upstream attribution and MIT licence text for adapted skills.
- `install.sh` v1 release: targets OpenCode 1.x, optional `--install-opencode` runs the official OpenCode 1.x installer, links agents/commands/team.yaml/team/AGENTS.md and `skills/team-*`, never modifies `opencode.json` (prints the recommended snippet), `--check` does not fail when recommended settings are missing, `--uninstall` only removes symlinks pointing into this repo, `--with-logo-skill` is a deprecated no-op, and `link()` refuses to replace a symlink pointing outside the repo.
- `scripts/smoke-install.sh` covering install, idempotency, check, uninstall, local-skill collision, in-repo symlink relink, and external symlink preservation.
- `scripts/validate.rb` local-only skills, required stage fields (`title`, `brief`, `gate`, `skill`, `output` under `artifact_dir`), and targeted external-skill reference scans.

### Changed

- `team.yaml` stages now reference `team-backlog`, `team-brand`, and `team-build` instead of the external `to-tickets`, `logo-design`, and `tdd` skills.
- `agents/brand.md` and `commands/brand.md` now use the local `team-brand` skill; no bundled scripts or asset library.
- README.md / README.tr.md: skill count 9 → 12, removed logo-design clone / `--with-logo-skill` / Python 3.8+ claims, documented `--install-opencode` and v1/v2 separation.
- SECURITY.md: scope updated for local skills and installer symlink handling.
- SUPPORT.md: added common-issue troubleshooting.

### Removed

- Optional `logo-design` skill clone and `--with-logo-skill` installer flag.

### Notes

- Tested with OpenCode 1.19.0 (latest v1: 1.19.4). OpenCode 2 (latest 2.1.3) is a separate future release; v1 and v2 cannot coexist. No official OpenCode 1 EOL date is claimed.

[Unreleased]: https://github.com/sametcelikbicak/opencode-team/compare/v1.0.0...HEAD
[v1.0.0]: https://github.com/sametcelikbicak/opencode-team/releases/tag/v1.0.0
