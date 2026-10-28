# Run checkpoints

OpenCode Team records each pipeline run and task attempt in `.team/runs/` so a compaction, restart or interrupted tool call does not force the orchestrator to reconstruct state from chat.

Artifacts are still the source of truth. A checkpoint records the attempt: which run started, which task is running, and which artifact revision a human approved. It does not replace the artifact or the gate.

## Directory

```text
.team/runs/
  current                         # latest run id (one line)
  <run_id>/
    run.json                      # run id, profile, stage, created, session ids
    events/
      <time>-<event>-<task>-a<attempt>-<token>.json
    approvals/
      <time>-<stage>-<token>.json # artifact, sha256, by, approved_at
```

`run.json` is created once. Event and approval files are append-only: every update is a new file, written atomically through a temporary file and a rename. A malformed file is ignored and reported; it is never treated as a completed task.

## `run.json`

```json
{
  "run_id": "20261028T131016577943Z-20fe61",
  "created_at": "2026-10-28T13:10:16Z",
  "profile": "new",
  "stage": "build",
  "status": "running",
  "session": "ses_...",
  "parent_session": "ses_..."
}
```

The run id is unique and distinct from reusable stage names. `current` points at the latest run; the helper still finds the newest run when `current` is missing.

## Task events

`task_started` is written before dispatch:

```json
{
  "event": "task_started",
  "at": "2026-10-28T13:11:00Z",
  "run_id": "20261028T131016577943Z-20fe61",
  "task_id": "build-fe-20261028T1300Z",
  "stage": "build",
  "agent": "fe",
  "attempt": 1,
  "status": "running",
  "session": "ses_...",
  "parent_session": "ses_...",
  "inputs": [".team/06-architecture.md"],
  "artifacts": [],
  "evidence": "",
  "next": ""
}
```

`task_finished` records the terminal outcome:

```json
{
  "event": "task_finished",
  "at": "2026-10-28T13:20:00Z",
  "run_id": "20261028T131016577943Z-20fe61",
  "task_id": "build-fe-20261028T1300Z",
  "stage": "build",
  "agent": "fe",
  "attempt": 1,
  "status": "completed",
  "session": "ses_...",
  "parent_session": "ses_...",
  "inputs": [".team/06-architecture.md"],
  "artifacts": [".team/07-build-fe.md"],
  "evidence": "unit tests: 3 pass",
  "next": "wait for be"
}
```

Terminal statuses are `completed`, `failed`, `interrupted` and `awaiting_approval`. A task with no terminal event is `running` and therefore uncertain.

## Approvals

An approval records a human gate, not a file's existence:

```json
{
  "stage": "build",
  "artifact": ".team/07-build.md",
  "sha256": "…",
  "by": "samet",
  "approved_at": "2026-10-28T13:25:00Z",
  "note": "looks good"
}
```

The helper hashes the artifact. If the artifact changes after approval, `status` reports the approval as stale. Existing artifacts from before checkpoints existed are not approvals; review them and record a new approval at the gate.

An approval record is not authentication. It records that a human approved that revision; protect the project directory as you would any other local work.

## Commands

Run from the project root. On macOS/Linux use `python3`; on Windows use `python` or `py -3` if `python3` is unavailable.

| Command | When |
|---------|------|
| `run_state.py status` | At session start, after compaction, before planning or dispatching |
| `run_state.py start-run --profile new --stage research` | No run exists yet |
| `run_state.py start-task --run <id> --task <task-id> --stage <stage> --agent <agent> --input <path>` | Before dispatching a task |
| `run_state.py finish-task --run <id> --task <task-id> --status completed --artifact <path> --evidence "..." --next "..."` | After a task succeeds |
| `run_state.py finish-task ... --status failed` or `interrupted` | When a task fails or is cancelled |
| `run_state.py retry --run <id> --task <task-id> --reason "..."` | Explicit retry after a failure or interruption |
| `run_state.py approve --run <id> --stage <stage> --artifact <path> --by <user>` | After the human approves a gate |

The helper lives at `<config-root>/skills/team-memory/run_state.py`, where the config root is `OPENCODE_CONFIG_DIR` or `~/.config/opencode` (`%USERPROFILE%\.config\opencode` on Windows). It uses only the Python standard library. If Python is unavailable, the files are plain JSON and can be read or written directly.

## Resume rules

- Read `status` before planning or dispatching.
- A `running` attempt is uncertain: inspect its artifacts and evidence, reconcile it, and ask the user before finishing or retrying it. Do not mark it completed and do not repeat side effects.
- A `completed` attempt is not rerun because the conversation was shortened.
- A `failed` or `interrupted` attempt is retried explicitly with `retry`; the earlier attempts stay in the history.
- A completed stage is not approved because its artifact exists. Only an `approve` record with a matching hash counts.
- A project without `.team/runs/` starts safely: no run, no approvals, existing artifacts are reviewed rather than assumed approved.

## Concurrency and partial state

- Event and approval filenames include a timestamp, the event/task, the attempt and a random token. Different tasks and attempts write different files.
- Each file is written once, atomically. Readers never see a half-written checkpoint.
- There is one writer per task attempt. Do not run the same task twice at once.
- Two invocations of the same attempt can still race; `status` reports duplicate terminal events as a conflict instead of picking one.
- `current` is last-write-wins. Keep one active run per project; pass `--run` when you need an older one.

## Limits

- Checkpoints help reliable continuation; they do not restart a stopped OpenCode process.
- They do not guarantee exactly-once external side effects. Re-check email, payments, deployments and other external state before retrying.
- Do not store secrets, credentials or full transcripts. Keep evidence and next-action text short; the helper rejects secret-looking text and long values.
- `.team/` is gitignored. Run state is project-local.
- The helper is optional. The JSON files are readable without it, but use the helper for atomic writes and validation when possible.

## Verification

```bash
python3 scripts/test-run-state.py
```

The test covers a fresh project, parallel tasks, interruption, explicit retry, completed-task recovery, approval invalidation, malformed JSON and path/secret guards.

For the full memory protocol see `skills/team-memory/SKILL.md`.
