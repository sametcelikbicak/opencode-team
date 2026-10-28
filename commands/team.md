---
name: team
description: Start or continue the software team pipeline. If an argument is given, interpret it as a profile or a stage.
agent: orchestrator
---

Start or continue the software team pipeline. If an argument is given, interpret it as a profile or a stage.

On start or resume, read the run checkpoint in `.team/runs/` with `run_state.py status` before planning or dispatching. Do not rerun completed tasks; reconcile running tasks before retrying.

Argument: $ARGUMENTS
