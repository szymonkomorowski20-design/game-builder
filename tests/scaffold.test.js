'use strict';

// gb scaffold / doctor: generated content, the never-overwrite rule, adopt mode, and one full
// end-to-end bootstrap against the real engine (skipped, not failed, without Godot).

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const sc = require('../tools/gb/scaffold.js');

const GB = path.join(__dirname, '..', 'tools', 'gb', 'gb.js');
const opts = (over = []) => sc.parseScaffoldArgs(['--dir', tmp(), '--name', 'T', '--engine', '4.7', ...over]);
function tmp() {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'gb-sc-'));
}

test('defaults: 2D → Compatibility renderer, 1280×720; 3D → Forward+', () => {
  const o2 = opts();
  assert.equal(o2.renderer, 'gl_compatibility');
  assert.equal(o2.width, 1280);
  const o3 = sc.parseScaffoldArgs(['--dim', '3d']);
  assert.equal(o3.renderer, 'forward_plus');
});

test('pixel art: low base resolution, viewport stretch, nearest filter, pixel snap, window ×4', () => {
  const pg = sc.projectGodot(sc.parseScaffoldArgs(['--pixel-art', '--name', 'P', '--engine', '4.7']));
  assert.match(pg, /viewport_width=320/);
  assert.match(pg, /window\/stretch\/mode="viewport"/);
  assert.match(pg, /default_texture_filter=0/);
  assert.match(pg, /snap_2d_transforms_to_pixel=true/);
  assert.match(pg, /window_width_override=1280/);
  assert.match(pg, /config\/features=PackedStringArray\("4\.7", "GL Compatibility"\)/);
});

test('invalid options are rejected with a clear message', () => {
  assert.throws(() => sc.parseScaffoldArgs(['--dim', '4d']), /2d or 3d/);
  assert.throws(() => sc.parseScaffoldArgs(['--renderer', 'vulkan']), /renderer must be/);
  assert.throws(() => sc.parseScaffoldArgs(['--tests', 'jest']), /tests must be/);
});

test('never overwrites: an existing file is KEPT byte-for-byte', () => {
  const o = opts();
  fs.writeFileSync(path.join(o.dir, 'AGENTS.md'), 'MINE');
  const report = sc.scaffold(o);
  assert.ok(report.includes('KEPT    AGENTS.md'));
  assert.equal(fs.readFileSync(path.join(o.dir, 'AGENTS.md'), 'utf8'), 'MINE');
  assert.ok(report.includes('CREATED project.godot'));
});

test('stamps AGENTS.md with the plugin version and fills every placeholder', () => {
  const o = opts();
  sc.scaffold(o);
  const agents = fs.readFileSync(path.join(o.dir, 'AGENTS.md'), 'utf8');
  const version = fs.readFileSync(path.join(__dirname, '..', 'VERSION'), 'utf8').trim();
  assert.match(agents, new RegExp(`Game-Builder-Version: ${version.replace(/\./g, '\\.')}`));
  assert.doesNotMatch(agents, /\{\{[A-Z_]+\}\}/);
  assert.match(agents, /SPEC → HUMAN → VERIFIED → PLAYABLE → GATED/);
});

test('the spine in AGENTS.md template is byte-identical to the session router', () => {
  const router = fs.readFileSync(path.join(__dirname, '..', 'hooks', 'workflow-router.js'), 'utf8');
  const tpl = fs.readFileSync(path.join(__dirname, '..', 'templates', 'repo', 'AGENTS.md.tmpl'), 'utf8');
  const spine = /const SPINE = '([^']+)'/.exec(router)[1];
  assert.ok(tpl.includes(spine));
});

test('generated .claude/settings.json is valid JSON and disables Sailes for the game repo', () => {
  const o = opts();
  sc.scaffold(o);
  const s = JSON.parse(fs.readFileSync(path.join(o.dir, '.claude', 'settings.json'), 'utf8'));
  assert.equal(s.enabledPlugins['sailes-app-builder@sailes'], false);
  assert.ok(s.permissions.allow.includes('Bash(node tools/gb/gb.js:*)'));
});

test('the repo copy of gb carries no scaffold (plugin-only)', () => {
  const o = opts();
  sc.scaffold(o);
  assert.ok(fs.existsSync(path.join(o.dir, 'tools', 'gb', 'gb.js')));
  assert.ok(!fs.existsSync(path.join(o.dir, 'tools', 'gb', 'scaffold.js')));
  assert.ok(fs.existsSync(path.join(o.dir, 'tools', 'gb', '.gdignore')));
});

test('adopt mode never generates game files', () => {
  const o = opts(['--adopt']);
  fs.writeFileSync(path.join(o.dir, 'project.godot'), 'config_version=5\n');
  const report = sc.scaffold(o);
  assert.ok(!report.some((l) => /scenes\/main\.tscn|scripts\/main\.gd|autoload\/events\.gd/.test(l)));
  assert.ok(report.includes('CREATED AGENTS.md'));
  assert.equal(fs.readFileSync(path.join(o.dir, 'project.godot'), 'utf8'), 'config_version=5\n');
});

// ---- end-to-end with the real engine ----
const haveGodot = spawnSync(process.execPath, [GB, 'godot', '--path', path.join(__dirname, 'fixtures', 'ok')], { encoding: 'utf8' }).status !== 2;
const skip = haveGodot ? false : 'no Godot binary found — e2e skipped';

test('e2e: scaffold → brief → git commit → doctor DONE → verify PASS', { skip, timeout: 900000 }, () => {
  const dir = path.join(tmp(), 'game');
  const run = (args, cwd = dir) => spawnSync(process.execPath, [GB, ...args], { cwd, encoding: 'utf8', timeout: 600000 });
  const s = run(['scaffold', '--dir', dir, '--name', 'E2E', '--dim', '2d', '--pixel-art'], os.tmpdir());
  assert.equal(s.status, 0, s.stdout + s.stderr);
  assert.match(s.stdout, /INPUT {3}7 default action/);

  let d = run(['doctor']);
  assert.equal(d.status, 1, 'doctor must not pass before the brief and the first commit');
  assert.match(d.stdout, /MISS \.ai\/brief\.md/);

  fs.writeFileSync(path.join(dir, '.ai', 'brief.md'), '# Game Brief: E2E\n\n## Decisions Ledger\n| Decision | Chosen | By |\n|---|---|---|\n| Dimension | 2D | user |\n');
  const git = (...a) => spawnSync('git', ['-C', dir, '-c', 'user.name=t', '-c', 'user.email=t@t', ...a], { encoding: 'utf8' });
  git('init', '-q');
  git('add', '-A');
  assert.equal(git('commit', '-q', '-m', 'chore: bootstrap').status, 0);

  const v = run(['verify', '--frames', '30']);
  assert.equal(v.status, 0, v.stdout);
  assert.match(v.stdout, /^PASS — /m);
  d = run(['doctor']);
  assert.equal(d.status, 0, d.stdout);
  assert.match(d.stdout, /DONE — no MISS lines/);
});
