import { test } from 'node:test';
import * as assert from 'node:assert';
import { execSync } from 'node:child_process';
import { mkdtempSync, writeFileSync, readFileSync, existsSync, rmSync, readlinkSync } from 'node:fs';
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
