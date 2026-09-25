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

test('does NOT block a script that merely has "import" in its name', () => {
  assert.equal(guard(write('/g/scripts/importer.gd')).code, 0);
  assert.equal(guard(write('/g/scripts/import_helpers.gd')).code, 0);
});
