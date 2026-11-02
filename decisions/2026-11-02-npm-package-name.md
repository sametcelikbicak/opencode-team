# Decision: npm package name

Date: 2026-11-02  
Status: accepted  
Related issue: #47

## Decision

Publish the npm package as `@opencodeteam/cli` (scoped under the `@opencodeteam` npm organization).

## Alternatives considered

| Option | Reason rejected |
|--------|-----------------|
| `opencode-team` | Already taken on npm (v0.1.1, unrelated Korean multi-agent plugin) |
| `@sametcelikbicak/opencode-team` | Personal scope works but org scope is cleaner for a team project |
| `opencode-team-cli` | Available but less discoverable than scoped name |
| `@opencode-team/cli` | **Selected** — org scope, clear purpose, available |

## Notes

- The `@opencodeteam` npm organization must be created on npmjs.org before the first publish.
- `npm CLI` with scoped packages requires `--access public` on first publish (set in `publishConfig.access`).
- Package is published at https://www.npmjs.com/package/@opencodeteam/cli
