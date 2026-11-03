# Output convention

Every stage writes a markdown artifact:

```
.team/
  01-research.md
  02-prd.md
  03-backlog.md
  04-ux.md
  05-brand.md
  06-architecture.md
  07-build.md
  08-qa.md
  09-security.md
  10-docs.md
  11-release.md
  12-launch.md
```

The build stage also writes intermediate `.team/07-build-fe.md` and `.team/07-build-be.md`; the orchestrator consolidates them into `07-build.md`.

## Project-local agent memory

Memory also lives under `.team/`:

```
.team/memory/
  INDEX.md                       # orchestrator-owned summary, <=60 lines
  log/
    orchestrator.md
    analyst.md
    ...                          # one log per agent role, <=40 lines
  decisions/
    YYYY-MM-DD-<slug>.md         # immutable decision records
  archive/
    <role>-YYYY-MM.md            # compacted old log lines
```

Run state sits next to memory:

```
.team/runs/
  current                         # latest run id
  <run_id>/
    run.json                      # run id, profile, stage, session ids
    events/                       # append-only task start/finish events
    approvals/                    # human gates tied to artifact hashes
```

Plain files in a folder. No database, no framework, fully diffable in git, and a human can step in at any stage.

Full protocol: `skills/team-memory/SKILL.md` and `docs/rfcs/0001-project-memory.md`.

## Run checkpoints

The orchestrator records each run and task attempt in `.team/runs/`, so a compaction or restart does not repeat completed work or skip unfinished work.

- `run.json` — unique run id, profile, stage and session ids.
- `events/` — one append-only JSON file per start or finish event.
- `approvals/` — human gate records tied to the artifact SHA-256.

At session start or after compaction the orchestrator runs `run_state.py status` from `skills/team-memory/` and resolves running, failed or completed attempts before dispatching. A completed task is not rerun; an artifact on disk is not approval.

Full protocol: [`docs/runs.md`](./runs.md).
