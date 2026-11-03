# Run Checkpoints — Verification Report

Date: 2026-10-28  
Issue: #48  
PR: to be opened

## Summary

The run checkpoint helper and its automated scenarios pass. The scenarios that need a live OpenCode session (fresh `/team`, real context compaction) were not run in this environment and are marked **not run** below. The helper tests run each command in a fresh process, so they cover state recovery after a process restart, interruption, completed-task recovery and failed-task retry.

## Automated Checks

| Check | Result | Evidence |
|-------|--------|----------|
| `python3 scripts/test-run-state.py` | **pass** | 34 checks, `run-state: OK` |
| `ruby scripts/validate.rb` | **pass** | `validate: 47 files OK` |
| `./scripts/test-memory-compact.sh` | **pass** | `memory-compact: OK` |
| `bash -n install.sh scripts/*.sh skills/team-memory/*.sh` | **pass** | exit 0, no output |
| `./scripts/smoke-install.sh` | **pass** | `smoke: OK` |
| `npm run generate:reference` | **pass** | 14 agents, 19 commands, 13 skills, 12 stages |
| `npm run docs:build` | **pass** | `build complete in 107.15s` |

The run-state test covers:

- a fresh project with no checkpoint, including an existing artifact that is not an approval;
- parallel `fe`/`be` task attempts with separate event files;
- a running attempt that is not started twice;
- completed tasks that are not rerun;
- a missing terminal write (interruption), reconciled through `status`;
- explicit retry after an interruption and after a failure, with attempt history preserved;
- approval invalidation after the artifact changes;
- malformed event JSON that is reported and not trusted;
- finding the newest run without `current`, and ignoring an invalid `current` pointer;
- path traversal, secret-looking evidence, multi-line evidence and approval outside `.team/`.

## Manual Scenarios

| # | Scenario | Result | Evidence |
|---|----------|--------|----------|
| 1 | Fresh `/team` run starts a checkpoint and does not treat an existing artifact as approved | **not run** | Needs a live OpenCode session. |
| 2 | Context compaction, then resume without rerunning a completed task | **not run** | Needs a live OpenCode session and a real compaction. |
| 3 | Process interruption between `start-task` and `finish-task` | **pass (helper)** | `status` reports the attempt as running; `retry` starts the next attempt and preserves the interrupted one. |
| 4 | Failed task retry | **pass (helper)** | Attempt 2 failed, `retry` started attempt 3; attempts 1-3 remain in history. |
| 5 | Approval tied to the artifact revision | **pass (helper)** | Changing `.team/07-build.md` after `approve` makes the approval stale. |
| 6 | Existing project without `.team/runs/` | **pass (helper)** | `status` says no checkpoint and does not mark artifacts approved. |

## Test Design

The test runs the helper as a subprocess in a temporary project, so every scenario starts with a new process and no in-memory state. That is the closest automated analogue to a new session or a resumed session. The LLM still has to read `status` at session start; that behavior is verified in the manual scenarios once they are run.

## Risks

- The helper needs Python 3. The JSON files are readable without it, but atomic writes and validation need the helper. The installer does not install Python.
- An approval record is not authentication. It records that a human approved that artifact revision; protect the project directory as usual.
- Checkpoints do not restart a stopped OpenCode process and do not guarantee exactly-once external side effects. Re-check external state before retrying.
- One active run per project. `current` is last-write-wins; pass `--run` to address an older run.
- Context compaction is an OpenCode/LLM behavior. The state survives it, but the orchestrator must read `status` before planning. Manual scenario 2 remains to be run.

## Follow-Up

Run manual scenarios 1 and 2 in a throwaway project, then update this report with the observed output.
