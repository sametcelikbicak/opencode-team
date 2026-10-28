# Native Windows verification

Date: 2026-10-27 (Europe/Istanbul)

Issue: #42

## Automated checks

| Check | Result |
| --- | --- |
| `scripts/smoke-install.ps1`, Windows PowerShell 5.1 | Passed, 102 assertions |
| `scripts/smoke-install.ps1`, PowerShell 7.6.5 | Passed, 102 assertions |
| `scripts/test-memory-compact.ps1`, Windows PowerShell 5.1 | Passed, 38 assertions |
| `scripts/test-memory-compact.ps1`, PowerShell 7.6.5 | Passed, 38 assertions |
| `ruby scripts/validate.rb` | Passed, 47 files |
| `ruby scripts/generate-reference.rb` | Passed; generated reference unchanged |
| `bash -n install.sh scripts/*.sh skills/team-memory/*.sh` | Passed |
| Existing `scripts/smoke-install.sh` | Passed under elevated Git Bash with `MSYS=winsymlinks:nativestrict` |
| Existing `scripts/test-memory-compact.sh` | Passed |
| `npm run docs:build` | Passed |

Native tests ran elevated because Developer Mode was disabled. They use disposable directories and fake OpenCode/npm commands; they never install packages or modify actual user configuration. Existing Unix scripts were also checked, but this is a Windows run, not a new macOS/Linux run. A Windows GitHub Actions job for both shells is configured; remote CI has not been run during this work.

## Actual OpenCode 1.19.4

An isolated config/data environment using the real installed binary discovered all 14 team agents, 19 commands, and 13 local skills. A disposable `opencode.json` resolved `orchestrator` as the default and both team instruction paths. The PowerShell install/check succeeded. No provider/model calls were made.

Installation into the actual user config also passed `-Check`. The preexisting `opencode.json` SHA256 was identical before/after. The installer printed the recommended settings instead of changing provider/model/default-agent settings.

The existing user database had a v2 schema (`session_v2` and `session_message`, no `session`) and caused OpenCode 1.19.4 to fail before agent discovery. A process-local `XDG_DATA_HOME` pointing at a separate v1 data directory allowed the real user configuration to discover all 14 team agents. The original database was not reset or migrated. See [Windows database troubleshooting](docs/install.md#windows-database-is-not-empty-and-has-no-session-table).

Provider authentication, model responses, and a full idea-to-launch pipeline were not exercised. Those depend on the user's configured provider and may incur usage.

## Independent review

A fresh reviewer found one important issue: relative `OPENCODE_CONFIG_DIR`/`MEMORY_DIR` values were resolved against the process-start directory instead of PowerShell's current location after `Set-Location`. Both regressions failed before the fix. Both helpers now resolve through the PowerShell filesystem provider before normalizing with .NET; the complete native suites passed after the fix.

Review scope decisions: memory compaction still requires no concurrent writers; the existing single-line log format remains the contract; v2 session migration remains outside this Windows installer change. The separate-data-directory workaround preserves those v2 sessions rather than converting them.

The process-only `OPENCODE_CONFIG_CONTENT` startup alternative was also verified with the user's actual config: `orchestrator` resolved as the default, both team instruction paths were present, and all 14 team agents were discovered, without editing `opencode.json`.
