'use strict';

// Unit tests for tools/gb/gb.js pure logic + integration tests against real Godot fixtures.
// Integration tests are skipped (not failed) when no Godot binary can be found, and say so.

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const gb = require('../tools/gb/gb.js');

const GB = path.join(__dirname, '..', 'tools', 'gb', 'gb.js');
const FIX = path.join(__dirname, 'fixtures');

test('projectEngineVersion reads major.minor from config/features', () => {
  assert.equal(gb.projectEngineVersion('config/features=PackedStringArray("4.7", "Forward Plus")'), '4.7');
  assert.equal(gb.projectEngineVersion('config/features=PackedStringArray("Mobile", "4.3")'), '4.3');
  assert.equal(gb.projectEngineVersion('[application]\nconfig/name="x"'), null);
});

test('projectMainScene reads run/main_scene', () => {
  assert.equal(gb.projectMainScene('run/main_scene="res://scenes/main.tscn"'), 'res://scenes/main.tscn');
  assert.equal(gb.projectMainScene(''), null);
});

test('parseGodotVersion handles official and custom builds', () => {
  assert.deepEqual(gb.parseGodotVersion('4.7.2.stable.official.ed1daf0bf'), { full: '4.7.2.stable.official.ed1daf0bf', majorMinor: '4.7' });
  assert.equal(gb.parseGodotVersion('4.3.stable.mono.official.77dcf97d8').majorMinor, '4.3');
  assert.equal(gb.parseGodotVersion('not godot'), null);
});

test('parseLog: runtime SCRIPT ERROR is an error with its location', () => {
  const log = "Godot Engine v4.7.2\n\nSCRIPT ERROR: Out of bounds get index '3' (on base: 'Array')\n   at: _ready (res://main.gd:6)\n";
  const r = gb.parseLog(log);
  assert.equal(r.errors.length, 1);
  assert.equal(r.errors[0].kind, 'SCRIPT ERROR');
  assert.equal(r.errors[0].at, '_ready (res://main.gd:6)');
});

test('parseLog: ANSI colours are stripped and warnings are not errors', () => {
  const r = gb.parseLog('\x1b[91mERROR: boom\x1b[0m\nWARNING: careful\n');
  assert.equal(r.errors.length, 1);
  assert.equal(r.warnings.length, 1);
});

test('parseLog: engine exit noise is ignored by default, extra ignores apply', () => {
  const r = gb.parseLog('ERROR: 3 resources still in use at exit.\nERROR: flaky driver thing\n', [/flaky driver/]);
  assert.equal(r.errors.length, 0);
});

test('candidateBinaries: GODOT_BIN wins, console builds rank first, newer first', () => {
  const listDir = (d) => (d.endsWith('Desktop') ? ['Godot_v4.3-stable_win64.exe', 'Godot_v4.7.2-stable_win64.exe', 'Godot_v4.7.2-stable_win64_console.exe', 'notes.txt'] : []);
  const c = gb.candidateBinaries({ env: { GODOT_BIN: 'C:\\x\\godot.exe', PATH: '' }, platform: 'win32', home: 'C:\\Users\\u', listDir });
  assert.equal(c[0], 'C:\\x\\godot.exe');
  const scanned = c.filter((p) => /Desktop/.test(p)).map((p) => path.basename(p));
  assert.deepEqual(scanned, ['Godot_v4.7.2-stable_win64_console.exe', 'Godot_v4.7.2-stable_win64.exe', 'Godot_v4.3-stable_win64.exe']);
});

function wav16(samples) {
  const data = Buffer.alloc(samples.length * 2);
  samples.forEach((s, i) => data.writeInt16LE(s, i * 2));
  const h = Buffer.alloc(44);
  h.write('RIFF', 0); h.writeUInt32LE(36 + data.length, 4); h.write('WAVE', 8);
  h.write('fmt ', 12); h.writeUInt32LE(16, 16); h.writeUInt16LE(1, 20); h.writeUInt16LE(1, 22);
  h.writeUInt32LE(44100, 24); h.writeUInt32LE(88200, 28); h.writeUInt16LE(2, 32); h.writeUInt16LE(16, 34);
  h.write('data', 36); h.writeUInt32LE(data.length, 40);
  return Buffer.concat([h, data]);
}

