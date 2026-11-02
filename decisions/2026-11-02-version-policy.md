# Decision: version policy

Date: 2026-11-02  
Status: accepted  
Related issue: #47, #52

## Decision

Use semver with pre-1.0 versions: `0.0.1` → `0.0.2` → … → `1.0.0`.

- `0.0.x` releases are pre-1.0; breaking changes are allowed within minor versions per semver.
- First stable `1.0.0` publish only after `install/check/update/uninstall` commands are implemented and tested on all three platforms.
- Version is derived from the git tag (`v*`) by the release-prep workflow.
- First publish is explicit (not tag-triggered); subsequent publishes are automated on tag push.

## Alternatives considered

| Option | Reason rejected |
|--------|-----------------|
| Start at 1.0.0 immediately | Premature; CLI commands not yet complete |
| CalVer (YY.MM) | Not aligned with semver expectations for CLI tools |
| 0.0.1 → 0.0.2 → … → 1.0.0 | **Selected** — clear path to stability |
