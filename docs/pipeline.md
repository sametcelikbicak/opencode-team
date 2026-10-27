# Pipeline & Gates

OpenCode Team runs an idea-to-launch pipeline with 12 stages. Each stage is a gate — the next stage starts only after you approve the current one.

## Stages

| Stage | Agent | Output | Gate |
|-------|-------|--------|------|
| research | analyst | `.team/01-research.md` | Yes |
| prd | pm | `.team/02-prd.md` | Yes |
| backlog | po | `.team/03-backlog.md` | Yes |
| ux | ux | `.team/04-ux.md` | Yes |
| brand | brand | `.team/05-brand.md` | Yes |
| architecture | architect | `.team/06-architecture.md` | Yes |
| build | fe + be | `.team/07-build.md` | Yes |
| qa | qa | `.team/08-qa.md` | Yes |
| security | security | `.team/09-security.md` | Yes |
| docs | docs | `.team/10-docs.md` | Yes |
| release | devops | `.team/11-release.md` | Yes |
| launch | marketing | `.team/12-launch.md` | Yes |

## Profiles

`team.yaml` defines two profiles. The orchestrator picks `new` in an empty directory and `change` in an existing repository, unless you say otherwise.

```yaml
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
```

## Gates

Every stage has `gate: true` by default. At each gate:

1. The orchestrator reports findings.
2. You review and approve (or request changes).
3. The next stage starts.

To skip approvals for a stage, set `gate: false` in your project's `team.yaml`.

## Customizing stages

`team.yaml` is configuration, not code. Change it and the pipeline changes — no code changes needed.

To add a stage:

1. Append it to the `stages` list in `team.yaml`.
2. Add it to the profile list(s).
3. Create `agents/<role>.md` if needed.
4. Create `commands/<role>.md` if you want a direct entry point.

To skip approvals for a stage, set `gate: false`.

## Running the pipeline

Start the pipeline:

```bash
/team
```

Run the next stage:

```bash
/team-next
```

Approve the current gate and continue:

```bash
/team-approve
```

Check status:

```bash
/team-status
```

List roles:

```bash
/role
```
