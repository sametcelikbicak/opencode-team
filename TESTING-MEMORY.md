# Project-Local Memory — End-to-End Verification Report

Date: 2026-10-26
Issue: #15
PR: #27

## Summary

All 8 manual scenarios from RFC 0001 were evaluated. Scenarios 1-6 were executed by a user with an active OpenCode CLI session. Scenarios 7 and 8 (secret scan and git ignore) were executed and passed. Scenario 4 (gate compaction) **failed** — a follow-up issue is required. Automated checks (validate.rb, smoke-install.sh) pass.

## Scenario Results

| # | Scenario | Result | Evidence |
|---|----------|--------|----------|
| 1 | Fresh `/team` run creates memory tree and `INDEX.md` | **pass** | User executed `/team` in a throwaway project; `.team/memory/` and `INDEX.md` created. |
| 2 | Direct `@analyst` invocation creates `log/analyst.md`, leaves `INDEX.md` unchanged | **pass** | User invoked `@analyst`; `log/analyst.md` created, `INDEX.md` unchanged. |
| 3 | Parallel `fe` + `be` writes separate logs, no lost lines | **pass** | User invoked `@fe` and `@be`; separate logs created with no lost lines. |
| 4 | Gate compacts 41-line log into `archive/`, keeps last 10 lines | **fail** | Gate compaction took too long and did not perform the expected operation. Follow-up issue required. |
| 5 | Decision creates complete `decisions/<date>-<slug>.md` | **pass** | User invoked `@architect` with a decision; decision file created with all required fields. |
| 6 | New session reads prior decision from `INDEX.md` or decision file | **pass** | New OpenCode session read the prior decision successfully. |
| 7 | Secret scan over `.team/memory/` finds no tokens/passwords/PII | **pass** | `grep -RiE 'api[_-]?key\|token\|password' .team/memory/` returned no matches. |
| 8 | `git check-ignore -v .team/memory/INDEX.md` confirms directory is ignored | **pass** | `.gitignore:6:.team/	.team/memory/INDEX.md` — exit code 0. |

## Automated Checks

| Check | Result | Evidence |
|-------|--------|----------|
| `ruby scripts/validate.rb` | **pass** | `validate: 47 files OK` |
| `./scripts/smoke-install.sh` | **pass** | `smoke: OK` — install, idempotent install, check, uninstall, collision cases all pass |

## Test Project Setup

A throwaway project was created with `git init` and `install.sh` run successfully. The `team-memory` skill was linked correctly:

```
✓ skills/team-memory → /Users/samet/Repositories/opencode-team/skills/team-memory
```

The `.team/memory/` directory does not exist until the first `/team` run seeds it, which is expected behavior.

## Follow-Up

**Scenario 4 failed.** Gate compaction did not complete correctly — it took too long and did not archive old lines or keep the last 10 lines. A follow-up issue should be created to investigate and fix the compaction logic in the orchestrator (`agents/orchestrator.md` Memory lifecycle section and `skills/team-memory/SKILL.md` compaction rules).

Scenarios 1-3, 5-8 all passed. Once scenario 4 is fixed and re-verified, the memory epic (#7) is complete.

## Risks

None identified from automated checks. The memory system files are correctly structured, validated, and ignored by git. Scenario 4 failure indicates a potential issue with gate compaction timing or logic that needs investigation.
