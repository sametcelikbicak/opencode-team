# Contributing

This repo is a set of opencode agents, commands and skills that run an idea-to-launch pipeline. Everything is bash, Markdown and YAML — there is no build step.

## Local setup

```bash
git clone https://github.com/sametcelikbicak/opencode-team.git
cd opencode-team
./install.sh --check   # show what is linked into ~/.config/opencode
./install.sh           # link agents, commands, team.yaml and skills
```

`install.sh` never edits `opencode.json`. Set `default_agent` and `instructions` yourself (see README).

The optional `logo-design` skill is not installed by default, because it clones a third-party repo:

```bash
./install.sh --with-logo-skill
```

## What you can change

| Area    | Path                     | Frontmatter                          |
| ------- | ------------------------ | ------------------------------------ |
| Agent   | `agents/<name>.md`       | `name`, `description`, `mode`        |
| Command | `commands/<name>.md`     | `name`, `description`, optional `agent` |
| Skill   | `skills/<name>/SKILL.md` | `name`, `description`                |
| Pipeline| `team.yaml`              | `stages`, `profiles`                 |

### Add an agent

1. Copy an existing file, for example `agents/pm.md`.
2. Set `name` to the file name: `agents/foo.md` → `name: foo`.
3. `description` is a single YAML string. **Quote it** when it contains `: `.
4. `mode` is one of `primary`, `subagent`, `all`.
5. Reference it from a stage (`agent:`, `support:`) or a command (`agent:`).

### Add a command

1. Copy an existing file, for example `commands/team-status.md`.
2. Set `name` to the file name.
3. Quote `description` when it contains `: `.
4. If it calls an agent, set `agent:` to an existing `agents/<name>.md`.

### Add a skill

1. Create `skills/<name>/SKILL.md`.
2. Frontmatter: `name` (must equal the directory), `description`.
3. Reference it from a `team.yaml` stage. A stage `skill` must exist in `skills/` or in the external allowlist in `scripts/validate.rb` (`logo-design`, `tdd`, `to-tickets`).

### Edit `team.yaml`

Every stage needs `id`, `title`, `agent`, `output` and `brief`. `gate` and `skill` are optional. `support` lists extra agents. `profiles.*` may only list stage ids.

## Checks

Run these before opening a PR. CI runs the same:

```bash
ruby scripts/validate.rb
bash -n install.sh scripts/*.sh
./scripts/smoke-install.sh
```

CI also runs `shellcheck --severity=error`. It is preinstalled on `ubuntu-latest`; locally, install it with your package manager if you want the same result.

## Commit and PR

- One logical change per PR.
- Imperative commit subject, for example `fix fresh install directory handling`.
- PRs are squash-merged; the PR title becomes the commit subject.
- Keep the PR template checklist.
- Never commit secrets, tokens or machine-specific paths.

## Style

- Code, comments and documentation in English. Turkish only in `README.tr.md` and `.team/` artifacts.
- No new dependency for a few lines. The validator uses Ruby stdlib only.
- Quote YAML values that contain `: `.
