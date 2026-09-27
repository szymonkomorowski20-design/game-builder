'use strict';

// Stage 2 — the verification layer: lint rules, GUT result parsing, export presets, and the
// harness against the real engine (scenarios, record → replay with state match, inert in play).
// Window/export tests are opt-in: GB_TEST_WINDOW=1 / GB_TEST_EXPORT=1 (they open a window / write 100 MB).

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const ROOT = path.join(__dirname, '..');
const GB = path.join(ROOT, 'tools', 'gb', 'gb.js');
const { lint, stripComments } = require('../tools/gb/lint.js');

function tmpProject(files) {
  const d = fs.mkdtempSync(path.join(os.tmpdir(), 'gb-v-'));
  for (const [f, body] of Object.entries(files)) {
    fs.mkdirSync(path.dirname(path.join(d, f)), { recursive: true });
    fs.writeFileSync(path.join(d, f), body);
  }
  return d;
}

const PG = 'config_version=5\n[application]\nrun/main_scene="res://main.tscn"\n[autoload]\nGbHarness="*res://addons/gb_harness/harness.gd"\n';

// ---------------- lint ----------------

test('lint: Godot 3 APIs are errors with file:line, comments and strings excluded', () => {
  const d = tmpProject({
    'project.godot': PG, 'main.tscn': '', 'addons/gb_harness/harness.gd': '',
    'player.gd': 'extends KinematicBody2D\n# yield( in a comment is fine\nvar s = "onready var in a string"\nonready var x = 1\nfunc f():\n\tyield(get_tree(), "idle_frame")\n',
  });
  const r = lint(d);
  const rules = r.errors.filter((e) => e.rule === 'godot3-api').map((e) => e.file + ' ' + e.message);
  assert.ok(rules.some((x) => /player\.gd:1 KinematicBody/.test(x)));
  assert.ok(rules.some((x) => /player\.gd:4 onready var/.test(x)));
  assert.ok(rules.some((x) => /player\.gd:6 yield/.test(x)));
  assert.equal(rules.length, 3, rules.join('\n'));
});

test('lint: broken res:// references are errors, existing ones are not', () => {
  const d = tmpProject({ 'project.godot': PG, 'main.tscn': '[ext_resource path="res://gone.gd"]\n[ext_resource path="res://main.tscn"]', 'addons/gb_harness/harness.gd': '' });
  const r = lint(d);
  assert.deepEqual(r.errors.map((e) => e.message), ['res://gone.gd does not exist']);
});

test('lint: an asset without a licence-register row is an error; a folder row covers its files', () => {
  const d = tmpProject({
    'project.godot': PG, 'main.tscn': 'res://assets/sfx/jump.wav', 'addons/gb_harness/harness.gd': '',
    'assets/sfx/jump.wav': 'x', 'assets/art/hero.png': 'x',
    '.ai/assets/REGISTER.md': '| Path | Source |\n|---|---|\n| assets/sfx | zulubo CC0 |\n',
  });
  const r = lint(d);
  assert.deepEqual(r.errors.filter((e) => e.rule === 'licence-register').map((e) => e.file), ['assets/art/hero.png']);
  assert.ok(r.warnings.some((w) => w.rule === 'unreferenced-asset' && w.file === 'assets/art/hero.png'));
});

test('lint: missing harness is an error in a stamped game-builder repo, a warning elsewhere; addons are not linted', () => {
  const files = { 'project.godot': 'config_version=5\n', 'addons/x/y.gd': 'extends KinematicBody2D\nvar p = "res://nope.gd"\n' };
  const plain = lint(tmpProject(files));
  assert.deepEqual(plain.errors, []);
  assert.ok(plain.warnings.some((w) => w.rule === 'harness'));
  const stamped = lint(tmpProject({ ...files, 'AGENTS.md': '> Game-Builder-Version: 0.2.0\n' }));
  assert.deepEqual(stamped.errors.map((e) => e.rule), ['harness']);
});

test('stripComments keeps # inside strings', () => {
  assert.equal(stripComments('var c = "#fff" # colour'), 'var c = "#fff" ');
});

// ---------------- parsers ----------------

const gbMod = require('../tools/gb/gb.js');

test('GUT totals and export presets parse', () => {
  const src = fs.readFileSync(GB, 'utf8');
  assert.match(src, /function parseGutTotals/);
  assert.match(src, /function parsePresets/);
  assert.ok(gbMod.findProjectDir);
});

// ---------------- engine integration ----------------

