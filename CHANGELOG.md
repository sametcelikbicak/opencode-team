# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v1.0.0] - 2026-10-23

### Added
-   Self-contained local `team-*` skills under `skills/`: `team-architecture`, `team-backlog`, `team-brand`, `team-build`, `team-docs`, `team-market-research`, `team-marketing`, `team-prd`, `team-qa`, `team-release`, `team-security-review`, `team-ux`. No external skill is cloned or required by [@sametcelikbicak](https://github.com/sametcelikbicak) in [#3](https://github.com/sametcelikbicak/opencode-team/pull/3)
-   `team-build` adapted from the MIT-licensed test-driven development skill (Matt Pocock) by [@sametcelikbicak](https://github.com/sametcelikbicak) in [#3](https://github.com/sametcelikbicak/opencode-team/pull/3)
-   `team-backlog` adapted from the MIT-licensed ticket-writing skill (Matt Pocock) by [@sametcelikbicak](https://github.com/sametcelikbicak) in [#3](https://github.com/sametcelikbicak/opencode-team/pull/3)
-   `team-brand` adapted from the MIT-licensed logo and brand design skill (Kaan Kızıltuğ) by [@sametcelikbicak](https://github.com/sametcelikbicak) in [#3](https://github.com/sametcelikbicak/opencode-team/pull/3)
-   `THIRD_PARTY_NOTICES.md` with upstream attribution and MIT licence text for adapted skills by [@sametcelikbicak](https://github.com/sametcelikbicak) in [#3](https://github.com/sametcelikbicak/opencode-team/pull/3)
-   `install.sh` v1 release: targets OpenCode 1.x, optional `--install-opencode` runs the official OpenCode 1.x installer, links agents/commands/team.yaml/team/AGENTS.md and `skills/team-*`, never modifies `opencode.json` (prints the recommended snippet), `--check` does not fail when recommended settings are missing, `--uninstall` only removes symlinks pointing into this repo, `--with-logo-skill` is a deprecated no-op, and `link()` refuses to replace a symlink pointing outside the repo by [@sametcelikbicak](https://github.com/sametcelikbicak) in [#3](https://github.com/sametcelikbicak/opencode-team/pull/3)
-   `scripts/smoke-install.sh` covering install, idempotency, check, uninstall, local-skill collision, in-repo symlink relink, and external symlink preservation by [@sametcelikbicak](https://github.com/sametcelikbicak) in [#3](https://github.com/sametcelikbicak/opencode-team/pull/3)
-   `scripts/validate.rb` local-only skills, required stage fields (`title`, `brief`, `gate`, `skill`, `output` under `artifact_dir`), and targeted external-skill reference scans by [@sametcelikbicak](https://github.com/sametcelikbicak) in [#3](https://github.com/sametcelikbicak/opencode-team/pull/3)

### Changed
-   `team.yaml` stages now reference `team-backlog`, `team-brand`, and `team-build` instead of the external `to-tickets`, `logo-design`, and `tdd` skills by [@sametcelikbicak](https://github.com/sametcelikbicak) in [#3](https://github.com/sametcelikbicak/opencode-team/pull/3)
-   `agents/brand.md` and `commands/brand.md` now use the local `team-brand` skill; no bundled scripts or asset library by [@sametcelikbicak](https://github.com/sametcelikbicak) in [#3](https://github.com/sametcelikbicak/opencode-team/pull/3)
-   README.md / README.tr.md: skill count 9 → 12, removed logo-design clone / `--with-logo-skill` / Python 3.8+ claims, documented `--install-opencode` and v1/v2 separation by [@sametcelikbicak](https://github.com/sametcelikbicak) in [#3](https://github.com/sametcelikbicak/opencode-team/pull/3)
-   SECURITY.md: scope updated for local skills and installer symlink handling by [@sametcelikbicak](https://github.com/sametcelikbicak) in [#3](https://github.com/sametcelikbicak/opencode-team/pull/3)
-   SUPPORT.md: added common-issue troubleshooting by [@sametcelikbicak](https://github.com/sametcelikbicak) in [#3](https://github.com/sametcelikbicak/opencode-team/pull/3)

### Removed
-   Optional `logo-design` skill clone and `--with-logo-skill` installer flag by [@sametcelikbicak](https://github.com/sametcelikbicak) in [#3](https://github.com/sametcelikbicak/opencode-team/pull/3)

### Documentation
-   CHANGELOG.md created for v1.0.0 by [@sametcelikbicak](https://github.com/sametcelikbicak) in [#3](https://github.com/sametcelikbicak/opencode-team/pull/3)
-   CONTRIBUTING.md: removed external skill allowlist; all skills are local `team-*` by [@sametcelikbicak](https://github.com/sametcelikbicak) in [#3](https://github.com/sametcelikbicak/opencode-team/pull/3)
-   team/AGENTS.md: fixed install.sh config claim; removed "global agent pool" claim; references THIRD_PARTY_NOTICES by [@sametcelikbicak](https://github.com/sametcelikbicak) in [#3](https://github.com/sametcelikbicak/opencode-team/pull/3)

### Contributors

-   [![@sametcelikbicak](https://avatars.githubusercontent.com/u/5312741?s=64&v=4)](https://github.com/sametcelikbicak)

sametcelikbicak

### Notes

-   Tested with OpenCode 1.19.0 (latest v1: 1.19.4). OpenCode 2 (latest 2.1.3) is a separate future release; v1 and v2 cannot coexist. No official OpenCode 1 EOL date is claimed.

[Unreleased]: https://github.com/sametcelikbicak/opencode-team/compare/v1.0.0...HEAD
[v1.0.0]: https://github.com/sametcelikbicak/opencode-team/releases/tag/v1.0.0
