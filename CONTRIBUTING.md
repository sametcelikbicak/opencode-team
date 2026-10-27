# Contributing

This repo is a set of opencode agents, commands and skills that run an idea-to-launch pipeline. The team itself is bash, Markdown and YAML; the documentation site is a VitePress build.

## Local setup

```bash
git clone https://github.com/sametcelikbicak/opencode-team.git
cd opencode-team
./install.sh --check   # show what is linked into ~/.config/opencode
./install.sh           # link agents, commands, team.yaml and skills
```

If OpenCode is not installed, `./install.sh --install-opencode` runs the official OpenCode 1.x installer first. Without it, the installer requires OpenCode on your PATH and only links files.

The docs site needs Node 22 and the locked dependencies:

```bash
npm ci
npm run docs:dev     # http://localhost:5173/opencode-team/
```

`install.sh` never edits `opencode.json`. Set `default_agent` and `instructions` yourself (see README).

## What you can change

| Area    | Path                     | Frontmatter                          |
| ------- | ------------------------ | ------------------------------------ |
| Agent   | `agents/<name>.md`       | `name`, `description`, `mode`        |
| Command | `commands/<name>.md`     | `name`, `description`, optional `agent` |
| Skill   | `skills/team-<name>/SKILL.md` | `name`, `description`            |
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

1. Create `skills/team-<name>/SKILL.md`.
2. Frontmatter: `name` (must equal the directory), `description`.
3. Reference it from a `team.yaml` stage. A stage `skill` must resolve to `skills/<name>/SKILL.md`; there is no external allowlist.

All skills in this repo are local `team-*`. The validator rejects the old external names (`logo-design`, `tdd`, `to-tickets`) as stage skills and any external skill references in agent or command bodies.

### Adapting an upstream skill

Adapted skills are Markdown only and do not vendor upstream scripts or assets. When you adapt MIT-licensed content:

1. Rewrite the workflow for this repo's pipeline, artifact paths and agent roles.
2. Add an adaptation footer to `SKILL.md` naming the upstream and its author.
3. Add the upstream and its MIT notice to `THIRD_PARTY_NOTICES.md`.

### Edit `team.yaml`

Every stage needs `id`, `title`, `agent`, `skill`, `gate`, `output` and `brief`. `support` lists extra agents. Outputs must be unique and under `artifact_dir` (`.team/`). `profiles.*` may only list stage ids.

## Checks

Run these before opening a PR. CI runs the same:

```bash
ruby scripts/validate.rb
bash -n install.sh scripts/*.sh
./scripts/smoke-install.sh
```

The validator checks frontmatter, filename/name matches, agent and command references, local-only skills, and the required `team.yaml` stage fields. The smoke test installs into a throwaway config directory and covers install, check, uninstall and local-skill collisions.

CI also runs `shellcheck --severity=error`. It is preinstalled on `ubuntu-latest`; locally, install it with your package manager if you want the same result.

Build the docs before opening a PR that touches `docs/`:

```bash
npm run docs:build
```

`ignoreDeadLinks` is off, so the build fails on a broken internal link.

## Generated reference

`docs/reference/agents.md`, `commands.md`, `skills.md` and `stages.md` are generated from the manifests. Do not edit them by hand.

```bash
npm run generate:reference
```

The docs build runs the generator first. CI regenerates the pages and fails when `git diff --exit-code -- docs/reference` is non-empty, so a manifest change without the generated output is rejected.

## Docs site

`docs/` is a VitePress site deployed by `.github/workflows/docs.yml` to GitHub Pages on every push to `main`. Configure the repository once: **Settings → Pages → Build and deployment → Source: GitHub Actions**.

`mermaid` is pinned to 11 because `vitepress-plugin-mermaid` does not support 12. The config also prebundles `fastdom`; without it the dev server serves the CJS module raw and the page goes blank. Do not bump `mermaid` without testing both `npm run docs:dev` and `npm run docs:build`.

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
