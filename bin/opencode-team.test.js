import { test } from 'node:test';
import * as assert from 'node:assert';
import { execSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, existsSync, rmSync, readlinkSync, symlinkSync, readdirSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const CLI = join(process.cwd(), 'bin', 'opencode-team');

function run(args, env = {}) {
  const fullEnv = { ...process.env, ...env };
  try {
    const out = execSync(`node ${CLI} ${args.join(' ')}`, {
      env: fullEnv,
      encoding: 'utf-8',
      stdio: ['pipe', 'pipe', 'pipe'],
    });
    return { code: 0, stdout: out, stderr: '' };
  } catch (err) {
    return {
      code: err.status || 1,
      stdout: err.stdout ? err.stdout.toString() : '',
      stderr: err.stderr ? err.stderr.toString() : '',
    };
  }
}

function freshConfigDir() {
  return mkdtempSync(join(tmpdir(), 'opencode-team-test-'));
}

test('CLI --version prints version', (t) => {
  const result = run(['--version']);
  assert.strictEqual(result.code, 0);
  assert.ok(result.stdout.trim().match(/^\d+\.\d+\.\d+$/));
});

test('CLI --help lists commands', (t) => {
  const result = run(['--help']);
  assert.strictEqual(result.code, 0);
  assert.ok(result.stdout.includes('install'));
  assert.ok(result.stdout.includes('check'));
  assert.ok(result.stdout.includes('update'));
  assert.ok(result.stdout.includes('uninstall'));
});

test('install creates symlinks in config dir', (t) => {
  const configDir = freshConfigDir();
  try {
    const result = run(['install', '--config-dir', configDir]);
    assert.strictEqual(result.code, 0, result.stderr);
    assert.ok(existsSync(join(configDir, 'agents')));
    assert.ok(existsSync(join(configDir, 'commands')));
    assert.ok(existsSync(join(configDir, 'team.yaml')));
    assert.ok(existsSync(join(configDir, 'team', 'AGENTS.md')));
    assert.ok(existsSync(join(configDir, 'skills', 'team-memory')));
    assert.ok(readlinkSync(join(configDir, 'agents')).includes('opencode-team'));
    assert.ok(readlinkSync(join(configDir, 'team.yaml')).includes('opencode-team'));
    const manifest = JSON.parse(readFileSync(join(configDir, '.opencode-team-manifest.json'), 'utf-8'));
    assert.ok(manifest.files.length > 0);
  } finally {
    rmSync(configDir, { recursive: true, force: true });
  }
});

test('install with --copy copies files instead of symlinks', (t) => {
  const configDir = freshConfigDir();
  try {
    const result = run(['install', '--config-dir', configDir, '--copy']);
    assert.strictEqual(result.code, 0, result.stderr);
    assert.ok(existsSync(join(configDir, 'team.yaml')));
    // A copied file is not a symlink: readlinkSync throws EINVAL
    let isSymlink = false;
    try {
      readlinkSync(join(configDir, 'team.yaml'));
      isSymlink = true;
    } catch {
      isSymlink = false;
    }
    assert.ok(!isSymlink, 'team.yaml should be a copy, not a symlink');
    assert.ok(readFileSync(join(configDir, 'team.yaml'), 'utf-8').length > 0);
  } finally {
    rmSync(configDir, { recursive: true, force: true });
  }
});

test('check reports installed status', (t) => {
  const configDir = freshConfigDir();
  try {
    run(['install', '--config-dir', configDir]);
    const result = run(['check', '--config-dir', configDir]);
    assert.strictEqual(result.code, 0, result.stderr);
    assert.ok(result.stdout.includes('agents →'));
    assert.ok(result.stdout.includes('team.yaml →'));
  } finally {
    rmSync(configDir, { recursive: true, force: true });
  }
});

test('uninstall removes managed files', (t) => {
  const configDir = freshConfigDir();
  try {
    run(['install', '--config-dir', configDir]);
    const result = run(['uninstall', '--config-dir', configDir]);
    assert.strictEqual(result.code, 0, result.stderr);
    assert.ok(!existsSync(join(configDir, 'team.yaml')));
    assert.ok(!existsSync(join(configDir, 'skills', 'team-memory')));
  } finally {
    rmSync(configDir, { recursive: true, force: true });
  }
});

test('uninstall keeps a real directory that replaced a managed symlink', (t) => {
  const configDir = freshConfigDir();
  try {
    assert.strictEqual(run(['install', '--config-dir', configDir]).code, 0);
    rmSync(join(configDir, 'agents'));
    mkdirSync(join(configDir, 'agents'));
    writeFileSync(join(configDir, 'agents', 'mine.md'), 'mine\n');
    const result = run(['uninstall', '--config-dir', configDir]);
    assert.strictEqual(result.code, 0, result.stderr);
    assert.ok(existsSync(join(configDir, 'agents', 'mine.md')), 'user directory must survive');
  } finally {
    rmSync(configDir, { recursive: true, force: true });
  }
});

test('uninstall keeps a symlink pointing outside the repo', (t) => {
  const configDir = freshConfigDir();
  const userDir = freshConfigDir();
  try {
    assert.strictEqual(run(['install', '--config-dir', configDir]).code, 0);
    writeFileSync(join(userDir, 'keep.txt'), 'keep\n');
    rmSync(join(configDir, 'agents'));
    symlinkSync(userDir, join(configDir, 'agents'));
    const result = run(['uninstall', '--config-dir', configDir]);
    assert.strictEqual(result.code, 0, result.stderr);
    assert.ok(existsSync(join(configDir, 'agents')), 'external symlink must be left untouched');
    assert.ok(existsSync(join(userDir, 'keep.txt')), 'external target must survive');
  } finally {
    rmSync(configDir, { recursive: true, force: true });
    rmSync(userDir, { recursive: true, force: true });
  }
});

test('uninstall removes an unmodified copy install', (t) => {
  const configDir = freshConfigDir();
  try {
    assert.strictEqual(run(['install', '--config-dir', configDir, '--copy']).code, 0);
    const result = run(['uninstall', '--config-dir', configDir]);
    assert.strictEqual(result.code, 0, result.stderr);
    assert.ok(!existsSync(join(configDir, 'team.yaml')));
    assert.ok(!existsSync(join(configDir, 'agents')));
    assert.ok(!existsSync(join(configDir, 'skills', 'team-memory')));
  } finally {
    rmSync(configDir, { recursive: true, force: true });
  }
});

test('uninstall keeps a modified copy', (t) => {
  const configDir = freshConfigDir();
  try {
    assert.strictEqual(run(['install', '--config-dir', configDir, '--copy']).code, 0);
    writeFileSync(join(configDir, 'team.yaml'), 'user content\n');
    const result = run(['uninstall', '--config-dir', configDir]);
    assert.strictEqual(result.code, 0, result.stderr);
    assert.ok(existsSync(join(configDir, 'team.yaml')), 'modified copy must survive');
  } finally {
    rmSync(configDir, { recursive: true, force: true });
  }
});

test('reinstall keeps the manifest so uninstall still removes managed files', (t) => {
  const configDir = freshConfigDir();
  try {
    assert.strictEqual(run(['install', '--config-dir', configDir]).code, 0);
    assert.strictEqual(run(['install', '--config-dir', configDir]).code, 0);
    const manifest = JSON.parse(readFileSync(join(configDir, '.opencode-team-manifest.json'), 'utf-8'));
    assert.ok(manifest.files.length > 0, 'manifest should keep managed files after reinstall');
    const result = run(['uninstall', '--config-dir', configDir]);
    assert.strictEqual(result.code, 0, result.stderr);
    assert.ok(!existsSync(join(configDir, 'team.yaml')));
    assert.ok(!existsSync(join(configDir, 'agents')));
    assert.ok(!existsSync(join(configDir, 'skills', 'team-memory')));
  } finally {
    rmSync(configDir, { recursive: true, force: true });
  }
});

test('install does not clobber non-managed files', (t) => {
  const configDir = freshConfigDir();
  try {
    writeFileSync(join(configDir, 'team.yaml'), 'user content\n');
    const result = run(['install', '--config-dir', configDir]);
    assert.strictEqual(result.code, 0, result.stderr);
    assert.strictEqual(readFileSync(join(configDir, 'team.yaml'), 'utf-8'), 'user content\n');
  } finally {
    rmSync(configDir, { recursive: true, force: true });
  }
});

test('unknown command fails', (t) => {
  const result = run(['bogus']);
  assert.strictEqual(result.code, 1);
});

test('install --config-dir with no value exits non-zero', (t) => {
  const configDir = freshConfigDir();
  try {
    const result = run(['install', '--config-dir'], { OPENCODE_CONFIG_DIR: configDir });
    assert.strictEqual(result.code, 1, `expected exit 1, got ${result.code}: ${result.stderr}`);
    // Default dir must not be touched: it should still be empty
    const entries = readdirSync(configDir);
    assert.strictEqual(entries.length, 0, 'default config dir must not be touched');
  } finally {
    rmSync(configDir, { recursive: true, force: true });
  }
});

test('install exits non-zero when a link/copy fails', (t) => {
  const configDir = freshConfigDir();
  try {
    // Make the skills dir read-only so symlinking into it fails
    mkdirSync(join(configDir, 'skills'), { recursive: true });
    try {
      // chmod 0o555: read+execute, no write
      execSync(`chmod 555 "${configDir}/skills"`);
    } catch {
      // chmod may not be available everywhere; skip the failure assertion if so
    }
    const result = run(['install', '--config-dir', configDir]);
    assert.notStrictEqual(result.code, 0, `expected non-zero exit, got ${result.code}`);
  } finally {
    try { execSync(`chmod 755 "${configDir}/skills"`); } catch {}
    rmSync(configDir, { recursive: true, force: true });
  }
});

test('check snippet reflects the resolved config dir', (t) => {
  const configDir = freshConfigDir();
  try {
    assert.strictEqual(run(['install', '--config-dir', configDir]).code, 0);
    const result = run(['check', '--config-dir', configDir]);
    assert.strictEqual(result.code, 0, result.stderr);
    assert.ok(result.stdout.includes(join(configDir, 'opencode.json')), 'snippet must name the resolved config dir');
    // Printed once: count occurrences of the snippet header line
    const snippetHeader = `Add this to ${join(configDir, 'opencode.json')}:`;
    const count = (result.stdout.match(new RegExp(snippetHeader.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g')) || []).length;
    assert.strictEqual(count, 1, 'snippet must be printed once');
  } finally {
    rmSync(configDir, { recursive: true, force: true });
  }
});

test('uninstall skips a copied file whose hash differs from the manifest', (t) => {
  const configDir = freshConfigDir();
  try {
    assert.strictEqual(run(['install', '--config-dir', configDir, '--copy']).code, 0);
    // Modify a copied file
    writeFileSync(join(configDir, 'team.yaml'), 'user modified content\n');
    const result = run(['uninstall', '--config-dir', configDir]);
    assert.strictEqual(result.code, 0, result.stderr);
    assert.ok(existsSync(join(configDir, 'team.yaml')), 'modified copy must survive uninstall');
    assert.ok(result.stdout.includes('skipped (modified by user)'), 'should warn about modified file');
  } finally {
    rmSync(configDir, { recursive: true, force: true });
  }
});

test('update uses manifest mode so --copy install stays copy after update', (t) => {
  const configDir = freshConfigDir();
  try {
    assert.strictEqual(run(['install', '--config-dir', configDir, '--copy']).code, 0);
    // Verify manifest records copy mode
    const manifest = JSON.parse(readFileSync(join(configDir, '.opencode-team-manifest.json'), 'utf-8'));
    assert.strictEqual(manifest.mode, 'copy', 'manifest should record copy mode');
    // Modify a copied file so we can detect refresh on update
    writeFileSync(join(configDir, 'team.yaml'), 'user modified content\n');
    const result = run(['update', '--config-dir', configDir]);
    // update runs npm install --global which may fail offline; accept either
    // a successful refresh or an npm/network failure, but not a mode-related error.
    if (result.code === 0) {
      assert.ok(readFileSync(join(configDir, 'team.yaml'), 'utf-8').length > 0, 'team.yaml should exist after update');
      const updatedManifest = JSON.parse(readFileSync(join(configDir, '.opencode-team-manifest.json'), 'utf-8'));
      assert.strictEqual(updatedManifest.mode, 'copy', 'manifest mode should remain copy after update');
    } else {
      assert.ok(result.stderr.includes('npm') || result.stderr.includes('Failed to update'), `unexpected update failure: ${result.stderr}`);
    }
  } finally {
    rmSync(configDir, { recursive: true, force: true });
  }
});
