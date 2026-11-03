---
name: team-release
description: Version management and deployment methodology. Semver, CHANGELOG, CI/CD, deployment steps, environment variables, rollback plan. The playbook of the devops role.
---

# Versioning and Deployment

## 1. Versioning

Semver: `MAJOR.MINOR.PATCH`

| Change | Version |
|---|---|
| Backward-incompatible API change | MAJOR |
| New feature, backward compatible | MINOR |
| Bug fix | PATCH |

Pre-release: `1.0.0-alpha.1`, `1.0.0-rc.1`

Determine the version number **with its rationale**. Do not say "we did everything"; classify what kind of change was made.

## 2. CHANGELOG

In Keep a Changelog format, **in English**:

```markdown
# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-10-21

### Added
- Invoice PDF export with configurable template

### Changed
- Dashboard query now uses the composite index on (user_id, created_at)

### Fixed
- Timezone offset applied twice when parsing invoice dates

### Security
- Session cookies now set `SameSite=Lax`
```

Rules:
- Write the changes visible to the user, not "refactor"
- Write the behavior, not the commit hash
- Breaking changes go under `### BREAKING CHANGES` with a migration note
- Date format `YYYY-MM-DD`

### When the repository already automates the CHANGELOG

If a tag push already generates the CHANGELOG, do **not** write it by hand. Review the generated release PR instead, then fix wording, missing breaking changes or migration notes there.

This repository is the reference implementation:

1. Push a `v*` tag.
2. `.github/workflows/release-prep.yml` runs `.github/scripts/release-prep.sh <tag>`.
3. The script diffs from the previous tag, groups commits by conventional prefix (`feat` → Added, `fix` → Fixed, `docs` → Documentation, `chore`/`refactor`/`perf`/`test`/`ci`/`style` → Changed, the rest → Other), adds `by @author` and `in [#PR]`, prepends a `## [<tag>] - date` section to `CHANGELOG.md`, and sets the `package.json` version.
4. The workflow commits `CHANGELOG.md` and `package.json` to `changelog/<tag>` and opens a PR.
5. After the PR merges, `.github/workflows/release-publish.yml` publishes to npm, attests provenance and creates the GitHub Release from the changelog section.

The devops role still owns the result: check the generated entry for user-visible wording, breaking changes and a migration note. Do not bump the version or edit `CHANGELOG.md` in a separate commit. If the project has no automation, write the CHANGELOG manually using the rules above.

## 3. CI/CD

Match the **existing** CI if there is one. If there is not, propose one, do not install one.

Pipeline steps (the order matters):

1. **Dependency install** — deterministic with a lockfile (`npm ci`)
2. **Lint** — fast, before writing code
3. **Type check** — `tsc --noEmit` / mypy
4. **Test** — unit + integration
5. **Build** — production output
6. **Deploy** — only from the main branch, via a tag

Rule: **the deploy step does not run automatically on the main branch.** It runs via a tag or with manual approval. Publishing by accident is bad.

Secrets are not embedded in CI; provide them as environment secrets from the repo settings.

## 4. Deployment steps

Sequential and copyable. Each step: what, how, how it is verified.

```bash
# 1. Environment preparation
npm ci

# 2. Migration (must be reversible)
npx prisma migrate deploy
# verification: npx prisma migrate status → "up to date"

# 3. Build
npm run build

# 4. Deploy
# (platform command)

# 5. Health check
curl -fsS https://api.example.com/health
# expected: {"status":"ok","version":"1.1.0"}
```

Migration order: it runs **before the code deployment** and must be backward compatible (that is, the old code must work with the new schema and the new code with the old schema). Otherwise it produces errors throughout the deployment window.

## 5. Environment variables

**Never write the value.** Only the name, type, description, requiredness.

| Variable | Type | Description | Required |
|---|---|---|---|
| DATABASE_URL | string | PostgreSQL connection string | yes |
| SESSION_SECRET | string | Session signing key (32+ bytes) | yes |

Write `.env.example`: variable names + description, values empty.

## 6. Rollback plan

A deployment is **not considered complete** without this section.

| Situation | Action | Time | Data loss |
|---|---|---|---|
| The new version fails the health check | Roll back to the previous version | 2 min | none |
| The migration ran, the application is broken | Roll back the migration + the previous version | 10 min | none (reversible schema) |
| The migration cannot be rolled back, data is corrupted | restore from backup | 30 min | the last write |

If you are making a change that cannot be rolled back, state this **before the deployment** and write a backup plan.

## 7. Monitoring

Minimum:
- Application error tracking (Sentry or equivalent) — stack trace + version + user context
- A health check endpoint (DB + critical dependency check)
- Structured logging (JSON, with a correlation ID)
- Basic uptime monitoring

Every log line should carry a request ID, otherwise debugging is impossible.

## Common mistakes

| Mistake | The right way |
|---|---|
| Writing a secret into the config | Environment variable |
| Automatic deployment from the main branch | Tag + manual approval |
| Not writing a rollback plan | Mandatory section |
| Deploying without a health check | A `/health` endpoint |
| Running the migration after the deployment | Run it first, keep it backward compatible |
| Listing commits in the CHANGELOG | Write the behavior |
| Hand-writing a CHANGELOG when the tag workflow generates it | Review the generated release PR |

## Output format

Markdown: Version and rationale / CHANGELOG (English) / CI/CD definition / Deployment steps / Environment variables / Rollback plan / Monitoring.

Explanations in the user's language (Turkish or English), CHANGELOG and commands in English.