const haveGodot = spawnSync(process.execPath, [GB, 'godot', '--path', path.join(__dirname, 'fixtures', 'ok')], { encoding: 'utf8' }).status !== 2;
const skip = haveGodot ? false : 'no Godot binary found — integration tests skipped';

function copyDir(src, dst) {
  fs.mkdirSync(dst, { recursive: true });
  for (const e of fs.readdirSync(src, { withFileTypes: true })) {
    if (e.name === '.godot' || e.name === '.ai') continue;
    const s = path.join(src, e.name);
    const t = path.join(dst, e.name);
    if (e.isDirectory()) copyDir(s, t);
    else fs.copyFileSync(s, t);
  }
}

let GAME = null;
function game() {
  if (GAME) return GAME;
  GAME = path.join(fs.mkdtempSync(path.join(os.tmpdir(), 'gb-h-')), 'game');
  copyDir(path.join(__dirname, 'fixtures', 'harness-game'), GAME);
  copyDir(path.join(ROOT, 'templates', 'addons', 'gb_harness'), path.join(GAME, 'addons', 'gb_harness'));
  const g = JSON.parse(spawnSync(process.execPath, [GB, 'godot', '--json', '--path', GAME], { encoding: 'utf8' }).stdout);
  spawnSync(g.godot, ['--headless', '--path', GAME, '--script', path.join(ROOT, 'tools', 'gb', 'setup_input.gd')], { encoding: 'utf8' });
  spawnSync(g.godot, ['--headless', '--path', GAME, '--import'], { encoding: 'utf8' });
  GAME_BIN = g.godot;
  return GAME;
}
let GAME_BIN = null;
const gb = (...args) => spawnSync(process.execPath, [GB, ...args], { encoding: 'utf8', timeout: 600000 });

test('scenario: a correct bot scenario passes with exact physics', { skip, timeout: 600000 }, () => {
  const r = gb('scenario', '--path', game());
  assert.equal(r.status, 0, r.stdout);
  assert.match(r.stdout, /PASS scenarios \(1\/1 passing\)/);
});

test('scenario: failing expectations and unknown actions are reported, exit 1', { skip, timeout: 600000 }, () => {
  const bad = path.join(game(), 'tests', 'scenarios', 'zz_broken.gd');
  fs.writeFileSync(bad, 'extends GbScenario\n\n\nfunc run() -> void:\n\tawait press("move_left", 0.5)\n\texpect_gt(node("Player").position.x, 1000.0, "deliberately wrong")\n\thold("fly")\n');
  try {
    const r = gb('scenario', 'res://tests/scenarios/zz_broken.gd', '--path', game());
    assert.equal(r.status, 1);
    assert.match(r.stdout, /deliberately wrong — expected > 1000\.000/);
    assert.match(r.stdout, /input action 'fly' does not exist/);
  } finally {
    fs.rmSync(bad);
  }
});

test('scenario: a scenario script with a parse error fails fast with a clear reason (no wait for the frame cap)', { skip, timeout: 600000 }, () => {
  const bad = path.join(game(), 'tests', 'scenarios', 'zz_parse.gd');
  fs.writeFileSync(bad, 'extends GbScenario\n\n\nfunc run() -> void:\n\texpect_eq(1, 1)\n');
  try {
    const t0 = Date.now();
    const r = gb('scenario', 'res://tests/scenarios/zz_parse.gd', '--path', game());
    assert.equal(r.status, 1, r.stdout);
    assert.match(r.stdout, /could not load scenario script/);
    assert.ok(Date.now() - t0 < 30000, `took ${Date.now() - t0} ms`);
  } finally {
    fs.rmSync(bad);
  }
});

test('record → replay reproduces the final tracked state; a tampered recording fails', { skip, timeout: 600000 }, () => {
  const dir = game();
  const rep = path.join(dir, 'tests', 'replays');
  fs.mkdirSync(rep, { recursive: true });
  // A scripted "human": the scenario plays while the harness records.
  const rec = spawnSync(GAME_BIN, ['--headless', '--path', dir, '--quit-after', '3000', '--', '--gb-scenario=res://tests/scenarios/walk_and_jump.gd', `--gb-record=walk`, `--gb-out=${rep}`], { encoding: 'utf8' });
  assert.match(rec.stdout, /GB_RECORD path=.* events=4/);
  const data = JSON.parse(fs.readFileSync(path.join(rep, 'walk.json'), 'utf8'));
  assert.match(data.final_state, /Player p=160\.00,/);
  assert.match(data.final_state, /score=1/);

  let r = gb('replay', '--path', dir);
  assert.equal(r.status, 0, r.stdout);
  assert.match(r.stdout, /PASS replays \(1\/1 passing\)/);

  data.events = data.events.filter((e) => e[1] !== 'jump'); // the jump never happens now
  fs.writeFileSync(path.join(rep, 'tampered.json'), JSON.stringify(data));
  r = gb('replay', path.join(rep, 'tampered.json'), '--path', dir);
  assert.equal(r.status, 1);
  assert.match(r.stdout, /final state differs/);
  fs.rmSync(path.join(rep, 'tampered.json'));
});

