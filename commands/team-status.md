---
name: team-status
description: "Report the status of the software team: which stages are done, which outputs exist, what is next, which gate we are waiting at."
agent: orchestrator
---

Report the status of the software team: which stages are done, which outputs exist, what is next, which gate we are waiting at.

Read team.yaml and the .team/ directory.

## Run checkpoint

Read `.team/runs/` before the artifacts. From the project root, run the helper with `python3` (macOS/Linux) or `python` (Windows):

```bash
python3 <config-root>/skills/team-memory/run_state.py status
```

Report running or uncertain attempts, valid or stale approvals, warnings and the next action. If no checkpoint exists, print "no run checkpoint" and do not fail.

## Memory summary

- `INDEX.md` line count.
- Latest 3 decisions.
- Open questions.

If memory is not initialized, print "memory not initialized" and do not fail.
