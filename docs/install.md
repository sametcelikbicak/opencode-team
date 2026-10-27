# Install

Install OpenCode Team into your OpenCode configuration so you can use it in any project directory.

## Requirements

- [OpenCode](https://opencode.ai) 1.x (tested on 1.19.0)
- An OpenCode Zen account or any provider configured in opencode — the defaults use free-tier models

## Install

Clone the repository and run the installer:

```bash
git clone https://github.com/sametcelikbicak/opencode-team.git
cd opencode-team
./install.sh
```

If OpenCode is not on your PATH, install it first:

```bash
./install.sh --install-opencode
```

`--install-opencode` runs the official OpenCode 1.x installer. OpenCode 1 and 2 cannot coexist — an existing OpenCode 2 binary is replaced. Without the flag, the installer never installs OpenCode and leaves an existing binary untouched.

Restart opencode after installation. The setup is global, so it works in every project directory.

## What the installer does

`install.sh` symlinks the repo into your OpenCode config:

| Path                                | Target                         |
|-------------------------------------|--------------------------------|
| `~/.config/opencode/agents`         | `opencode-team/agents`         |
| `~/.config/opencode/commands`       | `opencode-team/commands`       |
| `~/.config/opencode/skills/team-*`  | `opencode-team/skills/team-*`  |
| `~/.config/opencode/team.yaml`      | `opencode-team/team.yaml`      |
| `~/.config/opencode/team/AGENTS.md` | `opencode-team/team/AGENTS.md` |

The repo stays in git; the config directory holds symlinks. Edit a file in the repo and it takes effect immediately.

## Manual setup

If you prefer to wire it up manually, add to `~/.config/opencode/opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "default_agent": "orchestrator",
  "instructions": [
    "~/.config/opencode/team/AGENTS.md",
    "~/.config/opencode/team.yaml"
  ]
}
```

and place the agent, command and skill files in the matching directories under `~/.config/opencode/`.

## Check

Verify the installation:

```bash
./install.sh --check
```

This exits non-zero when a symlink is missing or a required setting is not configured.

## Uninstall

Remove only symlinks that point into this repo:

```bash
./install.sh --uninstall
```

`opencode.json` is never modified by the installer.

## First run

After installation, open `opencode` in any project directory and describe an idea:

```
OpenCode Team, I want to build a task manager web app.
```

The orchestrator will start the pipeline and ask for your approval at each gate.
