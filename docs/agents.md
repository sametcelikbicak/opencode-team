# Agents

OpenCode Team has 14 agent roles. All are defined with `mode: all`, so each is reachable three ways: **Tab / Shift+Tab** to cycle, **`@agent-name`** to mention, and the orchestrator can launch it as a subagent via the `task` tool.

## Role table

| Role | Agent file | Model | Writes |
|------|------------|-------|--------|
| Orchestrator | `agents/orchestrator.md` | `opencode/deepseek-v4.1-flash-free` | — (routes work) |
| Analyst | `agents/analyst.md` | `opencode/beam-free` | `.team/01-research.md` |
| PM | `agents/pm.md` | `opencode/beam-free` | `.team/02-prd.md` |
| PO | `agents/po.md` | `opencode/beam-free` | `.team/03-backlog.md` |
| UX Designer | `agents/ux.md` | `opencode/beam-free` | `.team/04-ux.md` |
| Brand | `agents/brand.md` | `opencode/deepseek-v4.1-flash-free` | `.team/05-brand.md` |
| Architect | `agents/architect.md` | `opencode/deepseek-v4.1-flash-free` | `.team/06-architecture.md` |
| Frontend | `agents/fe.md` | `opencode/deepseek-v4.1-flash-free` | `.team/07-build.md` |
| Backend | `agents/be.md` | `opencode/deepseek-v4.1-flash-free` | `.team/07-build.md` |
| QA | `agents/qa.md` | `opencode/deepseek-v4.1-flash-free` | `.team/08-qa.md` |
| Security | `agents/security.md` | `opencode/deepseek-v4.1-flash-free` | `.team/09-security.md` |
| Docs | `agents/docs.md` | `opencode/deepseek-v4.1-flash-free` | `.team/10-docs.md` |
| DevOps | `agents/devops.md` | `opencode/deepseek-v4.1-flash-free` | `.team/11-release.md` |
| Marketing | `agents/marketing.md` | `opencode/nemotron-3-ultra-free` | `.team/12-launch.md` |

Models are free-tier OpenCode Zen models. Override any of them in the agent file.

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

Directly invoked agents follow the same memory protocol as subagents — they read `.team/memory/INDEX.md` and their own log, and write at most 5 lines to their own log at the end.

## Adding a role

1. Create `agents/<role>.md` with frontmatter (`name`, `description`, `mode: all`, `model`, `permission`).
2. Reference it in `team.yaml` as `agent: <role>`.
3. Add a command in `commands/<role>.md` if you want a direct entry point.
