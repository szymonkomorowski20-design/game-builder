'use strict';

// Behavioural tests for the SessionStart hooks: build a repo on disk, run the hook with the
// harness's stdin JSON, assert on what it injects (or that it stays silent).

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const ROOT = path.join(__dirname, '..');
const ROUTER = path.join(ROOT, 'hooks', 'workflow-router.js');
const VERSION_CHECK = path.join(ROOT, 'hooks', 'framework-version-check.js');

function repo(files) {
  const d = fs.mkdtempSync(path.join(os.tmpdir(), 'gb-hook-'));
  fs.mkdirSync(path.join(d, '.git'));
  for (const [f, body] of Object.entries(files)) {
    fs.mkdirSync(path.dirname(path.join(d, f)), { recursive: true });
    fs.writeFileSync(path.join(d, f), body);
  }
  return d;
}

function run(script, cwd, env = {}) {
  const r = spawnSync(process.execPath, [script], { input: JSON.stringify({ cwd }), encoding: 'utf8', env: { ...process.env, ...env } });
  assert.equal(r.status, 0, r.stderr);
  if (!r.stdout.trim()) return null;
  return JSON.parse(r.stdout).hookSpecificOutput.additionalContext;
}

const STAMPED = '# Agents Guidelines\n> Game-Builder-Version: 0.1.0\n';

test('router: silent outside any game or workflow repo', () => {
  assert.equal(run(ROUTER, repo({ 'README.md': 'x' })), null);
});

test('router: silent in a Sailes web repo (AGENTS.md without our stamp, no project.godot)', () => {
  assert.equal(run(ROUTER, repo({ 'AGENTS.md': '# Agents\n> Framework-Version: 1.28.2\n', '.ai/specs/x.md': '' })), null);
});

test('router: an unadopted Godot project gets one adoption offer, nothing more', () => {
  const out = run(ROUTER, repo({ 'project.godot': 'config_version=5' }));
  assert.match(out, /has not adopted/);
  assert.match(out, /Route C/);
  assert.doesNotMatch(out, /HARD RULES/);
});

test('router: adopted repo with no spec routes to game-start and states the spine', () => {
  const out = run(ROUTER, repo({ 'AGENTS.md': STAMPED, 'project.godot': '' }));
  assert.match(out, /No active spec/);
  assert.match(out, /game-start/);
  assert.match(out, /SPEC → HUMAN → VERIFIED → PLAYABLE → GATED/);
  assert.match(out, /takes precedence over any web-app workflow/);
});

test('router: process weight comes from AGENTS.md; light changes the pipeline, never the spine', () => {
  const std = run(ROUTER, repo({ 'AGENTS.md': STAMPED, 'project.godot': '' }));
  assert.match(std, /PROCESS: standard/);
  assert.match(std, /game-checker \+ game-playtester at each phase gate/);
  const light = run(ROUTER, repo({ 'AGENTS.md': STAMPED + '- Process: light (chosen 2026-09-27)\n', 'project.godot': '' }));
  assert.match(light, /PROCESS: light/);
  assert.match(light, /docs[\\/]rigor\.md/);
  assert.doesNotMatch(light, /game-playtester/, 'light: the implementer writes the Run result itself');
  assert.match(light, /game-checker once per spec/);
  assert.match(light, /SPEC → HUMAN → VERIFIED → PLAYABLE → GATED/, 'the spine never relaxes');
  const odd = run(ROUTER, repo({ 'AGENTS.md': STAMPED + '- Process: turbo\n', 'project.godot': '' }));
  assert.match(odd, /PROCESS: standard/);
  assert.match(odd, /unknown process "turbo"/);
});

test('router: specs in flight are named; implemented/ and README are not', () => {
  const out = run(ROUTER, repo({ 'AGENTS.md': STAMPED, '.ai/specs/2026-09-25-jump.md': '', '.ai/specs/README.md': '', '.ai/specs/implemented/old.md': '' }));
  assert.match(out, /2026-09-25-jump\.md/);
  assert.doesNotMatch(out, /README\.md`/);
  assert.doesNotMatch(out, /old\.md/);
});

test('router: a failing verify report is surfaced with the failing steps', () => {
  const report = { result: 'FAIL', at: '2026-09-25T10:00:00Z', godotVersion: '4.7.2', steps: [{ step: 'import', status: 'ok' }, { step: 'run', status: 'fail' }] };
  const out = run(ROUTER, repo({ 'AGENTS.md': STAMPED, '.ai/verify/last.json': JSON.stringify(report) }));
  assert.match(out, /\*\*FAIL\*\*/);
  assert.match(out, /failing step\(s\): run/);
});

test('router: open incidents are listed, closed ones are not', () => {
  const out = run(ROUTER, repo({ 'AGENTS.md': STAMPED, '.ai/incidents/2026-09-20-crash.md': 'Status: OPEN\n', '.ai/incidents/2026-09-01-old.md': 'Status: FIXED\n' }));
  assert.match(out, /2026-09-20-crash\.md/);
  assert.doesNotMatch(out, /2026-09-01-old/);
});

function plugin(version, changelog) {
  return repo({ VERSION: version + '\n', 'CHANGELOG.md': changelog });
}

test('version check: silent when stamp matches the plugin', () => {
  assert.equal(run(VERSION_CHECK, repo({ 'AGENTS.md': STAMPED }), { CLAUDE_PLUGIN_ROOT: plugin('0.1.0', '') }), null);
});

test('version check: silent in repos without our stamp', () => {
  assert.equal(run(VERSION_CHECK, repo({ 'AGENTS.md': '> Framework-Version: 1.0.0' }), { CLAUDE_PLUGIN_ROOT: plugin('0.2.0', '') }), null);
});

test('version check: behind → names the changelog delta and offers, never forces', () => {
  const pr = plugin('0.3.0', '## 0.3.0 — 2026-10-01 · playtest gate\n## 0.2.0 — 2026-09-30 · verification layer\n## 0.1.0 — 2026-09-25 · foundation\n');
  const out = run(VERSION_CHECK, repo({ 'AGENTS.md': STAMPED }), { CLAUDE_PLUGIN_ROOT: pr });
  assert.match(out, /0\.2\.0 — 2026-09-30/);
  assert.match(out, /0\.3\.0 — 2026-10-01/);
  assert.doesNotMatch(out, /0\.1\.0 — 2026-09-25/);
  assert.match(out, /OFFER/);
});

test('version check: repo ahead of plugin → update the plugin', () => {
  const out = run(VERSION_CHECK, repo({ 'AGENTS.md': '> Game-Builder-Version: 9.0.0' }), { CLAUDE_PLUGIN_ROOT: plugin('0.1.0', '') });
  assert.match(out, /plugin is behind the repo/);
});