test('kbVersionNote: warns when kb results quote the master Godot docs next to the pinned 4.7 copy', () => {
  const master = 'Plik lokalny: zrodla/godotengine--godot-docs/tutorials/export/exporting_for_android.rst — linie 1–10';
  const pinned = 'Plik lokalny: fala-05/zrodla/godotengine--godot-docs-4.7/tutorials/export/exporting_for_android.rst';
  assert.match(gb.kbVersionNote(`${pinned}\n${master}`), /master.*4\.8-dev.*godot-docs-4\.7/s);
  assert.equal(gb.kbVersionNote(pinned), '');
  assert.equal(gb.kbVersionNote('## Some asset pack\nPlik lokalny: assety/fala-01/tiny-dungeon'), '');
});

test('wavPeakDb: silence is -Infinity, half scale is about -6 dBFS, non-WAV is null', () => {
  const d = fs.mkdtempSync(path.join(os.tmpdir(), 'gb-wav-'));
  fs.writeFileSync(path.join(d, 'silent.wav'), wav16(new Array(100).fill(0)));
  fs.writeFileSync(path.join(d, 'half.wav'), wav16([0, 16384, -16384, 8000]));
  fs.writeFileSync(path.join(d, 'x.wav'), 'not a wav');
  assert.equal(gb.wavPeakDb(path.join(d, 'silent.wav')), -Infinity);
  assert.ok(Math.abs(gb.wavPeakDb(path.join(d, 'half.wav')) + 6.02) < 0.05);
  assert.equal(gb.wavPeakDb(path.join(d, 'x.wav')), null);
  assert.equal(gb.wavPeakDb(path.join(d, 'missing.wav')), null);
});

test('detectTestFramework finds GUT and gdUnit4', () => {
  const d = fs.mkdtempSync(path.join(os.tmpdir(), 'gb-'));
  assert.equal(gb.detectTestFramework(d), null);
  fs.mkdirSync(path.join(d, 'addons', 'gut'), { recursive: true });
  fs.writeFileSync(path.join(d, 'addons', 'gut', 'gut_cmdln.gd'), '');
  assert.equal(gb.detectTestFramework(d), 'gut');
});

// ---- integration (real engine) ----

function haveGodot() {
  const r = spawnSync(process.execPath, [GB, 'godot', '--path', path.join(FIX, 'ok')], { encoding: 'utf8' });
  return r.status !== 2; // 2 = binary not found / usage error
}
const HAVE = haveGodot();
const skip = HAVE ? false : 'no Godot binary found (set GODOT_BIN) — integration tests skipped';

function verify(fixture) {
  const r = spawnSync(process.execPath, [GB, 'verify', '--json', '--frames', '20', '--path', path.join(FIX, fixture)], { encoding: 'utf8', timeout: 600000 });
  return { code: r.status, report: JSON.parse(r.stdout) };
}

test('verify: a healthy project passes every step', { skip }, () => {
  const { code, report } = verify('ok');
  assert.equal(code, 0);
  assert.equal(report.result, 'PASS');
  assert.deepEqual(report.steps.map((s) => s.step), ['import', 'check', 'lint', 'run', 'test', 'scenarios', 'replays']);
  assert.deepEqual(report.steps.filter((s) => s.status === 'skip').map((s) => s.step), ['test', 'scenarios', 'replays'], 'uncovered steps are SKIP, never PASS');
  assert.equal(report.steps.find((s) => s.step === 'check').failedScripts.length, 0);
});

test('verify: a parse error fails and names the broken script', { skip }, () => {
  const { code, report } = verify('parse-error');
  assert.equal(code, 1);
  assert.equal(report.result, 'FAIL');
  const check = report.steps.find((s) => s.step === 'check');
  assert.ok(check, 'check step still runs after an import that surfaced script errors');
  assert.deepEqual(check.failedScripts, ['res://main.gd']);
});

test('verify: a runtime error fails even though Godot exits 0', { skip }, () => {
  const { code, report } = verify('runtime-error');
  assert.equal(code, 1);
  const run = report.steps.find((s) => s.step === 'run');
  assert.equal(run.status, 'fail');
  assert.match(run.errors[0].message, /Out of bounds/);
  assert.match(run.errors[0].at, /main\.gd:6/);
});
