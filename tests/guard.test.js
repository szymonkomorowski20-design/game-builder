'use strict';

// The game repo's PreToolUse guard: blocks the protected surface, and — just as important —
// does NOT block edits whose content merely mentions protected words.

const test = require('node:test');
const assert = require('node:assert/strict');
const path = require('path');
const { spawnSync } = require('child_process');

const GUARD = path.join(__dirname, '..', 'templates', 'claude', 'hooks', 'guard-protected-paths.sh');

function guard(payload) {
  const r = spawnSync('sh', [GUARD], { input: JSON.stringify(payload), encoding: 'utf8' });
  return { code: r.status, err: r.stderr };
}

const bash = (command) => ({ tool_name: 'Bash', tool_input: { command } });
const write = (file_path, content = 'x') => ({ tool_name: 'Write', tool_input: { file_path, content } });

test('blocks force-push, reset --hard and publishing', () => {
  assert.equal(guard(bash('git push --force origin main')).code, 2);
  assert.equal(guard(bash('git reset --hard HEAD~1')).code, 2);
  assert.equal(guard(bash('butler push build/web user/game:html5')).code, 2);
});

test('allows ordinary commands', () => {
  assert.equal(guard(bash('node tools/gb/gb.js verify')).code, 0);
  assert.equal(guard(bash('git push origin feat/jump')).code, 0);
});

test('blocks writes into .godot/ (posix and Windows paths)', () => {
  assert.equal(guard(write('/home/u/game/.godot/imported/x.ctex')).code, 2);
  assert.equal(guard(write('C:\\Users\\u\\game\\.godot\\editor\\x.cfg')).code, 2);
});

test('blocks hand edits of *.import and implemented specs', () => {
  assert.equal(guard(write('C:\\g\\assets\\hero.png.import')).code, 2);
  assert.equal(guard(write('/g/.ai/specs/implemented/2026-09-01-jump.md')).code, 2);
  assert.equal(guard(write('C:\\g\\.ai\\specs\\implemented\\old.md')).code, 2);
});

test('does NOT block content that merely mentions protected words', () => {
  const doc = 'Never edit .godot/ or *.import; never git push --force; never reset --hard.';
  assert.equal(guard(write('C:\\g\\AGENTS.md', doc)).code, 0);
  assert.equal(guard(write('/g/.ai/specs/2026-09-25-jump.md', doc)).code, 0);
  assert.equal(guard({ tool_name: 'Edit', tool_input: { file_path: '/g/scripts/player.gd', old_string: 'a', new_string: 'reset --hard' } }).code, 0);
});

// ---- PostToolUse check-on-edit ----
const fs = require('fs');
const os = require('os');
const CHECK = path.join(__dirname, '..', 'templates', 'claude', 'hooks', 'check-on-edit.sh');
const haveGodot = spawnSync(process.execPath, [path.join(__dirname, '..', 'tools', 'gb', 'gb.js'), 'godot', '--path', path.join(__dirname, 'fixtures', 'ok')], { encoding: 'utf8' }).status !== 2;

function repoWithGb(fixture) {
  const d = fs.mkdtempSync(path.join(os.tmpdir(), 'gb-coe-'));
  fs.cpSync(path.join(__dirname, 'fixtures', fixture), d, { recursive: true, filter: (s) => !/[\\/]\.(godot|ai)([\\/]|$)/.test(s) });
  fs.mkdirSync(path.join(d, 'tools', 'gb'), { recursive: true });
  for (const f of ['gb.js', 'lint.js', 'check_all.gd']) fs.copyFileSync(path.join(__dirname, '..', 'tools', 'gb', f), path.join(d, 'tools', 'gb', f));
  fs.writeFileSync(path.join(d, 'tools', 'gb', '.gdignore'), ''); // as in every scaffolded repo
  spawnSync('git', ['init', '-q', d]);
  return d;
}

function checkOnEdit(repo, file) {
  const r = spawnSync('sh', [CHECK], { cwd: repo, input: JSON.stringify({ tool_name: 'Edit', tool_input: { file_path: path.join(repo, file) } }), encoding: 'utf8', timeout: 120000 });
  return { code: r.status, err: r.stderr };
}

test('check-on-edit: non-script edits pass without starting the engine', () => {
  const t0 = Date.now();
  assert.equal(checkOnEdit(os.tmpdir(), 'README.md').code, 0);
  assert.ok(Date.now() - t0 < 2000);
});

test('check-on-edit: a broken script edit returns the parse error to the agent (exit 2)', { skip: haveGodot ? false : 'no Godot' }, () => {
  const bad = checkOnEdit(repoWithGb('parse-error'), 'main.gd');
  assert.equal(bad.code, 2);
  assert.match(bad.err, /Cannot assign a value of type/);
  const good = checkOnEdit(repoWithGb('ok'), 'main.gd');
  assert.equal(good.code, 0, good.err);
});

test('does NOT block a script that merely has "import" in its name', () => {
  assert.equal(guard(write('/g/scripts/importer.gd')).code, 0);
  assert.equal(guard(write('/g/scripts/import_helpers.gd')).code, 0);
});
