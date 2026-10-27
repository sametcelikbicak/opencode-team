# Commands

OpenCode Team has 19 slash commands. Run them directly in OpenCode.

## Pipeline control

| Command | What it does |
|---------|--------------|
| `/team` | Start or continue the pipeline |
| `/team-status` | Which stages are done, what's next, where you're blocked |
| `/team-next` | Run the next stage |
| `/team-approve` | Approve the current gate and continue |
| `/role` | List the team and which stage each role owns |

## Stage commands

| Command | Agent | What it does |
|---------|-------|--------------|
| `/research` | analyst | Market and user research |
| `/prd` | pm | Product requirements document |
| `/backlog` | po | Epics and user stories |
| `/ux` | ux | Screen flows, states, accessibility |
| `/brand` | brand | Logo, palette, favicon set, brand guide |
| `/architecture` | architect | Data model, API contract, module boundaries |
| `/build` | orchestrator | Frontend + backend implementation |
| `/qa` | qa | Tests from acceptance criteria, run them |
| `/security` | security | Security review |
| `/docs` | docs | README, API docs, changelog |
| `/release` | devops | Version, CHANGELOG, deploy, rollback plan |
| `/launch` | marketing | Positioning, copy, channels, metrics |

## Memory commands

| Command | Agent | What it does |
|---------|-------|--------------|
| `/memory` | orchestrator | Inspect, seed, or compact project-local memory |
| `/remember` | active agent | Append a note to the active agent's memory log |

`/memory` arguments:

- `status` (default): read-only summary of `INDEX.md`, log sizes, latest decisions, and open questions.
- `init`: create the memory tree and missing logs; never overwrite existing content.
- `compact`: archive overflow log lines and shrink `INDEX.md`; refuse when subagents are active.

`/remember` appends one short note to the currently active agent's own log. Creates a `decisions/` file when the note is a decision. Refuses secrets and raw transcripts.

## Setup commands

| Command | What it does |
|---------|--------------|
| `/install` | Install OpenCode Team into your OpenCode config |
| `/check` | Verify the installation |
| `/uninstall` | Remove symlinks that point into this repo |
