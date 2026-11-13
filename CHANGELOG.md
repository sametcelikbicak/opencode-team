# Changelog

All notable changes to the OpenCode Team npm package are documented in this file.

## [v2.0.1] - 2026-11-13

### Fixed
- clear Vite Dependabot advisories with a Vite 6 override by @sametcelikbicak in [#133](https://github.com/sametcelikbicak/opencode-team/pull/133)
- check reports linked skills as unmanaged, and .team/ never ignored itself by @abdullahtas0 in [#132](https://github.com/sametcelikbicak/opencode-team/pull/132)

### Changed
- update changelog and version for v2.0.0 by @sametcelikbicak in [#131](https://github.com/sametcelikbicak/opencode-team/pull/131)
## [v2.0.0] - 2026-11-06

### Fixed
- align CLI messages and docs with OpenCode 2 by @sametcelikbicak in [#130](https://github.com/sametcelikbicak/opencode-team/pull/130)
- load all 14 agents in OpenCode 2 by @sametcelikbicak in [#127](https://github.com/sametcelikbicak/opencode-team/pull/127)

### Changed
- convert agent frontmatter to OpenCode v2 permission model by @sametcelikbicak in [#125](https://github.com/sametcelikbicak/opencode-team/pull/125)
- target OpenCode 2.x with v1.0.0 migration guidance by @sametcelikbicak in [#124](https://github.com/sametcelikbicak/opencode-team/pull/124)

### Documentation
- remove remaining v1 artifacts for OpenCode 2 by @sametcelikbicak in [#129](https://github.com/sametcelikbicak/opencode-team/pull/129)
- add v1 to v2 team upgrade guide by @sametcelikbicak in [#128](https://github.com/sametcelikbicak/opencode-team/pull/128)
- target OpenCode 2.x instead of 1.x by @sametcelikbicak in [#126](https://github.com/sametcelikbicak/opencode-team/pull/126)

### Notes

- First release targeting `OpenCode 2.x` only. `OpenCode 1.x` users must stay on v1.0.0 (`@opencodeteam/cli@1.0.0`); v1.x receives critical bug fixes only.
- **Breaking:** agent frontmatter uses the OpenCode v2 permission model (`permissions` array, `shell`, `subagent`), and `temperature` was removed. Custom agents copied from v1 need the same conversion.
- **Breaking:** the CLI and installers reject OpenCode 1.x (`TARGET_MAJOR = 2`). `--install-opencode` now installs OpenCode 2.x, replacing an existing OpenCode 1 binary because the two cannot coexist.
- Upgrading: install OpenCode 2.x, re-run the installer, then start a new session. Symlinks, `opencode.json(c)`, provider credentials, project memory (`.team/memory/`) and run checkpoints (`.team/runs/`) are preserved. See [docs/install.md](docs/install.md#upgrading-the-team-from-v1-to-v2).

## [v1.0.0] - 2026-11-05

### Added

- First stable release targeting `OpenCode 1.x` only
- Version gate: `TARGET_MAJOR = 1` in `bin/opencode-team` and `install.sh`; OpenCode 2 is explicitly rejected
- Agent frontmatter uses OpenCode v1 permission model (`permission`, `bash`, `task`)
- Installer (`install.sh`, `install.ps1`) requires OpenCode 1.x on PATH

### Changed

- update changelog and version for v0.0.5 by @sametcelikbicak in [#121](https://github.com/sametcelikbicak/opencode-team/pull/121)

### Documentation

- v1 README polish — add npm, Node, changelog, support, CoC badges by @sametcelikbicak in [#122](https://github.com/sametcelikbicak/opencode-team/pull/122)

### Notes

- This is the first stable v1 release for OpenCode 1.x users. No new features will be added to v1.x; only critical bug fixes.
- OpenCode 1 and 2 cannot coexist. OpenCode 2 support is planned as a separate major release (v2.0.0).
- After v1.0.0, the repo will move to v2.0.0 for OpenCode v2 support.

## [v0.0.5] - 2026-11-04

### Fixed

- check warns (not fails) for missing opencode by @sametcelikbicak in [#120](https://github.com/sametcelikbicak/opencode-team/pull/120)
- checkVersion warns (not fails) for missing opencode by @sametcelikbicak in [#119](https://github.com/sametcelikbicak/opencode-team/pull/119)
- OpenCode v1 compliance items (install, permissions, docs, tests) by @sametcelikbicak in [#118](https://github.com/sametcelikbicak/opencode-team/pull/118)
- release-publish version step and npm notices attribution by @sametcelikbicak in [#117](https://github.com/sametcelikbicak/opencode-team/pull/117)
- Stale TESTING docs removed; model field marked optional (#92) by @sametcelikbicak in [#92](https://github.com/sametcelikbicak/opencode-team/pull/92)
- default_agent check ignores opencode.jsonc (#91) by @sametcelikbicak in [#91](https://github.com/sametcelikbicak/opencode-team/pull/91)
- npm packaging — add test script, exclude test file, review engines constraint (#90) by @sametcelikbicak in [#90](https://github.com/sametcelikbicak/opencode-team/pull/90)
- Docs site cleanup — broken anchors, missing og.jpg, orphan RFC, index links (#89) by @sametcelikbicak in [#89](https://github.com/sametcelikbicak/opencode-team/pull/89)
- POSIX installers only warn when opencode major is not 1 (#88) by @sametcelikbicak in [#88](https://github.com/sametcelikbicak/opencode-team/pull/88)
- CLI test suite does not run on push or pull_request (#87) by @sametcelikbicak in [#87](https://github.com/sametcelikbicak/opencode-team/pull/87)
- Release tag format mismatch silently skips the GitHub Release (#86) by @sametcelikbicak in [#86](https://github.com/sametcelikbicak/opencode-team/pull/86)
- Documentation corrections (#85) by @sametcelikbicak in [#85](https://github.com/sametcelikbicak/opencode-team/pull/85)
- docs/install.md contains duplicated sections (#84) by @sametcelikbicak in [#84](https://github.com/sametcelikbicak/opencode-team/pull/84)
- README and SECURITY claim no tagged release, but v0.0.2 and v0.0.3 exist (#83) by @sametcelikbicak in [#83](https://github.com/sametcelikbicak/opencode-team/pull/83)
- Change profile skips ux and backlog but downstream agents require those artifacts (#82) by @sametcelikbicak in [#82](https://github.com/sametcelikbicak/opencode-team/pull/82)
- Memory paths are relative and break in an installed setup (#81) by @sametcelikbicak in [#81](https://github.com/sametcelikbicak/opencode-team/pull/81)
- Build stage ownership conflicts (#80) by @sametcelikbicak in [#80](https://github.com/sametcelikbicak/opencode-team/pull/80)
- Stage skills loaded during dispatch (#79) by @sametcelikbicak in [#79](https://github.com/sametcelikbicak/opencode-team/pull/79)
- release-publish.yml fork guard and protected publish environment (#78) by @sametcelikbicak in [#78](https://github.com/sametcelikbicak/opencode-team/pull/78)
- Agent permission model is over-broad (#77) by @sametcelikbicak in [#77](https://github.com/sametcelikbicak/opencode-team/pull/77)
- CLI copy mode respects manifest on update and uninstall (#76) by @sametcelikbicak in [#76](https://github.com/sametcelikbicak/opencode-team/pull/76)
- CLI argument and error handling (#75) by @sametcelikbicak in [#75](https://github.com/sametcelikbicak/opencode-team/pull/75)
- new releases auto-latest; add contributors to README by @sametcelikbicak in [#98](https://github.com/sametcelikbicak/opencode-team/pull/98)

### Changed

- update changelog and version for v0.0.4 by @sametcelikbicak in [#97](https://github.com/sametcelikbicak/opencode-team/pull/97)

## [v0.0.4] - 2026-11-03

### Fixed

- uninstall never deletes non-owned files (#74) by @sametcelikbicak in [#74](https://github.com/sametcelikbicak/opencode-team/pull/74)
- keep install manifest across reinstalls (#73) by @sametcelikbicak in [#73](https://github.com/sametcelikbicak/opencode-team/pull/73)
- release-prep.sh and release-publish.yml match rolecraft format by @sametcelikbicak in [#72](https://github.com/sametcelikbicak/opencode-team/pull/72)

### Changed

- update changelog and version for v0.0.3 by @sametcelikbicak in [#71](https://github.com/sametcelikbicak/opencode-team/pull/71)

### Documentation

- correct v0.0.1 date to v1 release date by @sametcelikbicak in [#94](https://github.com/sametcelikbicak/opencode-team/pull/94)

### Other

- Restructure README, add team-discipline, and fix release changelog by @sametcelikbicak in [#93](https://github.com/sametcelikbicak/opencode-team/pull/93)

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

## [v0.0.1] - 2026-10-23

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
- Add self-contained v1 release with local team-\* skills by @sametcelikbicak in [#3](https://github.com/sametcelikbicak/opencode-team/pull/3)
- Add phased pipeline diagram and restrict welcome workflow by @sametcelikbicak in [#2](https://github.com/sametcelikbicak/opencode-team/pull/2)
- Add contribution pipeline and install fixes by @sametcelikbicak in [#1](https://github.com/sametcelikbicak/opencode-team/pull/1)
- Initial commit by @sametcelikbicak
