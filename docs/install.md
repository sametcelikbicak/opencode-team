# Install

Install OpenCode Team into your OpenCode configuration so you can use it in any project directory.

## Requirements

- [OpenCode](https://opencode.ai) 1.x (tested on 1.19.0; native Windows verified on 1.19.4)
- An OpenCode Zen account or any provider configured in opencode — the defaults use free-tier models

## Platform support

| Platform | Status |
|----------|--------|
| macOS | Supported |
| Linux | Supported |
| Windows (native) | Supported: Windows PowerShell 5.1 and PowerShell 7 |
| Windows (WSL) | Untested |

Use `install.sh` on macOS/Linux and `install.ps1` on native Windows. Both create symbolic links to the repository.

## Install

### macOS and Linux

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

### Windows

Open an **Administrator PowerShell**, then run:

```powershell
git clone https://github.com/sametcelikbicak/opencode-team.git
cd opencode-team
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

Windows PowerShell 5.1 is included with Windows. PowerShell 7 (`pwsh`) is also supported; with Windows Developer Mode enabled, it can create symbolic links without elevation. The installer never elevates itself or changes Developer Mode. Without link privileges, it stops before changing installation links and explains how to proceed.

`-ExecutionPolicy Bypass` applies only to the new PowerShell process. It does not change the machine's execution policy; an organization policy can still restrict script execution. In a shell that already permits scripts, `.\install.ps1` is sufficient.

OpenCode 1.x must already be on PATH. To explicitly install it when missing or incompatible, use:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -InstallOpenCode
```

This optional mode requires npm and runs `npm install --global opencode-ai@1`, then verifies the executable. It reuses an existing working 1.x installation. Without the switch, the installer never changes OpenCode. OpenCode 2 is rejected.

The default config directory is `%USERPROFILE%\.config\opencode`. To use a different directory, set the same environment variable for installation **and** subsequent OpenCode sessions:

```powershell
$env:OPENCODE_CONFIG_DIR = 'D:\my config\opencode'
.\install.ps1
opencode
```

The installer prints a JSON snippet containing paths for that actual directory. Merge it into your existing `opencode.json` to enable the orchestrator and global instructions; preserve provider/model settings. The installer does not edit JSON or JSONC.

Alternatively, for the default config directory, you can supply the team settings only to the current terminal without editing your configuration file:

```powershell
$env:OPENCODE_CONFIG_CONTENT = '{"default_agent":"orchestrator","instructions":["~/.config/opencode/team/AGENTS.md","~/.config/opencode/team.yaml"]}'
opencode
```

For a custom config directory, use the instruction paths printed by the installer. If you already use `OPENCODE_CONFIG_CONTENT`, merge these settings into its existing value instead of replacing it.

Verify or uninstall from the same elevated shell (or PowerShell 7 with Developer Mode):

```powershell
.\install.ps1 -Check
.\install.ps1 -Uninstall
```

Repeat installation is safe. Local/external skills are preserved; conflicting core entries are reported and preserved. Check fails for missing/wrong core links, missing skills, or an unavailable/incompatible OpenCode. A missing `default_agent` is a hint. Uninstall removes only this repository's links, without deleting their targets, ordinary files, or your configuration. Linked config containers are rejected to avoid modifying another directory through a parent link.

Native Windows memory maintenance uses `memory-compact.ps1`, so the team's memory helper does not require Bash. See [Memory](memory.md#native-windows).

## What the installer does

The platform's installer symlinks the repo into your OpenCode config:

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

This exits non-zero when a symlink is missing. A missing `default_agent` is shown as a hint, not a failure.

## Uninstall

Remove only symlinks that point into this repo:

```bash
./install.sh --uninstall
```

`opencode.json` is never modified by either installer. For Windows commands, see [Windows](#windows).

## First run

After installation, open `opencode` in any project directory and describe an idea:

```
OpenCode Team, I want to build a task manager web app.
```

The orchestrator will start the pipeline and ask for your approval at each gate.

## Troubleshooting

### Windows: `Database is not empty and has no session table`

This can occur when OpenCode 1.x opens a data directory previously migrated by OpenCode 2. It is separate from the team installer: a v2 database has `session_v2` instead of the v1 `session` table. See the [upstream report](https://github.com/anomalyco/opencode/issues/56764).

Keep that database and use a separate data directory for your 1.x session:

```powershell
$env:XDG_DATA_HOME = Join-Path $env:USERPROFILE '.local/share/opencode-v1'
opencode --agent orchestrator
```

This environment setting applies to the current terminal and its child processes. It preserves the original database and uses fresh v1 session/authentication data; connect your provider in the new environment if needed. The global team configuration remains in `%USERPROFILE%\.config\opencode` (or `OPENCODE_CONFIG_DIR`). It does not migrate v2 sessions. Do not delete the old database to fix this error.

### `opencode: command not found`

The installer only links files when OpenCode is already on your PATH. To install OpenCode 1.x first:

```bash
./install.sh --install-opencode
```

OpenCode 1 and 2 cannot coexist. The flag replaces an existing OpenCode 2 binary.

### Agents or commands are missing after install

Run the check:

```bash
./install.sh --check
```

It exits non-zero when a symlink is missing. A missing `default_agent` is a hint, not a failure. Restart `opencode` after linking; the config is read at startup.

### The orchestrator is not the default agent

`install.sh` never edits `opencode.json`. Add `default_agent` and the `instructions` entries from [Manual setup](#manual-setup), then restart `opencode`.

### A change in the repo does not show up

The config directory holds symlinks, not copies. Run `./install.sh --check` to confirm the targets. If the repository moved, rerun `./install.sh` from the new path.
