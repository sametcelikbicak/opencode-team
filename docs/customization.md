# Customization

`team.yaml` is configuration, not code. Change it and the pipeline changes — no code changes needed.

## team.yaml

`team.yaml` defines stages, agents, skills, gates, and profiles. A project-specific `team.yaml` in your project root takes precedence over the global one.

```yaml
artifact_dir: .team
memory_dir: .team/memory

profiles:
  new:
    - research
    - prd
    - backlog
    - ux
    - brand
    - architecture
    - build
    - qa
    - security
    - docs
    - release
    - launch
  change:
    - research
    - prd
    - architecture
    - build
    - qa

stages:
  - id: research
    title: Market and user research
    agent: analyst
    skill: team-market-research
    gate: true
    output: .team/01-research.md
    brief: >
      Research the market context, competitors, target user and niche.
```

## Adding a role

1. Create `agents/<role>.md` with frontmatter (`name`, `description`, `mode: all`, `model`, `permission`).
2. Reference it in `team.yaml` as `agent: <role>`.
3. Add a command in `commands/<role>.md` if you want a direct entry point.

## Adding a stage

1. Append it to the `stages` list in `team.yaml`.
2. Add it to the profile list(s).
3. Create `agents/<role>.md` if needed.
4. Create `commands/<role>.md` if you want a direct entry point.

## Adding a skill

1. Create `skills/team-<name>/SKILL.md` with frontmatter (`name`, `description`).
2. Reference it in `team.yaml` as `skill: team-<name>`.

## Project-local vs global

- **Project-local:** `.team/` directory in your project. Gitignored. Contains stage artifacts and agent memory.
- **Global:** `~/.config/opencode/` directory. Contains the installed agents, commands, skills, and config.

The installer symlinks the repo into `~/.config/opencode/`. Edit a file in the repo and it takes effect immediately.

## memory_dir

By default, memory lives in `.team/memory/`. Override with `memory_dir` in `team.yaml`:

```yaml
memory_dir: .team/memory
```
