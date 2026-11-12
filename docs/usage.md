# Usage

Open OpenCode in any project and describe what you want:

```bash
cd ~/projects/my-new-app
opencode
```

```
> Build a freelancer invoice reminder app that sends email nudges before and after due dates.
```

The orchestrator reads `team.yaml`, picks a profile, and walks the stages. At every gate it shows you what was produced and waits for your approval.

## Running a single stage

Every role has a command. Skip the pipeline and go straight to what you need:

| Command         | Role         | What it does                                |
| --------------- | ------------ | ------------------------------------------- |
| `/research`     | analyst      | Market and competitor research              |
| `/prd`          | pm           | Product requirements document               |
| `/backlog`      | po           | Epics and user stories                      |
| `/ux`           | ux           | Screen flows, states, accessibility         |
| `/brand`        | brand        | Logo, palette, favicon set, brand guide     |
| `/architecture` | architect    | Data model, API contract, module boundaries |
| `/build`        | orchestrator | Frontend + backend implementation           |
| `/qa`           | qa           | Tests from acceptance criteria, run them    |
| `/security`     | security     | Security review                             |
| `/docs`         | docs         | README, API docs, changelog                 |
| `/release`      | devops       | Version, CHANGELOG, deploy, rollback plan   |
| `/launch`       | marketing    | Positioning, copy, channels, metrics        |

Pipeline control:

| Command         | What it does                                             |
| --------------- | -------------------------------------------------------- |
| `/team`         | Start or continue the pipeline                           |
| `/team-status`  | Which stages are done, what's next, where you're blocked |
| `/team-next`    | Run the next stage                                       |
| `/team-approve` | Approve the current gate and continue                    |
| `/role`         | List the team and which stage each role owns             |
| `/memory`       | Inspect, seed, or compact project-local agent memory     |
| `/remember`     | Append a note to the active agent's memory log           |

All agents are `mode: all`, so each one is reachable three ways: **`@agent-name`** to mention, **Shift+Tab** (or `/agents`) to switch, and the orchestrator can launch one as a subagent via the `subagent` tool.

## Models

No agent pins a model: each one runs on the session's active model (set in `~/.config/opencode/opencode.json` via `model`), so any configured provider works. To pin a model for a single agent, add a `model:` field to its frontmatter — the filename supplies the agent id, so no `name:` field is needed:

```yaml
---
description: "Marketing: positioning, copywriting, launch strategy, go-to-market"
model: opencode/nemotron-3-ultra-free
---
```

Free-tier OpenCode Zen picks used while testing: `deepseek-v4.1-flash-free` (code, image input), `beam-free` (fast, text-only), `nemotron-3-ultra-free` (Turkish copy).
