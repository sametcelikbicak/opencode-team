# How commands work

OpenCode Team defines 19 slash commands in `commands/*.md`. Run them directly in OpenCode.

## Pipeline control

| Command | What it does |
|---------|--------------|
| `/team` | Start or continue the pipeline |
| `/team-status` | Which stages are done, what's next, where you're blocked |
| `/team-next` | Run the next stage |
| `/team-approve` | Approve the current gate and continue |
| `/role` | List the team and which stage each role owns |

## Stage commands

Each pipeline stage has a direct command: `/research`, `/prd`, `/backlog`, `/ux`, `/brand`, `/architecture`, `/build`, `/qa`, `/security`, `/docs`, `/release` and `/launch`. The command runs the stage even when you are not driving the full pipeline.

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

## Installation

Installation is not a slash command. Run `./install.sh` from the repository, or see [Install](./install).

## Full list

[Command reference](./reference/commands) — generated from frontmatter: command, description and target agent.
