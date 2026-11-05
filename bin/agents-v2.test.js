import { test } from 'node:test';
import * as assert from 'node:assert';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, copyFileSync, readdirSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const ROOT = process.cwd();
const AGENTS = join(ROOT, 'agents');

function opencodeVersion() {
  try {
    return execFileSync('opencode', ['--version'], { encoding: 'utf8' }).trim();
  } catch {
    return null;
  }
}

// Guards the v2 frontmatter shape: a map under permissions makes OpenCode 2
// drop the agent file without an error.
test('every team agent loads in OpenCode 2', (t) => {
  const version = opencodeVersion();
  if (!version || !/(?:^|\s)v?2\.\d+/.test(version)) {
    t.skip('OpenCode 2.x not on PATH');
    return;
  }

  const dir = mkdtempSync(join(tmpdir(), 'opencode-team-agents-'));
  try {
    mkdirSync(join(dir, '.opencode', 'agents'), { recursive: true });
    const files = readdirSync(AGENTS).filter((f) => f.endsWith('.md'));
    const expected = files.map((f) => f.slice(0, -3));
    for (const f of files) copyFileSync(join(AGENTS, f), join(dir, '.opencode', 'agents', f));

    const out = execFileSync('opencode', ['--standalone', 'debug', 'agents'], {
      cwd: dir,
      encoding: 'utf8',
      timeout: 120000,
    });
    const ids = new Set(JSON.parse(out.slice(out.indexOf('['))).map((a) => a.id));
    const missing = expected.filter((id) => !ids.has(id));
    assert.deepStrictEqual(missing, [], `agents not loaded by OpenCode 2: ${missing.join(', ')}`);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
