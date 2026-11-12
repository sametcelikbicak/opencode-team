# FAQ

## Installation

### How do I install OpenCode Team?

```bash
git clone https://github.com/sametcelikbicak/opencode-team.git
cd opencode-team
./install.sh
```

Start a new OpenCode session after installation.

On native Windows, use an Administrator PowerShell and run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1` instead of `./install.sh`. See the [Windows guide](install.md#windows).

### Does it work on Windows?

Yes. Use `install.ps1` with Windows PowerShell 5.1 or PowerShell 7. Symbolic links require an Administrator PowerShell, or PowerShell 7 with Windows Developer Mode enabled. Configuration defaults to `%USERPROFILE%\.config\opencode` and supports `OPENCODE_CONFIG_DIR`. Installation and memory maintenance have native PowerShell tests and Windows CI coverage. WSL is untested. See [Windows installation](install.md#windows).

### Do I need OpenCode 2.x or 1.x?

OpenCode Team is tested on OpenCode 2.x (2.2.5). OpenCode 1.x users: use Release v1.0.0 (@opencodeteam/cli@1.0.0). OpenCode 2 and 1 cannot coexist — an existing OpenCode 1 binary is replaced by the `--install-opencode` flag.

### How do I uninstall?

```bash
./install.sh --uninstall
```

This removes only symlinks that point into this repo. `opencode.json` is never modified.

On Windows, use `.\install.ps1 -Uninstall`; `.\install.ps1 -Check` verifies the installation.

## Memory

### Where is memory stored?

In `.team/memory/` in your project directory. The first `/team` run writes `.team/.gitignore` with a single `*` line, so the whole workspace ignores itself and stays local; your project's own `.gitignore` is never touched.

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

Yes. Every agent is `mode: all`, reachable via `@agent-name`, Shift+Tab (or `/agents`), or as a subagent launched by the orchestrator.

### Can I add my own agent?

Yes. Create `agents/<role>.md` with frontmatter, reference it in `team.yaml`, and optionally add `commands/<role>.md`.

## Models

### What models do agents use?

Agents inherit the session's active model (set in `~/.config/opencode/opencode.json` via `model`). No agent pins a `model:` in its frontmatter, so all agents use the same session model unless you add `model:` to an individual agent file.

Override any model in the agent file.
