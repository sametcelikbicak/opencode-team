---
name: team-status
description: "Report the status of the software team: which stages are done, which outputs exist, what is next, which gate we are waiting at."
agent: orchestrator
---

Report the status of the software team: which stages are done, which outputs exist, what is next, which gate we are waiting at.

Read team.yaml and the .team/ directory.

## Memory summary

- `INDEX.md` line count.
- Latest 3 decisions.
- Open questions.

If memory is not initialized, print "memory not initialized" and do not fail.