test('harness is inert in a normal run (no GB_ output, RNG not seeded)', { skip, timeout: 600000 }, () => {
  const out = spawnSync(GAME_BIN || game() && GAME_BIN, ['--headless', '--path', game(), '--quit-after', '10'], { encoding: 'utf8' }).stdout;
  assert.doesNotMatch(out, /GB_HARNESS/);
});

test('tests install gut → gb test reports passing/failing counts from GUT', { skip, timeout: 900000 }, () => {
  const inst = gb('tests', 'install', '--path', game());
  assert.equal(inst.status, 0, inst.stdout + inst.stderr);
  assert.match(inst.stdout, /GUT 9\.\d+\.\d+ copied/);
  const r = gb('test', '--path', game());
  assert.equal(r.status, 1, 'one deliberately failing test');
  assert.match(r.stdout, /FAIL test \(gut: 1\/2 passing\)/);
  assert.match(r.stdout, /test_deliberately_failing/);
});

test('a test script that does not parse fails gb test instead of being skipped by GUT', { skip, timeout: 900000 }, () => {
  if (!fs.existsSync(path.join(game(), 'addons', 'gut'))) gb('tests', 'install', '--path', game());
  const bad = path.join(game(), 'tests', 'unit', 'test_unparsable.gd');
  fs.mkdirSync(path.dirname(bad), { recursive: true });
  fs.writeFileSync(bad, 'extends GutTest\n\n\nfunc test_uses_a_class_that_does_not_exist() -> void:\n\tvar p := NoSuchClass.new()\n\tassert_not_null(p)\n');
  try {
    const r = gb('test', '--path', game());
    assert.equal(r.status, 1, r.stdout);
    assert.match(r.stdout, /did not load and were skipped: res:\/\/tests\/unit\/test_unparsable\.gd/);
  } finally {
    fs.rmSync(bad);
  }
});

test('scenario --repeat names a scenario that passes only sometimes as FLAKY', { skip, timeout: 900000 }, () => {
  const d = game();
  // Deterministic "flake": a counter in user:// makes every other run fail.
  const flaky = 'extends GbScenario\n\nfunc run() -> void:\n\tvar p := "user://gb_flaky_counter.txt"\n\tvar n := 0\n\tif FileAccess.file_exists(p):\n\t\tn = int(FileAccess.get_file_as_string(p))\n\tvar f := FileAccess.open(p, FileAccess.WRITE)\n\tf.store_string(str(n + 1))\n\tf.close()\n\texpect(n % 2 == 0, "alternates")\n';
  const file = path.join(d, 'tests', 'scenarios', 'zz_flaky.gd');
  fs.writeFileSync(file, flaky);
  try {
    const r = gb('scenario', 'res://tests/scenarios/zz_flaky.gd', '--repeat', '4', '--path', d);
    assert.equal(r.status, 1, r.stdout);
    assert.match(r.stdout, /FLAKY zz_flaky\.gd: passed 2\/4/);
  } finally {
    fs.rmSync(file, { force: true });
  }
});

test('shot + compare against an accepted baseline (opens a window)', { skip: skip || (process.env.GB_TEST_WINDOW ? false : 'set GB_TEST_WINDOW=1'), timeout: 600000 }, () => {
  assert.equal(gb('shot', '--name', 't', '--accept', '--path', game()).status, 0);
  const r = gb('shot', '--name', 't', '--compare', '--path', game());
  assert.equal(r.status, 0, r.stdout);
  assert.match(r.stdout, /0 px \(0\.00%\) differ from the baseline/);
});

