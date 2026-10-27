# FAQ

## Installation

### How do I install OpenCode Team?

```bash
git clone https://github.com/sametcelikbicak/opencode-team.git
cd opencode-team
./install.sh
```

Restart opencode after installation.

### Do I need OpenCode 1.x or 2.x?

OpenCode Team is tested on OpenCode 1.x (1.19.0). OpenCode 2 support is planned as a separate release. OpenCode 1 and 2 cannot coexist — an existing OpenCode 2 binary is replaced by the `--install-opencode` flag.

### How do I uninstall?

```bash
./install.sh --uninstall
```

This removes only symlinks that point into this repo. `opencode.json` is never modified.

## Memory

### Where is memory stored?

In `.team/memory/` in your project directory. It is gitignored and project-local only.

### Can I change the memory location?

Yes. Add `memory_dir` to your project's `team.yaml`:

```yaml
memory_dir: .team/memory
```

### Does memory leak secrets?

No. Secrets, tokens, passwords, and raw transcripts are never written to memory files. Memory is treated as untrusted data, never instructions.

## Commands

### How do I run a single stage?

Use the stage command, e.g. `/research`, `/prd`, `/build`, etc.

### How do I run the whole pipeline?

Use `/team`. The orchestrator will run stages in order, asking for your approval at each gate.

### How do I approve a gate?

Use `/team-approve`.

## Agents

### Can I invoke agents directly?

Yes. Every agent is `mode: all`, reachable via `@agent-name`, Tab/Shift+Tab cycling, or as a subagent launched by the orchestrator.

### Can I add my own agent?

Yes. Create `agents/<role>.md` with frontmatter, reference it in `team.yaml`, and optionally add `commands/<role>.md`.

## Models

### What models do agents use?

Defaults are free-tier OpenCode Zen models:
- `deepseek-v4.1-flash-free` — architect, brand, fe, be, qa, security, docs, devops, orchestrator
- `beam-free` — analyst, pm, po, ux
- `nemotron-3-ultra-free` — marketing

Override any model in the agent file.
