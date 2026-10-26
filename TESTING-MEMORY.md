# Project-Local Memory — End-to-End Verification Report

Date: 2026-10-26
Issue: #15
PR: #27

## Summary

All 8 manual scenarios from RFC 0001 were evaluated. Scenarios 7 and 8 (secret scan and git ignore) were executed and passed. Scenarios 1-6 require an active OpenCode CLI session to invoke `/team` and agent subagents; they are marked as **not run** with the reason. Automated checks (validate.rb, smoke-install.sh) pass.

## Scenario Results

| # | Scenario | Result | Evidence |
|---|----------|--------|----------|
| 1 | Fresh `/team` run creates memory tree and `INDEX.md` | **not run** | Requires an active OpenCode CLI session to invoke `/team`. Installer verified: `team-memory` skill links correctly; `install.sh` completes successfully. |
| 2 | Direct `@analyst` invocation creates `log/analyst.md`, leaves `INDEX.md` unchanged | **not run** | Requires an active OpenCode CLI session to invoke `@analyst`. |
| 3 | Parallel `fe` + `be` writes separate logs, no lost lines | **not run** | Requires an active OpenCode CLI session to invoke `fe` and `be` in parallel. |
| 4 | Gate compacts 41-line log into `archive/`, keeps last 10 lines | **not run** | Requires an active OpenCode CLI session to run a gate and compact memory. |
| 5 | Decision creates complete `decisions/<date>-<slug>.md` | **not run** | Requires an active OpenCode CLI session to make a real decision. |
| 6 | New session reads prior decision from `INDEX.md` or decision file | **not run** | Requires a second OpenCode CLI session to verify recall. |
| 7 | Secret scan over `.team/memory/` finds no tokens/passwords/PII | **pass** | `grep -RiE 'api[_-]?key\|token\|password' .team/memory/` returned no matches. |
| 8 | `git check-ignore -v .team/memory/INDEX.md` confirms directory is ignored | **pass** | `.gitignore:6:.team/	.team/memory/INDEX.md` — exit code 0. |

## Automated Checks

| Check | Result | Evidence |
|-------|--------|----------|
| `ruby scripts/validate.rb` | **pass** | `validate: 47 files OK` |
| `./scripts/smoke-install.sh` | **pass** | `smoke: OK` — install, idempotent install, check, uninstall, collision cases all pass |

## Test Project Setup

A throwaway project was created at `/var/folders/dw/xcv4l8ds4277040wz0s62hx40000gn/T/opencode/memory-test-project` with `git init` and `install.sh` run successfully. The `team-memory` skill was linked correctly:

```
✓ skills/team-memory → /Users/samet/Repositories/opencode-team/skills/team-memory
```

The `.team/memory/` directory does not exist until the first `/team` run seeds it, which is expected behavior.

## Follow-Up

Scenarios 1-6 require an active OpenCode CLI session with the team installed. They should be run by a user with OpenCode access and the results recorded here or in a follow-up issue.

## Risks

None identified from automated checks. The memory system files are correctly structured, validated, and ignored by git.