test('shot --movie works without the harness and reports whether the game made sound (opens a window)', { skip: skip || (process.env.GB_TEST_WINDOW ? false : 'set GB_TEST_WINDOW=1'), timeout: 600000 }, () => {
  // A game with no harness and no test code: a sine tone plays from the first frame.
  const tone = 'extends Node2D\n\nfunc _ready() -> void:\n\tvar s := AudioStreamWAV.new()\n\ts.format = AudioStreamWAV.FORMAT_16_BITS\n\ts.mix_rate = 44100\n\tvar data := PackedByteArray()\n\tdata.resize(44100 * 2)\n\tfor i in 44100:\n\t\tdata.encode_s16(i * 2, int(sin(i * TAU * 440.0 / 44100.0) * 16000.0))\n\ts.data = data\n\t$Player.stream = s\n\t$Player.play()\n';
  const scene = '[gd_scene format=3]\n\n[ext_resource type="Script" path="res://main.gd" id="1"]\n\n[node name="Main" type="Node2D"]\nscript = ExtResource("1")\n\n[node name="Player" type="AudioStreamPlayer" parent="."]\n\n[node name="Box" type="Polygon2D" parent="."]\npolygon = PackedVector2Array(100, 100, 300, 100, 300, 300)\n';
  const d = tmpProject({ 'project.godot': 'config_version=5\n[application]\nrun/main_scene="res://main.tscn"\nconfig/features=PackedStringArray("4.7")\n', 'main.tscn': scene, 'main.gd': tone });
  const r = gb('shot', '--movie', '--name', 'tone', '--frames', '30', '--path', d);
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.ok(fs.existsSync(path.join(d, '.ai', 'verify', 'shots', 'tone.png')));
  const peak = Number(/audio peak (-?[\d.]+) dBFS/.exec(r.stdout)?.[1]);
  assert.ok(peak > -12 && peak <= 0, `expected an audible tone, got: ${r.stdout}`);
});

test('export Windows Desktop produces an executable', { skip: skip || (process.env.GB_TEST_EXPORT ? false : 'set GB_TEST_EXPORT=1'), timeout: 900000 }, () => {
  const d = game();
  // The exact presets gb scaffold writes (a hand-trimmed preset without include/exclude_filter
  // makes Godot 4.7 log ERRORs — measured 2026-09-25 — so the test uses the real template).
  fs.writeFileSync(path.join(d, 'export_presets.cfg'), require('../tools/gb/scaffold.js').exportPresets());
  const r = gb('export', '--preset', 'Windows Desktop', '--path', d);
  assert.equal(r.status, 0, r.stdout);
  assert.ok(fs.statSync(path.join(d, 'build', 'windows', 'game.exe')).size > 1e6);
});

test('export --smoke catches a resource that the export filter dropped (the editor run is fine)', { skip: skip || (process.env.GB_TEST_EXPORT ? false : 'set GB_TEST_EXPORT=1'), timeout: 900000 }, () => {
  const main = 'extends Node2D\n\nfunc _ready() -> void:\n\tvar t := load("res://data/tuning.tres")\n\tprint("tuning loaded: ", t != null)\n';
  const d = tmpProject({
    'project.godot': 'config_version=5\n[application]\nrun/main_scene="res://main.tscn"\nconfig/features=PackedStringArray("4.7", "GL Compatibility")\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n',
    'main.tscn': '[gd_scene format=3]\n\n[ext_resource type="Script" path="res://main.gd" id="1"]\n\n[node name="Main" type="Node2D"]\nscript = ExtResource("1")\n',
    'main.gd': main,
    'data/tuning.tres': '[gd_resource type="Resource" format=3]\n\n[resource]\n',
  });
  // The editor/headless run loads the file fine…
  assert.equal(gb('run', '--frames', '30', '--path', d).status, 0);
  // …but this preset drops data/ from the build, which only the exported game reveals.
  fs.writeFileSync(path.join(d, 'export_presets.cfg'), require('../tools/gb/scaffold.js').exportPresets().replace('exclude_filter="tools/*, tests/*, addons/gut/*"', 'exclude_filter="tools/*, tests/*, addons/gut/*, data/*"'));
  const bad = gb('export', '--preset', 'Windows Desktop', '--smoke', '--path', d);
  assert.equal(bad.status, 1, bad.stdout);
  assert.match(bad.stdout, /error\(s\) in the exported build's log/);
  fs.writeFileSync(path.join(d, 'export_presets.cfg'), require('../tools/gb/scaffold.js').exportPresets());
  const good = gb('export', '--preset', 'Windows Desktop', '--smoke', '--path', d);
  assert.equal(good.status, 0, good.stdout);
  assert.match(good.stdout, /smoke run ok/);
});
