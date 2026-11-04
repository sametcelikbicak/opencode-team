# UX Design

The UX stage produces `.team/04-ux.md`, specifying screen flows, states
(empty, error, loading, populated), and the component inventory.
Accessibility must meet WCAG 2.1 AA.

## Agent

The `ux` agent (`agents/ux.md`, `mode: all`) owns this stage. It is invoked
via the `ux` command (`commands/ux.md`) or directly with `@ux`.

## Skill

The stage uses the `team-ux` skill (`skills/team-ux/SKILL.md`).

## Output

`.team/04-ux.md` — screen flows, state inventory, component list, and
accessibility notes.

## Prerequisites

Read `.team/02-prd.md` (if it exists) before starting.
