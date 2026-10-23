# Security policy

## Supported versions

`main` only. `v1.0.0` is the current release; OpenCode 2 support is planned as a separate release.

## Reporting

Use [private vulnerability reporting](https://github.com/sametcelikbicak/opencode-team/security/advisories/new). Do not open a public issue.

## Scope

This repo ships instructions that an AI agent executes, plus one executable (`install.sh`).

In scope:

- Prompt injection or instruction override in `agents/`, `commands/` or `skills/`
- Instructions that exfiltrate data, read secrets or run untrusted code
- `install.sh`: path traversal, unsafe symlink handling, unquoted expansion, unpinned network fetch
- Secrets committed to the repo

Out of scope:

- Vulnerabilities in opencode itself — report them upstream
- No external skills are shipped; all skills are local `team-*`. Adapted upstream content is attributed in `THIRD_PARTY_NOTICES.md` — report issues with adapted content here. Pinning problems in this repo are in scope.

## What to include

Affected file, impact, reproduction steps and a suggested fix.
