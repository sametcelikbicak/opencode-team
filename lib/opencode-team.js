// OpenCode Team CLI core — placeholder for future commands.
// Commands: install, check, update, uninstall.
// Currently only --version and --help are wired in bin/opencode-team.

export const version = '0.0.1';

export function unknownCommand(command) {
  return `"${command}" command is not yet implemented.`;
}
