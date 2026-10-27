# How agents work

OpenCode Team defines 14 agent roles in `agents/*.md`. Every role uses `mode: all`, so it is reachable three ways:

- **Tab / Shift+Tab** to cycle through agents
- **`@agent-name`** to mention one directly
- the orchestrator can launch it as a subagent through the `task` tool

The orchestrator is the default agent. It routes an idea through the pipeline and asks for approval at each gate. A specialist owns one stage and writes that stage's artifact.

## Direct invocation

Every agent is reachable directly:

```
@analyst
@pm
@po
@ux
@brand
@architect
@fe
@be
@qa
@security
@docs
@devops
@marketing
```

Directly invoked agents follow the same memory protocol as subagents: read `.team/memory/INDEX.md` and their own log, then write at most 5 lines to their own log.

## Adding a role

1. Create `agents/<role>.md` with frontmatter (`name`, `description`, `mode: all`, `model`, `permission`).
2. Reference it in `team.yaml` as `agent: <role>`.
3. Add a command in `commands/<role>.md` if you want a direct entry point.

## Full list

[Agent reference](./reference/agents) — generated from frontmatter: name, description, mode and model.
