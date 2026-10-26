---
name: remember
description: Append a note to the active agent's project memory log.
---

Append one short note to the currently active agent's own project memory log.

- Creates a `decisions/<date>-<slug>.md` file when the note is a decision.
- Refuses secrets and raw transcripts.
- Never writes `INDEX.md` or another role's log.
- Targets the active agent; no fixed agent field.

$ARGUMENTS
