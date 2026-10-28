## What changed

## Why

## Checklist

- [ ] `ruby scripts/validate.rb` passes
- [ ] macOS/Linux: `bash -n install.sh scripts/*.sh` and `./scripts/smoke-install.sh` pass
- [ ] Windows: `.\scripts\smoke-install.ps1` passes (CI also runs it on `windows-latest`)
- [ ] New frontmatter `description` values are quoted when they contain `: `
- [ ] `team.yaml` references resolve (`agent`, `skill`, profile stage ids)
- [ ] README updated if a command, flag, agent or stage changed
- [ ] No secrets or machine-specific paths

## Related issue
