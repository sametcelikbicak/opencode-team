# Project-Local Memory — End-to-End Verification Report

Date: 2026-10-26  
Re-verified: 2026-10-27, 2026-11-12  
Issue: #15  
PR: #27, #30, #132

## Summary

All 8 manual scenarios from RFC 0001 were evaluated. Scenarios 1-3 and 5-8 passed in the original run. Scenario 4 (gate compaction) failed and was fixed by #28/#30. It now passes the automated compaction check and a 45-entry temporary-log run.

Scenario 8 changed meaning in #132. The original run relied on the throwaway project's own `.gitignore` containing `.team/`, which the team never wrote. The workspace now ignores itself through `.team/.gitignore`, created by the first `/team` run, by `/memory init`, or by `run_state.py start-run`/`start-task`, and scenario 8 was re-run against that mechanism.

## Scenario Results

| # | Scenario | Result | Evidence |
|---|----------|--------|----------|
| 1 | Fresh `/team` run creates memory tree and `INDEX.md` | **pass** | User executed `/team` in a throwaway project; `.team/memory/` and `INDEX.md` created. The same run now also writes `.team/.gitignore`; that creation is covered by `scripts/test-run-state.py`, not by a new live `/team` run. |
| 2 | Direct `@analyst` invocation creates `log/analyst.md`, leaves `INDEX.md` unchanged | **pass** | User invoked `@analyst`; `log/analyst.md` created, `INDEX.md` unchanged. |
| 3 | Parallel `fe` + `be` writes separate logs, no lost lines | **pass** | User invoked `@fe` and `@be`; separate logs created with no lost lines. |
| 4 | Gate compacts 41-line log into `archive/`, keeps last 10 lines | **pass** | Re-verified with `./scripts/test-memory-compact.sh`: 45 entries become 10, 35 are archived, and a second run does not duplicate the archive header. |
| 5 | Decision creates complete `decisions/<date>-<slug>.md` | **pass** | User invoked `@architect` with a decision; decision file created with all required fields. |
| 6 | New session reads prior decision from `INDEX.md` or decision file | **pass** | New OpenCode session read the prior decision successfully. |
| 7 | Secret scan over `.team/memory/` finds no tokens/passwords/PII | **pass** | `grep -RiE 'api[_-]?key\|token\|password' .team/memory/` returned no matches. |
| 8 | `git check-ignore -v .team/memory/INDEX.md` confirms the workspace is ignored | **pass** | Re-verified 2026-11-12 against `.team/.gitignore` rather than the project's own `.gitignore`: `.team/.gitignore:4:*	.team/memory/INDEX.md` — exit code 0. `git check-ignore -v .team/.gitignore` also matches, and `git add .` stages nothing under `.team/`. |

## Automated Checks

| Check | Result | Evidence |
|-------|--------|----------|
| `ruby scripts/validate.rb` | **pass** | `validate: 48 files OK` |
| `./scripts/smoke-install.sh` | **pass** | `smoke: OK` — install, idempotent install, check, uninstall, collision cases all pass |
| `./scripts/test-memory-compact.sh` | **pass** | `memory-compact: OK` — empty logs, repeated archive runs, duplicate index lines, unique over-cap index, default project path |

## Test Project Setup

A throwaway project was created with `git init` and `install.sh` run successfully. The `team-memory` skill was linked correctly:

```
✓ skills/team-memory → /Users/samet/Repositories/opencode-team/skills/team-memory
```

The `.team/memory/` directory does not exist until the first `/team` run seeds it, which is expected behavior. The throwaway project's own `.gitignore` was never edited; the ignore rule lives in `.team/.gitignore` and travels with the workspace.

Re-verified 2026-11-12 with a scratch `git init` project:

```bash
python3 <config-root>/skills/team-memory/run_state.py start-run --profile new --stage research
git check-ignore -v .team/memory/INDEX.md   # .team/.gitignore:4:*	.team/memory/INDEX.md
git check-ignore -v .team/.gitignore        # .team/.gitignore:4:*	.team/.gitignore
git add .                                   # stages main.txt only
```

## Follow-Up

Scenario 4 is resolved. `skills/team-memory/memory-compact.sh` now:

- counts empty logs without an integer-expression error;
- archives old entries and keeps the last 10;
- writes one archive header per role/month;
- removes exact duplicate lines from `INDEX.md`;
- leaves `INDEX.md` unchanged and exits non-zero when unique lines still exceed 60, because merging durable facts is semantic work for the orchestrator.

## Risks

- `INDEX.md` compaction is not semantic. If unique lines exceed 60, the script fails and the orchestrator must merge facts, move detail into a decision file, or shorten open questions.
- Two concurrent calls to the same role are last-write-wins. This is documented and out of scope for v1.
- A direct `@analyst` or `@fe` invocation never runs `/team`, so the ignore file depends on the agent following the `team/AGENTS.md` rule. `run_state.py start-run`/`start-task` also create it for the checkpoint-driven path, but a bare agent call has no deterministic hook.
