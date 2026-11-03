# Changelog

All notable changes to the OpenCode Team npm package are documented in this file.

## [v0.0.3] - 2026-11-02

### Added
- add npm pack artifact test to CI (3 platforms + paths with spaces) by @sametcelikbicak in [#64](https://github.com/sametcelikbicak/opencode-team/pull/64)

### Fixed
- release-prep.sh changelog format uses PR titles by @sametcelikbicak in [#70](https://github.com/sametcelikbicak/opencode-team/pull/70)
- release-prep.sh previous tag detection by @sametcelikbicak in [#68](https://github.com/sametcelikbicak/opencode-team/pull/68)
- security hardening for npm installer (#56) by @sametcelikbicak in [#65](https://github.com/sametcelikbicak/opencode-team/pull/65)

### Documentation
- add git-clone to npm migration instructions (#55) by @sametcelikbicak in [#66](https://github.com/sametcelikbicak/opencode-team/pull/66)

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
- persist run and task checkpoints (#48) by @sametcelikbicak in [#51](https://github.com/sametcelikbicak/opencode-team/pull/51)
- add native Windows support by @onurozkir in [#44](https://github.com/sametcelikbicak/opencode-team/pull/44)
- add memory_dir and document memory in READMEs by @sametcelikbicak in [#26](https://github.com/sametcelikbicak/opencode-team/pull/26)
- add /memory and /remember commands by @sametcelikbicak in [#25](https://github.com/sametcelikbicak/opencode-team/pull/25)
- add read/write steps to specialist agents by @sametcelikbicak in [#24](https://github.com/sametcelikbicak/opencode-team/pull/24)
- manage memory lifecycle in the orchestrator by @sametcelikbicak in [#22](https://github.com/sametcelikbicak/opencode-team/pull/22)
- add team-memory skill and universal rule by @sametcelikbicak in [#21](https://github.com/sametcelikbicak/opencode-team/pull/21)

### Fixed
- give the build report a single writer by @sametcelikbicak in [#50](https://github.com/sametcelikbicak/opencode-team/pull/50)
- memory compaction path/caps and install/Windows docs by @sametcelikbicak in [#41](https://github.com/sametcelikbicak/opencode-team/pull/41)
- constrain wordmark width so it cannot clip by @sametcelikbicak in [#40](https://github.com/sametcelikbicak/opencode-team/pull/40)
- keep wordmark from overlapping on Windows by @sametcelikbicak in [#39](https://github.com/sametcelikbicak/opencode-team/pull/39)
- favicon and mermaid support by @sametcelikbicak in [#35](https://github.com/sametcelikbicak/opencode-team/pull/35)
- add type:module and ignoreDeadLinks for VitePress build by @sametcelikbicak in [#33](https://github.com/sametcelikbicak/opencode-team/pull/33)
- add memory-compact script for gate compaction by @sametcelikbicak in [#30](https://github.com/sametcelikbicak/opencode-team/pull/30)

### Changed
- replace first-interaction bot with platform-aware templates by @sametcelikbicak in [#49](https://github.com/sametcelikbicak/opencode-team/pull/49)
- verify memory scenarios end to end by @sametcelikbicak in [#27](https://github.com/sametcelikbicak/opencode-team/pull/27)
- cover team-memory in install smoke test by @ect2000 in [#23](https://github.com/sametcelikbicak/opencode-team/pull/23)

### Documentation
- add install troubleshooting by @sametcelikbicak in [#38](https://github.com/sametcelikbicak/opencode-team/pull/38)
- generate reference pages from manifests by @sametcelikbicak in [#37](https://github.com/sametcelikbicak/opencode-team/pull/37)
- write initial guides and reference pages by @sametcelikbicak in [#34](https://github.com/sametcelikbicak/opencode-team/pull/34)
- add package-lock.json for npm ci by @sametcelikbicak in [#32](https://github.com/sametcelikbicak/opencode-team/pull/32)
- scaffold VitePress and deploy to GitHub Pages by @sametcelikbicak in [#31](https://github.com/sametcelikbicak/opencode-team/pull/31)
- update verification report with actual test results by @sametcelikbicak in [#29](https://github.com/sametcelikbicak/opencode-team/pull/29)
- publish project-local memory RFC by @sametcelikbicak in [#20](https://github.com/sametcelikbicak/opencode-team/pull/20)

### Other
- Remove hardcoded agent models, add README badges by @sametcelikbicak in [#43](https://github.com/sametcelikbicak/opencode-team/pull/43)
- build(deps): bump katex and mermaid in [#36](https://github.com/sametcelikbicak/opencode-team/pull/36)
- Remove v1 release references and drop CHANGELOG by @sametcelikbicak in [#6](https://github.com/sametcelikbicak/opencode-team/pull/6)
- Add README logo at a readable size by @sametcelikbicak in [#5](https://github.com/sametcelikbicak/opencode-team/pull/5)
- Refine v1.0.0 changelog format by @sametcelikbicak in [#4](https://github.com/sametcelikbicak/opencode-team/pull/4)
- Add self-contained v1 release with local team-* skills by @sametcelikbicak in [#3](https://github.com/sametcelikbicak/opencode-team/pull/3)
- Add phased pipeline diagram and restrict welcome workflow by @sametcelikbicak in [#2](https://github.com/sametcelikbicak/opencode-team/pull/2)
- Add contribution pipeline and install fixes by @sametcelikbicak in [#1](https://github.com/sametcelikbicak/opencode-team/pull/1)
- Initial commit by @sametcelikbicak
