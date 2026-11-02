# Changelog

## [0.0.3] - 2026-11-02

- fix: release-prep.sh changelog format uses PR titles (#70) by @sametcelikbicak in [#70](https://github.com/sametcelikbicak/opencode-team/pull/70)
- fix: release-prep.sh previous tag detection (#68) by @sametcelikbicak in [#68](https://github.com/sametcelikbicak/opencode-team/pull/68)
- docs: add git-clone to npm migration instructions (#55) (#66)
- fix: security hardening for npm installer (#56) (#65)
- feat: add npm pack artifact test to CI (3 platforms + paths with spaces) (#64) by @sametcelikbicak in [#64](https://github.com/sametcelikbicak/opencode-team/pull/64)




All notable changes to the OpenCode Team npm package are documented in this file.

## [v0.0.2] - 2026-11-02

### Added
- Real `install`, `check`, `update`, `uninstall` CLI commands by @sametcelikbicak in [#58](https://github.com/sametcelikbicak/opencode-team/pull/58)
- Symlink (default) and copy (`--copy`) install modes by @sametcelikbicak in [#58](https://github.com/sametcelikbicak/opencode-team/pull/58)
- `--config-dir` / `OPENCODE_CONFIG_DIR` support by @sametcelikbicak in [#58](https://github.com/sametcelikbicak/opencode-team/pull/58)
- Manifest-based uninstall (`.opencode-team-manifest.json`) by @sametcelikbicak in [#58](https://github.com/sametcelikbicak/opencode-team/pull/58)
- 8 unit tests with `node --test` (zero dependencies) by @sametcelikbicak in [#58](https://github.com/sametcelikbicak/opencode-team/pull/58)

### Changed
- Release workflow: tag → changelog PR → npm publish + GitHub Release + provenance by @sametcelikbicak in [#59](https://github.com/sametcelikbicak/opencode-team/pull/59)
- `install` command no longer requires opencode on PATH by @sametcelikbicak in [#60](https://github.com/sametcelikbicak/opencode-team/pull/60)
- `check` command warns instead of failing when opencode not installed by @sametcelikbicak in [#61](https://github.com/sametcelikbicak/opencode-team/pull/61)

### Documentation
- npm install instructions in README and docs/install.md by @sametcelikbicak in [#59](https://github.com/sametcelikbicak/opencode-team/pull/59)
- Decision files: package name, version policy, copy/link by @sametcelikbicak in [#59](https://github.com/sametcelikbicak/opencode-team/pull/59)

## [v0.0.1] - 2026-11-02

### Added
- Initial npm package publication (@opencodeteam/cli) by @sametcelikbicak in [#57](https://github.com/sametcelikbicak/opencode-team/pull/57)
- Placeholder CLI with --version and --help by @sametcelikbicak in [#57](https://github.com/sametcelikbicak/opencode-team/pull/57)
