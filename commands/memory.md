---
name: memory
description: Inspect, seed, or compact project-local agent memory.
agent: orchestrator
---

Inspect, seed, or compact project-local memory in `.team/memory/`.

Arguments:

- `status` (default): read-only summary of `INDEX.md`, log sizes, latest decisions, and open questions.
- `init`: create the memory tree and missing logs; never overwrite existing content.
- `compact`: archive overflow log lines and shrink `INDEX.md`; refuse when subagents are active. If unique index lines still exceed 60, stop and report the count instead of dropping facts.

$ARGUMENTS
