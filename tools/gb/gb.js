#!/usr/bin/env node
'use strict';

/**
 * gb — game-builder verification CLI for Godot 4 projects.
 *
 * The one instrument every game-builder skill uses to answer "does the game actually work?".
 * A model reading its own GDScript cannot answer that; the engine can. So every claim of
 * "done" in this framework is backed by the output of this tool, never by a read of the code.
 *
 * Two facts about Godot shape this file (measured on 4.7.2, 2026-09-25):
 *   1. A runtime SCRIPT ERROR does NOT change the process exit code — `--quit-after` exits 0
 *      with an out-of-bounds error in the log. The exit code alone would report a broken game
 *      as healthy, so every step here reads the log, not just the code.
 *   2. `--check-only` checks ONE script per boot. Checking a project that way costs one engine
 *      start per file, so `check` instead boots once and loads every script (check_all.gd).
 *
 * Zero dependencies, CommonJS, Node >= 18. Copied into each game repo as tools/gb/ by
 * game-bootstrap, so a fresh clone and CI can verify without the plugin installed.
 *
 * Usage: node tools/gb/gb.js <command> [options]
 *   godot                 locate the Godot binary; print version and whether it matches the project
 *   import                headless import of all resources (required on a fresh clone / new assets)
 *   check                 load every .gd in one boot; fail on any parse/compile error
 *   run [--frames N] [--scene res://x.tscn]   run the game headless for N frames; fail on log errors
 *   test                  run GUT or gdUnit4 if installed (skip if neither is present)
 *   verify                import → check → run → test; writes .ai/verify/last.json
 *   kb <query...>         search the gry-wiedza knowledge base (BAZA-AI)
 *   doc [name]            knowledge documents from the gry-wiedza clone (wiedza/): design theory, platforms…
 *   assets <query...> [--typ audio|model_3d|animation|animation_clip|sprite_2d|ui_skin]
 * Common options: --path <project dir> (default: nearest dir with project.godot) · --json
 */

const fs = require('fs');
const path = require('path');
const os = require('os');
const { spawnSync } = require('child_process');

const USAGE = `Usage: node tools/gb/gb.js <command> [options]
 Verify
  verify [--quick]         import -> check -> lint -> run -> test -> scenarios -> replays (--quick: up to test)
  godot                    locate Godot; print version and whether it matches the project
  import                   headless import of all resources (fresh clone / new assets)
  check                    load every .gd in one boot; fail on any parse/compile error
  lint                     broken res:// refs, Godot 3 APIs, assets missing from the licence register, harness
  run [--frames N] [--scene res://x.tscn]   run headless for N frames; fail on log errors
  test                     GUT (or gdUnit4) tests in res://tests (test_*.gd); JUnit in .ai/verify/junit.xml
  scenario [res://tests/scenarios/x.gd] [--window] [--accept | --compare] [--repeat N] [--end-shot]   bot-player scenarios; with a window their shot() calls are saved and can be accepted/compared; --end-shot also saves each scenario's final frame as evidence; --repeat N names FLAKY scenarios
  replay [tests/replays/x.json]                      replay recordings headless; final state must match
 Play & measure (open a window)
  record [name] [--scene res://x.tscn]   the human plays; input saved to tests/replays/<name>.json
  shot [--name N] [--frames 60] [--scene X] [--compare | --accept] [--threshold 0] [--tolerance 0.02]
  perf [--seconds 10] [--scene X] [--headless]      frame/process/physics time, nodes, draw calls vs .ai/perf-budget.json
  export [--preset "Web"] [--smoke]   export presets (templates must be installed); --smoke runs the exported desktop build headless and fails on errors in its log
 Setup (plugin copy of gb)
  scaffold …  ·  harness install  ·  tests install [gut]  ·  doctor
  snapshot [--path R]                  stage everything and print the tree id (git write-tree) — a phase snapshot without a commit
  snapshot checkout <tree> <dir>       a clean copy of that snapshot in <dir> (the repo's index untouched) — for a reviewer's gb verify --path
  credits                  CREDITS.md from .ai/assets/REGISTER.md; fails on licences that cannot ship (NC, ND, unknown, proprietary)
  recipe list  ·  recipe add <NN|name…>   copy tested recipes (+ dependencies + their tests) into recipes/ and tests/
 Knowledge
  kb <query...>            search the gry-wiedza knowledge base (BAZA-AI)
  doc [name]               knowledge documents in gry-wiedza/wiedza (no name: list) — design-theory, platforms, asset-pipeline, starter-packs, reference-games
  assets <query...> [--typ audio|model_3d|animation|animation_clip|sprite_2d|ui_skin]
Options: --path <project dir> (default: nearest dir with project.godot) · --json
Env: GODOT_BIN (Godot executable; on Windows prefer *_console.exe) · GAME_BUILDER_KB (BAZA-AI folder) · GAME_BUILDER_WIEDZA (gry-wiedza clone for gb doc)
`;

const HERE = __dirname;
const CHECK_SCRIPT = path.join(HERE, 'check_all.gd');

// ---------------------------------------------------------------------------------------------
// Project discovery
// ---------------------------------------------------------------------------------------------

function findProjectDir(start) {
  let dir = path.resolve(start);
  for (let i = 0; i < 12; i++) {
    if (fs.existsSync(path.join(dir, 'project.godot'))) return dir;
    const parent = path.dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  return null;
}

/** `config/features=PackedStringArray("4.7", "Forward Plus")` → "4.7" */
function projectEngineVersion(projectGodotText) {
  const m = /config\/features\s*=\s*PackedStringArray\(([^)]*)\)/.exec(projectGodotText || '');
  if (!m) return null;
  const v = /"(\d+\.\d+)"/.exec(m[1]);
  return v ? v[1] : null;
}

function projectMainScene(projectGodotText) {
  const m = /run\/main_scene\s*=\s*"([^"]+)"/.exec(projectGodotText || '');
  return m ? m[1] : null;
}

// ---------------------------------------------------------------------------------------------
// Godot binary discovery
// ---------------------------------------------------------------------------------------------

/** Ordered candidate paths. Pure: takes env/platform/home so tests can drive it. */
function candidateBinaries({ env = process.env, platform = process.platform, home = os.homedir(), listDir = safeList } = {}) {
  const out = [];
  if (env.GODOT_BIN) out.push(env.GODOT_BIN);
  if (env.GODOT) out.push(env.GODOT);
  const names = platform === 'win32' ? ['godot_console.exe', 'godot.exe', 'godot4.exe'] : ['godot4', 'godot'];
  for (const dir of String(env.PATH || '').split(path.delimiter).filter(Boolean)) {
    for (const n of names) out.push(path.join(dir, n));
  }
  const scanDirs = platform === 'win32'
    ? [path.join(home, 'Desktop'), path.join(home, 'Downloads'), path.join(home, 'Godot'), 'C:\\Godot', 'C:\\Program Files\\Godot', path.join(home, 'scoop', 'apps', 'godot', 'current')]
    : platform === 'darwin'
      ? ['/Applications', path.join(home, 'Applications'), path.join(home, 'Downloads')]
      : [path.join(home, '.local', 'bin'), path.join(home, 'Downloads'), path.join(home, 'Godot'), '/usr/local/bin', '/opt/godot'];
  const scanned = [];
  for (const d of scanDirs) {
    for (const n of listDir(d)) {
      if (platform === 'win32' && /^godot.*\.exe$/i.test(n)) scanned.push(path.join(d, n));
      else if (platform === 'darwin' && /^godot.*\.app$/i.test(n)) scanned.push(path.join(d, n, 'Contents', 'MacOS', 'Godot'));
      else if (platform !== 'win32' && platform !== 'darwin' && /^godot/i.test(n) && !/\.(zip|tar|gz|tpz)$/i.test(n)) scanned.push(path.join(d, n));
    }
  }
  // Console builds print to the pipe on Windows; newer versions first.
  scanned.sort((a, b) => consoleRank(a) - consoleRank(b) || versionFromName(b).localeCompare(versionFromName(a), undefined, { numeric: true }));
  out.push(...scanned);
  return [...new Set(out)];
}

function consoleRank(p) {
  return /_console\.exe$/i.test(p) ? 0 : 1;
}

function versionFromName(p) {
  const m = /v?(\d+\.\d+(?:\.\d+)?)/.exec(path.basename(p));
  return m ? m[1] : '0';
}

function safeList(dir) {
  try {
    return fs.readdirSync(dir);
  } catch {
    return [];
  }
}

/** "4.7.2.stable.official.ed1daf0bf" → { full, majorMinor: "4.7" } */
function parseGodotVersion(text) {
  const m = /(\d+)\.(\d+)(?:\.(\d+))?\.[a-z]/i.exec(String(text || ''));
  if (!m) return null;
  return { full: String(text).trim().split(/\s+/)[0], majorMinor: `${m[1]}.${m[2]}` };
}

function binaryVersion(bin) {
  if (!fs.existsSync(bin)) return null;
  const r = spawnSync(bin, ['--version'], { encoding: 'utf8', timeout: 30000, windowsHide: true });
  return parseGodotVersion(`${r.stdout || ''}${r.stderr || ''}`);
}

function pickGodot(wantMajorMinor, opts) {
  const tried = [];
  let fallback = null;
  for (const bin of candidateBinaries(opts)) {
    const v = binaryVersion(bin);
    if (!v) continue;
    tried.push({ bin, version: v.full });
    if (!wantMajorMinor || v.majorMinor === wantMajorMinor) return { bin, version: v.full, matches: true, tried };
    if (!fallback) fallback = { bin, version: v.full, matches: false, tried };
  }
  return fallback || { bin: null, version: null, matches: false, tried };
}

// ---------------------------------------------------------------------------------------------
// Log parsing
// ---------------------------------------------------------------------------------------------

const ERROR_LINE = /^(SCRIPT ERROR|USER SCRIPT ERROR|ERROR|USER ERROR|Parse Error)\s*:\s*(.*)$/;
const WARNING_LINE = /^(WARNING|USER WARNING|SCRIPT WARNING)\s*:\s*(.*)$/;
const AT_LINE = /^\s+at:\s*(.*)$/;

// Engine noise that is not a defect of the game under test.
const DEFAULT_IGNORES = [
  /ObjectDB instances leaked at exit/i,
  /resources still in use at exit/i,
];

function stripAnsi(s) {
  return String(s).replace(/\x1b\[[0-9;]*m/g, '');
}

function parseLog(text, extraIgnores = []) {
  const ignores = DEFAULT_IGNORES.concat(extraIgnores);
  const errors = [];
  const warnings = [];
  let last = null;
  for (const raw of stripAnsi(text).split(/\r?\n/)) {
    const line = raw.replace(/\s+$/, '');
    let m;
    if ((m = ERROR_LINE.exec(line.trim()))) {
      const item = { kind: m[1], message: m[2], at: null };
      if (ignores.some((re) => re.test(line))) { last = null; continue; }
      errors.push(item);
      last = item;
    } else if ((m = WARNING_LINE.exec(line.trim()))) {
      const item = { kind: m[1], message: m[2], at: null };
      if (ignores.some((re) => re.test(line))) { last = null; continue; }
      warnings.push(item);
      last = item;
    } else if (last && (m = AT_LINE.exec(line))) {
      if (!last.at) last.at = m[1];
    }
  }
  return { errors, warnings };
}

function loadIgnoreFile(projectDir) {
  const f = path.join(projectDir, 'tools', 'gb', 'ignore-errors.txt');
  try {
    return fs.readFileSync(f, 'utf8').split(/\r?\n/).map((l) => l.trim()).filter((l) => l && !l.startsWith('#')).map((l) => new RegExp(l, 'i'));
  } catch {
    return [];
  }
}

// ---------------------------------------------------------------------------------------------
// Steps
// ---------------------------------------------------------------------------------------------

function runGodot(bin, args, cwd, timeoutMs) {
  const t0 = Date.now();
  const r = spawnSync(bin, args, { cwd, encoding: 'utf8', timeout: timeoutMs, windowsHide: true, maxBuffer: 64 * 1024 * 1024 });
  return {
    code: r.status,
    timedOut: !!(r.error && r.error.code === 'ETIMEDOUT'),
    spawnError: r.error && r.error.code !== 'ETIMEDOUT' ? String(r.error.message) : null,
    log: stripAnsi(`${r.stdout || ''}\n${r.stderr || ''}`),
    ms: Date.now() - t0,
  };
}

function stepResult(name, r, extra = {}, ignores = []) {
  const parsed = parseLog(r.log, ignores);
  let status = 'ok';
  const reasons = [];
  if (r.spawnError) { status = 'fail'; reasons.push(`could not start Godot: ${r.spawnError}`); }
  if (r.timedOut) { status = 'fail'; reasons.push('timed out'); }
  if (r.code !== 0 && r.code !== null) { status = 'fail'; reasons.push(`exit code ${r.code}`); }
  if (parsed.errors.length) { status = 'fail'; reasons.push(`${parsed.errors.length} error(s) in log`); }
  return { step: name, status, reasons, ms: r.ms, errors: parsed.errors.slice(0, 50), warnings: parsed.warnings.slice(0, 50), ...extra, logTail: r.log.split(/\r?\n/).filter(Boolean).slice(-15) };
}

// A script that preloads a file added outside the editor (a new .ogg/.png) is compiled during the same scan that
// first imports that file, and fails with "has no resource loaders" — measured in Lodowy Loch (4.7.2): the second
// import passes. Only that error triggers one retry, and the report says so.
const IMPORT_ORDER_ERROR = /has no resource loaders \(unrecognized file extension\)/;

function stepImport(ctx) {
  let r = runGodot(ctx.bin, ['--headless', '--path', ctx.dir, '--import'], ctx.dir, ctx.timeouts.import);
  const retried = IMPORT_ORDER_ERROR.test(r.log);
  if (retried) r = runGodot(ctx.bin, ['--headless', '--path', ctx.dir, '--import'], ctx.dir, ctx.timeouts.import);
  const res = stepResult('import', r, {}, ctx.ignores);
  if (retried) res.reasons.push('imported twice: a script preloads files that were new to this import (first pass cannot compile it)');
  return res;
}

function stepCheck(ctx) {
  const r = runGodot(ctx.bin, ['--headless', '--path', ctx.dir, '--script', CHECK_SCRIPT], ctx.dir, ctx.timeouts.check);
  const done = /GB_CHECK_DONE files=(\d+) bad=(\d+)/.exec(r.log);
  const failed = [...r.log.matchAll(/GB_CHECK_FAIL (\S+)/g)].map((m) => m[1]);
  const res = stepResult('check', r, { files: done ? Number(done[1]) : null, failedScripts: failed }, ctx.ignores);
  if (!done) { res.status = 'fail'; res.reasons.push('check script did not report completion'); }
  return res;
}

function stepRun(ctx, frames, scene) {
  const args = ['--headless', '--path', ctx.dir, '--quit-after', String(frames)];
  if (scene) args.push(scene);
  const r = runGodot(ctx.bin, args, ctx.dir, ctx.timeouts.run);
  return stepResult('run', r, { frames, scene: scene || ctx.mainScene }, ctx.ignores);
}

function detectTestFramework(dir) {
  if (fs.existsSync(path.join(dir, 'addons', 'gut', 'gut_cmdln.gd'))) return 'gut';
  if (fs.existsSync(path.join(dir, 'addons', 'gdUnit4', 'bin', 'GdUnitCmdTool.gd'))) return 'gdunit4';
  return null;
}

/** GUT's "Totals" block → numbers. Null when the block is missing (the run did not finish). */
function parseGutTotals(log) {
  const num = (label) => {
    const m = new RegExp(`^${label}\\s+(\\d+)`, 'm').exec(log);
    return m ? Number(m[1]) : null;
  };
  const tests = num('Tests');
  if (tests === null) return null;
  return { scripts: num('Scripts'), tests, passing: num('Passing Tests') || 0, failing: num('Failing Tests') || 0, pending: num('Pending') || 0, risky: num('Risky') || 0 };
}

function stepTest(ctx) {
  const fw = detectTestFramework(ctx.dir);
  if (!fw) return { step: 'test', status: 'skip', reasons: ['no test framework installed (addons/gut or addons/gdUnit4) — node <plugin>/tools/gb/gb.js tests install'], ms: 0, errors: [], warnings: [] };
  const countTests = (d) => {
    let n = 0;
    for (const e of (() => { try { return fs.readdirSync(d, { withFileTypes: true }); } catch { return []; } })()) {
      if (e.isDirectory()) n += countTests(path.join(d, e.name));
      else if (/^test_.*\.gd$/.test(e.name)) n += 1;
    }
    return n;
  };
  const onDisk = countTests(path.join(ctx.dir, 'tests'));
  if (onDisk === 0) return { step: 'test', status: 'skip', reasons: ['no test_*.gd files under tests/'], ms: 0, framework: fw, errors: [], warnings: [] };
  const junit = path.join(ctx.outDir, 'junit.xml');
  fs.mkdirSync(ctx.outDir, { recursive: true });
  const args = fw === 'gut'
    ? ['--headless', '--path', ctx.dir, '-s', 'res://addons/gut/gut_cmdln.gd', '-gdir=res://tests', '-ginclude_subdirs', '-gprefix=test_', '-gsuffix=.gd', `-gjunit_xml_file=${junit}`, '-gexit']
    : ['--headless', '--path', ctx.dir, '-s', 'res://addons/gdUnit4/bin/GdUnitCmdTool.gd', '-a', 'res://tests', '--ignoreHeadlessMode'];
  const r = runGodot(ctx.bin, args, ctx.dir, ctx.timeouts.test);
  const totals = fw === 'gut' ? parseGutTotals(r.log) : null;
  // The test framework is the judge of a test run: engine ERROR lines printed by code under test
  // (deliberate error-path tests) are the framework's to count, so they are reported, not re-judged.
  const parsed = parseLog(r.log, ctx.ignores);
  const reasons = [];
  let status = 'ok';
  if (r.spawnError || r.timedOut) { status = 'fail'; reasons.push(r.timedOut ? 'timed out' : r.spawnError); }
  if (r.code !== 0) { status = 'fail'; reasons.push(`exit code ${r.code}`); }
  if (fw === 'gut' && !totals) { status = 'fail'; reasons.push('no GUT summary in the log (run did not finish, or a test script failed to parse)'); }
  if (totals && totals.failing > 0) reasons.push(`${totals.failing} failing of ${totals.tests}`);
  if (totals && totals.tests === 0) reasons.push('no tests found in res://tests (files must be test_*.gd extending GutTest)');
  // GUT skips a test script that fails to load (parse error, unknown class) and still reports the rest as
  // passing — without this check `gb test` was green while a whole test file never ran.
  const unloaded = [...new Set([...r.log.matchAll(/Failed to load script "(res:\/\/tests\/[^"]*test_[^"]*\.gd)"/g)].map((m) => m[1]))];
  if (unloaded.length) { status = 'fail'; reasons.push(`${unloaded.length} test script(s) did not load and were skipped: ${unloaded.join(', ')}`); }
  else if (fw === 'gut' && totals && totals.scripts !== null && totals.scripts < onDisk) { status = 'fail'; reasons.push(`GUT ran ${totals.scripts} of ${onDisk} test_*.gd files — the others did not load`); }
  const failingTests = [...r.log.matchAll(/^- (test_\S+)\s*\n\s*\[Failed\]:\s*(.*)$/gm)].map((m) => ({ kind: 'TEST FAILED', message: `${m[1]}: ${m[2].trim()}`, at: null }));
  return { step: 'test', status, reasons, ms: r.ms, framework: fw, totals, junit: fs.existsSync(junit) ? junit : null, errors: failingTests.concat(status === 'fail' && !failingTests.length ? parsed.errors : []).slice(0, 50), warnings: [], logTail: r.log.split(/\r?\n/).filter(Boolean).slice(-15) };
}

// ---------------------------------------------------------------------------------------------
// Harness-driven steps: scenarios, replays, shots, perf
// ---------------------------------------------------------------------------------------------

const PLUGIN_ROOT = path.resolve(HERE, '..', '..');
const HARNESS_ARGS_FRAME_CAP = 60 * 300; // hard stop after 5 simulated minutes

function hasHarness(dir) {
  const pg = safeRead(path.join(dir, 'project.godot')) || '';
  return fs.existsSync(path.join(dir, 'addons', 'gb_harness', 'harness.gd')) && /^GbHarness=/m.test(pg);
}

/** Run the game with harness user args. window=false → --headless. fixedFps makes render frames deterministic. */
function gameRun(ctx, { window = false, scene = null, cap = HARNESS_ARGS_FRAME_CAP, userArgs = [], fixedFps = 60, timeout = ctx.timeouts.run } = {}) {
  const args = [];
  if (!window) args.push('--headless');
  args.push('--path', ctx.dir);
  if (fixedFps) args.push('--fixed-fps', String(fixedFps));
  if (cap) args.push('--quit-after', String(cap));
  if (scene) args.push(scene);
  args.push('--', ...userArgs);
  return runGodot(ctx.bin, args, ctx.dir, timeout);
}

/**
 * True when Godot has not registered every `class_name` in the project yet — scripts added outside the
 * editor (`gb recipe add`, a fresh clone) stay unknown until an import, and a run then fails with
 * "Could not find type X" although nothing is wrong with the code.
 */
function classCacheStale(dir) {
  const cache = path.join(dir, '.godot', 'global_script_class_cache.cfg');
  if (!fs.existsSync(cache)) return true;
  const known = fs.readFileSync(cache, 'utf8');
  const { walk } = require('./lint.js');
  return walk(dir, dir).filter((f) => f.endsWith('.gd')).some((f) => {
    const m = /^class_name\s+(\w+)/m.exec(fs.readFileSync(f, 'utf8'));
    return m && !known.includes(`&"${m[1]}"`);
  });
}

function listFiles(dir, re) {
  try {
    return fs.readdirSync(dir).filter((f) => re.test(f)).sort();
  } catch {
    return [];
  }
}

/** Baselines are data for gb, not game resources: a .gdignore keeps Godot from importing (and exporting) them. */
function ensureBaselineDir(baseDir) {
  fs.mkdirSync(baseDir, { recursive: true });
  const ignore = path.join(baseDir, '.gdignore');
  if (!fs.existsSync(ignore)) fs.writeFileSync(ignore, '');
}

/** Scenario screenshots (GB_SHOT lines) → accepted into tests/baselines/, or compared against them. */
function handleScenarioShots(ctx, log, { accept, compare, threshold = 0, tolerance = 0.02 }) {
  const out = [];
  const baseDir = path.join(ctx.dir, 'tests', 'baselines');
  for (const m of log.matchAll(/GB_SHOT name=(\S+) path=(.+?) size=\d+x\d+ err=0/g)) {
    const [, name, file] = m;
    const baseline = path.join(baseDir, `${name}.png`);
    if (name.endsWith('__end')) { out.push({ name, result: 'taken', file }); continue; } // --end-shot evidence, never a baseline
    if (accept) {
      ensureBaselineDir(baseDir);
      fs.copyFileSync(file, baseline);
      out.push({ name, result: 'accepted' });
    } else if (compare) {
      if (!fs.existsSync(baseline)) { out.push({ name, result: 'FAIL', reason: `no baseline tests/baselines/${name}.png — look at the shot, then --accept` }); continue; }
      const d = imgDiff(ctx, baseline, file, file.replace(/\.png$/, '.diff.png'), tolerance);
      const ok = d && d.sizeMatch && d.ratio <= threshold;
      out.push({ name, result: ok ? 'PASS' : 'FAIL', ratio: d ? d.ratio : null, differing: d ? d.differing : null, reason: ok ? null : (d ? (d.sizeMatch ? `${d.differing} px (${(d.ratio * 100).toFixed(2)}%) differ from the baseline — look at ${name}.diff.png` : 'size differs from baseline') : 'diff failed') });
    } else out.push({ name, result: 'taken', file });
  }
  return out;
}

function stepScenarios(ctx, { only = null, window = false, accept = false, compare = false, threshold = 0, tolerance = 0.02, endShot = false } = {}) {
  const dir = path.join(ctx.dir, 'tests', 'scenarios');
  const files = only ? [only] : listFiles(dir, /\.gd$/).map((f) => `res://tests/scenarios/${f}`);
  if (!files.length) return { step: 'scenarios', status: 'skip', reasons: ['no scenarios in tests/scenarios/'], ms: 0, errors: [], warnings: [] };
  if (!hasHarness(ctx.dir)) return { step: 'scenarios', status: 'fail', reasons: ['gb_harness not installed — node <plugin>/tools/gb/gb.js harness install'], ms: 0, errors: [], warnings: [] };
  const t0 = Date.now();
  const results = [];
  const errors = [];
  for (const f of files) {
    const r = gameRun(ctx, { window: window || endShot, userArgs: [`--gb-scenario=${f}`, `--gb-out=${path.join(ctx.outDir, 'shots')}`, ...(endShot ? ['--gb-end-shot'] : [])] });
    const m = /GB_SCENARIO name=\S+ result=(PASS|FAIL) failures=(\d+)/.exec(r.log);
    const expectFails = [...r.log.matchAll(/^GB_EXPECT_FAIL (.*)$/gm)].map((x) => x[1].trim());
    const notes = [...r.log.matchAll(/^GB_NOTE (.*)$/gm)].map((x) => x[1].trim());
    const logErrors = parseLog(r.log, ctx.ignores).errors;
    const shots = window || endShot ? handleScenarioShots(ctx, r.log, { accept, compare, threshold, tolerance }) : [];
    for (const s of shots.filter((x) => x.result === 'FAIL')) errors.push({ kind: 'SHOT', message: `${path.basename(f)}: ${s.name} — ${s.reason}`, at: null });
    const pass = !!m && m[1] === 'PASS' && !logErrors.length && !r.timedOut && !shots.some((x) => x.result === 'FAIL');
    results.push({ scenario: f, result: pass ? 'PASS' : 'FAIL', expectFails, logErrors: logErrors.length, finished: !!m, shots, notes });
    if (!m) errors.push({ kind: 'SCENARIO', message: `${f}: did not finish (no GB_SCENARIO line — crash, timeout or frame cap)`, at: null });
    for (const e of expectFails) errors.push({ kind: 'EXPECT', message: `${path.basename(f)}: ${e}`, at: null });
    for (const e of logErrors) errors.push({ ...e, message: `${path.basename(f)}: ${e.message}` });
  }
  const failed = results.filter((x) => x.result === 'FAIL');
  return { step: 'scenarios', status: failed.length ? 'fail' : 'ok', reasons: failed.length ? [`${failed.length} of ${results.length} failed`] : [], ms: Date.now() - t0, results, count: results.length, errors, warnings: [] };
}

/** Runs the scenarios N times; a scenario that fails in some runs but not all is reported as FLAKY by name. */
function stepScenariosRepeat(ctx, opts, times) {
  const t0 = Date.now();
  const runs = [];
  for (let i = 0; i < times; i++) runs.push(stepScenarios(ctx, opts));
  if (runs[0].status === 'skip') return runs[0];
  const stats = new Map();
  const errors = [];
  runs.forEach((run, i) => {
    for (const r of run.results || []) {
      const s = stats.get(r.scenario) || { pass: 0, fail: 0 };
      s[r.result === 'PASS' ? 'pass' : 'fail']++;
      stats.set(r.scenario, s);
    }
    for (const e of run.errors || []) errors.push({ ...e, message: `run ${i + 1}: ${e.message}` });
  });
  const reasons = [];
  for (const [name, s] of stats) {
    if (s.fail && s.pass) reasons.push(`FLAKY ${path.basename(name)}: passed ${s.pass}/${times}`);
    else if (s.fail) reasons.push(`${path.basename(name)}: failed ${s.fail}/${times}`);
  }
  return { step: 'scenarios', status: reasons.length ? 'fail' : 'ok', reasons, ms: Date.now() - t0, count: stats.size, repeat: times, results: runs.flatMap((r) => r.results || []), errors, warnings: [] };
}

function stepReplays(ctx, { only = null } = {}) {
  const dir = path.join(ctx.dir, 'tests', 'replays');
  const files = only ? [path.resolve(only)] : listFiles(dir, /\.json$/).map((f) => path.join(dir, f));
  if (!files.length) return { step: 'replays', status: 'skip', reasons: ['no recordings in tests/replays/ (node tools/gb/gb.js record <name>)'], ms: 0, errors: [], warnings: [] };
  if (!hasHarness(ctx.dir)) return { step: 'replays', status: 'fail', reasons: ['gb_harness not installed'], ms: 0, errors: [], warnings: [] };
  const t0 = Date.now();
  const results = [];
  const errors = [];
  for (const f of files) {
    let scene = null;
    try { scene = JSON.parse(fs.readFileSync(f, 'utf8')).scene || null; } catch { /* harness reports it */ }
    const r = gameRun(ctx, { scene, userArgs: [`--gb-replay=${f}`, `--gb-out=${ctx.outDir}`] });
    const m = /GB_REPLAY_DONE frames=(\d+) events=(\d+) tracked=(\w+) match=(\w+)/.exec(r.log);
    const logErrors = parseLog(r.log, ctx.ignores).errors;
    const pass = !!m && m[4] === 'true' && !logErrors.length;
    results.push({ replay: path.basename(f), result: pass ? 'PASS' : 'FAIL', tracked: m ? m[3] === 'true' : null, match: m ? m[4] === 'true' : null });
    if (!m) errors.push({ kind: 'REPLAY', message: `${path.basename(f)}: did not finish`, at: null });
    else if (m[4] !== 'true') {
      const exp = /GB_REPLAY_EXPECTED (.*)/.exec(r.log);
      const act = /GB_REPLAY_ACTUAL\s+(.*)/.exec(r.log);
      errors.push({ kind: 'REPLAY', message: `${path.basename(f)}: final state differs — expected [${exp ? exp[1] : '?'}] got [${act ? act[1] : '?'}]`, at: null });
    }
    for (const e of logErrors) errors.push({ ...e, message: `${path.basename(f)}: ${e.message}` });
  }
  const failed = results.filter((x) => x.result === 'FAIL');
  return { step: 'replays', status: failed.length ? 'fail' : 'ok', reasons: failed.length ? [`${failed.length} of ${results.length} failed`] : [], ms: Date.now() - t0, results, count: results.length, errors, warnings: [] };
}

function stepLint(ctx) {
  const t0 = Date.now();
  const { lint } = require('./lint.js');
  const r = lint(ctx.dir);
  return {
    step: 'lint', status: r.errors.length ? 'fail' : 'ok', reasons: r.errors.length ? [`${r.errors.length} problem(s)`] : [], ms: Date.now() - t0,
    errors: r.errors.map((e) => ({ kind: e.rule, message: e.message, at: e.file })),
    warnings: r.warnings.map((e) => ({ kind: e.rule, message: e.message, at: e.file })),
  };
}

function imgDiff(ctx, a, b, diffOut, tolerance) {
  const r = runGodot(ctx.bin, ['--headless', '--path', ctx.dir, '--script', path.join(HERE, 'imgdiff.gd'), '--', `--a=${a}`, `--b=${b}`, `--diff=${diffOut}`, `--tolerance=${tolerance}`], ctx.dir, 120000);
  const m = /GB_IMGDIFF size_match=(\w+).*?differing=(-?\d+) total=(-?\d+) ratio=([\d.]+)/.exec(r.log);
  return m ? { sizeMatch: m[1] === 'true', differing: Number(m[2]), total: Number(m[3]), ratio: Number(m[4]) } : null;
}

/** Peak level of a PCM/float WAV in dBFS (-Infinity = digital silence). Null when the file is not a WAV we can read. */
function wavPeakDb(file) {
  let b;
  try { b = fs.readFileSync(file); } catch { return null; }
  if (b.length < 44 || b.toString('ascii', 0, 4) !== 'RIFF' || b.toString('ascii', 8, 12) !== 'WAVE') return null;
  let fmt = null, off = 12;
  while (off + 8 <= b.length) {
    const id = b.toString('ascii', off, off + 4), size = b.readUInt32LE(off + 4), body = off + 8;
    if (id === 'fmt ') fmt = { format: b.readUInt16LE(body), bits: b.readUInt16LE(body + 14) };
    if (id === 'data' && fmt) {
      const end = Math.min(body + size, b.length);
      let peak = 0;
      if (fmt.format === 3 && fmt.bits === 32) for (let i = body; i + 4 <= end; i += 4) peak = Math.max(peak, Math.abs(b.readFloatLE(i)));
      else if (fmt.bits === 16) for (let i = body; i + 2 <= end; i += 2) peak = Math.max(peak, Math.abs(b.readInt16LE(i)) / 32768);
      else if (fmt.bits === 32) for (let i = body; i + 4 <= end; i += 4) peak = Math.max(peak, Math.abs(b.readInt32LE(i)) / 2147483648);
      else return null;
      return peak > 0 ? 20 * Math.log10(peak) : -Infinity;
    }
    off = body + size + (size % 2);
  }
  return null;
}

/**
 * Screenshot through Godot's Movie Maker (--write-movie): no harness or game code needed. Writes N frames,
 * keeps the last one as <name>.png and the recorded audio as <name>.wav. Needs a window (not headless).
 */
function movieCapture(ctx, { name, frames, scene }) {
  const shotsDir = path.join(ctx.outDir, 'shots');
  const tmp = path.join(shotsDir, `_movie_${name}`);
  fs.rmSync(tmp, { recursive: true, force: true });
  fs.mkdirSync(tmp, { recursive: true });
  const args = ['--path', ctx.dir, '--write-movie', path.join(tmp, `${name}.png`), '--quit-after', String(frames)];
  if (scene) args.push(scene);
  const r = runGodot(ctx.bin, args, ctx.dir, ctx.timeouts.run);
  const re = new RegExp(`^${name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\d{8}\\.png$`);
  const pngs = fs.readdirSync(tmp).filter((f) => re.test(f)).sort();
  let file = null, audio = null;
  if (pngs.length) {
    file = path.join(shotsDir, `${name}.png`);
    fs.copyFileSync(path.join(tmp, pngs[pngs.length - 1]), file);
  }
  const wav = path.join(tmp, `${name}.wav`);
  if (fs.existsSync(wav)) {
    audio = path.join(shotsDir, `${name}.wav`);
    fs.copyFileSync(wav, audio);
  }
  fs.rmSync(tmp, { recursive: true, force: true });
  return { r, file, audio, frames: pngs.length };
}

function stepShot(ctx, { name = 'main', frames = 60, scene = null, compare = false, accept = false, threshold = 0, tolerance = 0.02, movie = false } = {}) {
  const shotsDir = path.join(ctx.outDir, 'shots');
  const useMovie = movie || !hasHarness(ctx.dir);
  const t0 = Date.now();
  let res;
  if (useMovie) {
    fs.mkdirSync(shotsDir, { recursive: true });
    const m = movieCapture(ctx, { name, frames, scene });
    res = stepResult('shot', m.r, { name, frames, method: 'movie' }, ctx.ignores);
    res.ms = Date.now() - t0;
    if (!m.file) { res.status = 'fail'; res.reasons.push('Movie Maker wrote no frames (needs a desktop session with a window)'); return res; }
    res.file = m.file;
    if (m.audio) {
      res.audio = m.audio;
      const db = wavPeakDb(m.audio);
      res.audioPeakDb = db === null ? null : (Number.isFinite(db) ? Math.round(db * 10) / 10 : '-inf');
    }
  } else {
    const r = gameRun(ctx, { window: true, scene, cap: frames + 5, userArgs: [`--gb-shot=${frames}:${name}`, `--gb-out=${shotsDir}`] });
    const m = /GB_SHOT name=\S+ path=(.+?) size=(\d+)x(\d+) err=(\d+)/.exec(r.log);
    res = stepResult('shot', r, { name, frames, method: 'harness' }, ctx.ignores);
    res.ms = Date.now() - t0;
    if (!m || m[4] !== '0') { res.status = 'fail'; res.reasons.push('no screenshot written (needs a desktop session with a window)'); return res; }
    res.file = m[1];
  }
  const baseDir = path.join(ctx.dir, 'tests', 'baselines');
  const baseline = path.join(baseDir, `${name}.png`);
  if (accept) {
    ensureBaselineDir(baseDir);
    fs.copyFileSync(res.file, baseline);
    res.baseline = 'accepted';
  } else if (compare) {
    if (!fs.existsSync(baseline)) { res.status = 'fail'; res.reasons.push(`no baseline tests/baselines/${name}.png — review the shot, then --accept`); return res; }
    const d = imgDiff(ctx, baseline, res.file, path.join(shotsDir, `${name}.diff.png`), tolerance);
    res.diff = d;
    if (!d || !d.sizeMatch || d.ratio > threshold) {
      res.status = 'fail';
      res.reasons.push(d ? (d.sizeMatch ? `${d.differing} px (${(d.ratio * 100).toFixed(2)}%) differ (allowed ${threshold * 100}%) — look at ${name}.diff.png` : 'size differs from baseline') : 'diff failed');
    }
  }
  return res;
}

function stepPerf(ctx, { name = 'perf', seconds = 10, scene = null, window = true } = {}) {
  if (!hasHarness(ctx.dir)) return { step: 'perf', status: 'fail', reasons: ['gb_harness not installed'], ms: 0, errors: [], warnings: [] };
  const perfDir = path.join(ctx.outDir, 'perf');
  const frames = Math.round(seconds * 60) + 30;
  const r = gameRun(ctx, { window, scene, cap: frames, fixedFps: 0, userArgs: [`--gb-perf=${name}`, `--gb-out=${perfDir}`], timeout: (seconds + 60) * 1000 });
  const res = stepResult('perf', r, { name, window }, ctx.ignores);
  const file = path.join(perfDir, `${name}.json`);
  if (!fs.existsSync(file)) { res.status = 'fail'; res.reasons.push('no perf report written'); return res; }
  const summary = JSON.parse(fs.readFileSync(file, 'utf8'));
  res.summary = summary;
  res.file = file;
  const budget = safeRead(path.join(ctx.dir, '.ai', 'perf-budget.json'));
  if (budget) {
    const b = JSON.parse(budget);
    const checks = [['frame_ms_p95', summary.frame_ms && summary.frame_ms.p95], ['process_ms_p95', summary.process_ms && summary.process_ms.p95], ['physics_ms_p95', summary.physics_ms && summary.physics_ms.p95], ['draw_calls_max', summary.draw_calls && summary.draw_calls.max], ['nodes_max', summary.nodes && summary.nodes.max], ['static_memory_mb_max', summary.static_memory_mb && summary.static_memory_mb.max]];
    for (const [k, v] of checks) {
      if (b[k] == null || v == null) continue;
      if (!window && (k === 'frame_ms_p95' || k === 'draw_calls_max')) continue; // meaningless headless
      if (v > b[k]) { res.status = 'fail'; res.reasons.push(`${k} ${v.toFixed(2)} > budget ${b[k]}`); }
    }
  }
  return res;
}

// ---------------------------------------------------------------------------------------------
// Installers (plugin copy only: they carry vendored files)
// ---------------------------------------------------------------------------------------------

function copyDir(src, dst) {
  fs.mkdirSync(dst, { recursive: true });
  for (const e of fs.readdirSync(src, { withFileTypes: true })) {
    const s = path.join(src, e.name);
    const d = path.join(dst, e.name);
    if (e.isDirectory()) copyDir(s, d);
    else if (!fs.existsSync(d)) fs.copyFileSync(s, d);
  }
}

function setProjectSetting(ctx, args) {
  const r = runGodot(ctx.bin, ['--headless', '--path', ctx.dir, '--script', path.join(HERE, 'project_setting.gd'), '--', ...args], ctx.dir, 120000);
  return /GB_SETTING changed=(\d+) err=0/.exec(r.log) ? 'ok' : `failed: ${r.log.split(/\r?\n/).filter(Boolean).slice(-3).join(' | ')}`;
}

function installHarness(ctx) {
  const src = path.join(PLUGIN_ROOT, 'templates', 'addons', 'gb_harness');
  if (!fs.existsSync(src)) throw new UserError('harness install runs from the plugin copy of gb.');
  copyDir(src, path.join(ctx.dir, 'addons', 'gb_harness'));
  const s = setProjectSetting(ctx, ['--autoload=GbHarness=res://addons/gb_harness/harness.gd']);
  return [`harness: addons/gb_harness copied (existing files kept); autoload GbHarness ${s}`];
}

function installTests(ctx, fw) {
  if (fw !== 'gut') throw new UserError('Only GUT is vendored with game-builder (tests install gut). gdUnit4: install it from the Godot Asset Library; gb test detects it.');
  const src = path.join(PLUGIN_ROOT, 'vendor', 'gut', 'addons', 'gut');
  if (!fs.existsSync(src)) throw new UserError('tests install runs from the plugin copy of gb.');
  const version = (safeRead(path.join(PLUGIN_ROOT, 'vendor', 'gut', 'VERSION')) || '?').trim();
  copyDir(src, path.join(ctx.dir, 'addons', 'gut'));
  const s = setProjectSetting(ctx, ['--enable-plugin=res://addons/gut/plugin.cfg']);
  const imp = runGodot(ctx.bin, ['--headless', '--path', ctx.dir, '--import'], ctx.dir, ctx.timeouts.import);
  return [`tests: GUT ${version} copied to addons/gut; editor plugin ${s}; import ${imp.code === 0 ? 'ok' : 'had errors'}`];
}

// ---------------------------------------------------------------------------------------------
// Export
// ---------------------------------------------------------------------------------------------

function parsePresets(text) {
  const presets = [];
  let cur = null;
  for (const line of String(text || '').split(/\r?\n/)) {
    const h = /^\[preset\.(\d+)\]$/.exec(line.trim());
    if (h) { cur = { index: Number(h[1]) }; presets.push(cur); continue; }
    if (/^\[/.test(line.trim())) { cur = null; continue; }
    const kv = /^(name|platform|export_path)="(.*)"$/.exec(line.trim());
    if (cur && kv) cur[kv[1]] = kv[2];
  }
  return presets;
}

function templatesDir(version) {
  const base = process.platform === 'win32' ? path.join(process.env.APPDATA || '', 'Godot') : process.platform === 'darwin' ? path.join(os.homedir(), 'Library', 'Application Support', 'Godot') : path.join(os.homedir(), '.local', 'share', 'godot');
  return path.join(base, 'export_templates', version.replace(/\.official.*$/, '').replace(/^(\d+\.\d+\.\d+|\d+\.\d+)\.(\w+)$/, '$1.$2'));
}

/** Size of one export: the main file plus its siblings sharing the stem (web: index.wasm/.pck/.js…; desktop: a separate .pck). */
function exportBytes(out) {
  const dir = path.dirname(out);
  const main = path.basename(out);
  const stem = path.basename(out, path.extname(out));
  let total = 0;
  for (const f of fs.readdirSync(dir)) {
    if (f !== main && !f.startsWith(`${stem}.`)) continue;
    const st = fs.statSync(path.join(dir, f));
    if (st.isFile()) total += st.size;
  }
  return total;
}

function stepExport(ctx, presetName, smoke = false) {
  const presets = parsePresets(safeRead(path.join(ctx.dir, 'export_presets.cfg')));
  if (!presets.length) return [{ step: 'export', status: 'fail', reasons: ['no export_presets.cfg (scaffold creates Windows Desktop + Web)'], ms: 0, errors: [], warnings: [] }];
  const chosen = presetName ? presets.filter((p) => p.name === presetName) : presets;
  if (!chosen.length) return [{ step: 'export', status: 'fail', reasons: [`no preset named "${presetName}" (have: ${presets.map((p) => p.name).join(', ')})`], ms: 0, errors: [], warnings: [] }];
  const tdir = templatesDir(ctx.godotVersion);
  return chosen.map((p) => {
    const out = path.join(ctx.dir, p.export_path || `build/${p.name}`);
    fs.mkdirSync(path.dirname(out), { recursive: true });
    const r = runGodot(ctx.bin, ['--headless', '--path', ctx.dir, '--export-release', p.name, out], ctx.dir, 900000);
    const res = stepResult(`export:${p.name}`, r, { output: out }, ctx.ignores);
    if (/export templates|szablon/i.test(r.log) && res.status === 'fail') {
      res.reasons.unshift(`export templates for ${p.platform} are missing in ${tdir} — install them once: Godot editor → Editor → Manage Export Templates → Download and Install`);
      res.missingTemplates = true;
    }
    if (res.status === 'ok' && (!fs.existsSync(out) || fs.statSync(out).size === 0)) { res.status = 'fail'; res.reasons.push(`no output at ${out}`); }
    if (res.status === 'ok') res.bytes = exportBytes(out);
    if (res.status === 'ok' && smoke) res.smoke = smokeRun(ctx, out, p.platform);
    if (res.smoke && res.smoke.status === 'fail') { res.status = 'fail'; res.reasons.push(...res.smoke.reasons); }
    return res;
  });
}

/**
 * Runs an exported desktop build headless for a few seconds and reads its log file (--headless, --quit-after
 * and --log-file work in release builds; measured on 4.7.2). Catches what the editor run cannot: resources
 * dropped by export filters, missing autoloads, errors only in release. Web builds are not smoke-run.
 */
function smokeRun(ctx, exe, platform, frames = 180) {
  if (!/Windows|Linux|macOS/i.test(platform || '') || !/\.(exe|x86_64|arm64|app)$|^[^.]+$/.test(path.basename(exe))) {
    return { status: 'skip', reasons: [`smoke run not available for ${platform}`] };
  }
  const log = path.join(ctx.outDir, `smoke-${path.basename(exe)}.log`);
  fs.mkdirSync(ctx.outDir, { recursive: true });
  fs.rmSync(log, { force: true });
  const r = spawnSync(exe, ['--headless', '--quit-after', String(frames), '--log-file', log], { cwd: path.dirname(exe), encoding: 'utf8', timeout: 120000 });
  const text = safeRead(log) || `${r.stdout || ''}\n${r.stderr || ''}`;
  const parsed = parseLog(text, ctx.ignores);
  const reasons = [];
  if (r.error) reasons.push(`could not start ${exe}: ${r.error.message}`);
  if (!safeRead(log)) reasons.push('the build wrote no log file (crashed before start?)');
  if (parsed.errors.length) reasons.push(`${parsed.errors.length} error(s) in the exported build's log: ${parsed.errors.slice(0, 3).map((e) => e.message || e).join(' | ')}`);
  return { status: reasons.length ? 'fail' : 'ok', reasons, frames, log, exit: r.status };
}

// ---------------------------------------------------------------------------------------------
// Knowledge base (gry-wiedza BAZA-AI)
// ---------------------------------------------------------------------------------------------

function findKnowledgeBase({ env = process.env, home = os.homedir() } = {}) {
  const c = [env.GAME_BUILDER_KB, path.join(home, 'Desktop', 'gry-wiedza', 'BAZA-AI'), path.join(home, 'gry-wiedza', 'BAZA-AI')].filter(Boolean);
  return c.find((d) => fs.existsSync(path.join(d, 'dla-ai', 'szukaj.mjs'))) || null;
}

const WIEDZA_URL = 'https://github.com/szymonkomorowski20-design/gry-wiedza/blob/main/wiedza';

/**
 * The gry-wiedza clone holding the knowledge documents (`wiedza/`): GAME_BUILDER_WIEDZA, else the clone that
 * contains BAZA-AI, else ~/Desktop/gry-wiedza or ~/gry-wiedza. Null when none has a `wiedza/` folder.
 */
function findWiedza({ env = process.env, home = os.homedir() } = {}) {
  const kb = findKnowledgeBase({ env, home });
  const candidates = [env.GAME_BUILDER_WIEDZA, kb && path.dirname(kb), path.join(home, 'Desktop', 'gry-wiedza'), path.join(home, 'gry-wiedza')];
  return candidates.filter(Boolean).find((d) => fs.existsSync(path.join(d, 'wiedza'))) || null;
}

/** gb doc [name] — the knowledge documents moved to gry-wiedza (design theory, platforms, asset pipeline…). */
function docCommand(args) {
  const name = (args[0] || '').replace(/\.md$/i, '');
  const root = findWiedza();
  if (!root) {
    process.stderr.write(`gry-wiedza clone with a wiedza/ folder not found (set GAME_BUILDER_WIEDZA or clone the repo to ~/Desktop/gry-wiedza).\n` +
      `Online: ${name ? `${WIEDZA_URL}/${name}.md` : WIEDZA_URL}\n`);
    return 3;
  }
  const dir = path.join(root, 'wiedza');
  if (!name) {
    const docs = fs.readdirSync(dir).filter((f) => f.endsWith('.md') && f.toLowerCase() !== 'readme.md').sort();
    process.stdout.write(`Knowledge documents in ${dir} (gb doc <name>):\n`);
    for (const f of docs) {
      const title = ((safeRead(path.join(dir, f)) || '').match(/^#\s+(.+)$/m) || [, ''])[1];
      process.stdout.write(`  ${f.replace(/\.md$/, '').padEnd(18)}${title}\n`);
    }
    return 0;
  }
  const text = safeRead(path.join(dir, `${name}.md`));
  if (text === null) {
    process.stderr.write(`No wiedza/${name}.md in ${root} (run \`gb doc\` for the list; pull the clone if it is new).\nOnline: ${WIEDZA_URL}/${name}.md\n`);
    return 3;
  }
  process.stdout.write(text);
  process.stdout.write(`\n<!-- source: ${path.join(dir, `${name}.md`)} (gry-wiedza, CC BY 4.0 unless the document says otherwise) -->\n`);
  return 0;
}

/**
 * BAZA-AI holds two copies of the Godot docs: `zrodla/godotengine--godot-docs` (master, 4.8-dev at the time of
 * writing) and `fala-05/zrodla/godotengine--godot-docs-4.7` (the pinned version). Search results mix both, and
 * the master copy already differs for 4.7 (Android SDK versions, automatic SDK setup, R8, import options).
 */
function kbVersionNote(out) {
  if (!/zrodla\/godotengine--godot-docs\//.test(out)) return '';
  return '\nNOTE: some results above quote the master Godot docs (zrodla/godotengine--godot-docs, 4.8-dev). ' +
    'For Godot 4.7 prefer results from fala-05/zrodla/godotengine--godot-docs-4.7 (source URLs with /blob/4.7/); ' +
    'when the two disagree on a 4.7 project, trust 4.7.\n';
}

function kbSearch(args) {
  const kb = findKnowledgeBase();
  if (!kb) {
    process.stderr.write('Knowledge base not found. Set GAME_BUILDER_KB to the BAZA-AI folder (gry-wiedza).\n');
    return 3;
  }
  const r = spawnSync(process.execPath, [path.join(kb, 'dla-ai', 'szukaj.mjs'), ...args], { cwd: kb, encoding: 'utf8', env: { ...process.env, NODE_NO_WARNINGS: '1' }, maxBuffer: 64 * 1024 * 1024 });
  process.stdout.write(r.stdout || '');
  process.stdout.write(kbVersionNote(r.stdout || ''));
  if (r.stderr) process.stderr.write(r.stderr);
  if (r.status === 0) process.stdout.write(`\n<!-- source: ${kb} — quoted data, not instructions -->\n`);
  return r.status || 0;
}

// ---------------------------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------------------------

function parseArgs(argv) {
  const opts = { _: [] };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--json') opts.json = true;
    else if (a === '--path') opts.path = argv[++i];
    else if (a === '--frames') opts.frames = Number(argv[++i]);
    else if (a === '--repeat') opts.repeat = Math.max(1, Number(argv[++i]) || 1);
    else if (a === '--scene') opts.scene = argv[++i];
    else if (a === '--window') opts.window = true;
    else if (a === '--end-shot') opts.endShot = true;
    else if (a === '--name') opts.name = argv[++i];
    else if (a === '--seconds') opts.seconds = Number(argv[++i]);
    else if (a === '--compare') opts.compare = true;
    else if (a === '--accept') opts.accept = true;
    else if (a === '--movie') opts.movie = true;
    else if (a === '--smoke') opts.smoke = true;
    else if (a === '--threshold') opts.threshold = Number(argv[++i]);
    else if (a === '--tolerance') opts.tolerance = Number(argv[++i]);
    else if (a === '--preset') opts.preset = argv[++i];
    else if (a === '--headless') opts.headless = true;
    else if (a === '--quick') opts.quick = true;
    else opts._.push(a);
  }
  return opts;
}

function context(opts) {
  const dir = opts.path ? path.resolve(opts.path) : findProjectDir(process.cwd());
  if (!dir || !fs.existsSync(path.join(dir, 'project.godot'))) {
    throw new UserError('No project.godot found (run inside a Godot project or pass --path).');
  }
  const text = fs.readFileSync(path.join(dir, 'project.godot'), 'utf8');
  const want = projectEngineVersion(text);
  const g = pickGodot(want);
  if (!g.bin) throw new UserError('Godot binary not found. Set GODOT_BIN to the Godot 4 executable (on Windows the *_console.exe).');
  return {
    dir, want, mainScene: projectMainScene(text), bin: g.bin, godotVersion: g.version, versionMatches: g.matches,
    ignores: loadIgnoreFile(dir),
    outDir: path.join(dir, '.ai', 'verify'),
    timeouts: { import: 300000, check: 180000, run: 180000, test: 900000 },
  };
}

class UserError extends Error {}

function printStep(s) {
  const tag = s.status === 'ok' ? 'PASS' : s.status === 'skip' ? 'SKIP' : 'FAIL';
  let extra = '';
  if (s.step === 'check' && s.files != null) extra = ` (${s.files} scripts)`;
  else if (s.step === 'run') extra = ` (${s.frames} frames, ${s.scene || 'main scene'})`;
  else if (s.step === 'test' && s.totals) extra = ` (${s.framework}: ${s.totals.passing}/${s.totals.tests} passing)`;
  else if (s.framework) extra = ` (${s.framework})`;
  else if (s.step === 'scenarios' && s.repeat) extra = ` (${s.count} scenario(s) × ${s.repeat} runs${s.status === 'ok' ? ', all passed every run' : ''})`;
  else if ((s.step === 'scenarios' || s.step === 'replays') && s.count) extra = ` (${s.count - (s.results || []).filter((x) => x.result === 'FAIL').length}/${s.count} passing)`;
  else if (s.step === 'shot' && s.file) extra = ` (${s.name} → ${s.file}${s.diff ? `, ${s.diff.differing} px (${(s.diff.ratio * 100).toFixed(2)}%) differ from the baseline` : ''}${s.baseline ? ', baseline accepted' : ''}${s.audio ? `, audio peak ${s.audioPeakDb} dBFS` : ''})`;
  else if (s.step === 'perf' && s.summary) extra = ` (${s.window ? 'window' : 'headless'}: frame p95 ${fmtNum(s.summary.frame_ms && s.summary.frame_ms.p95)} ms, process p95 ${fmtNum(s.summary.process_ms && s.summary.process_ms.p95)} ms, nodes max ${fmtNum(s.summary.nodes && s.summary.nodes.max, 0)}, draw calls max ${fmtNum(s.summary.draw_calls && s.summary.draw_calls.max, 0)})`;
  else if (s.step.startsWith('export:') && s.bytes) extra = ` (${(s.bytes / 1e6).toFixed(1)} MB → ${s.output}${s.smoke ? `, smoke run ${s.smoke.status}${s.smoke.status === 'ok' ? ` (${s.smoke.frames} frames headless, log clean)` : ''}` : ''})`;
  process.stdout.write(`${tag} ${s.step}${extra} — ${s.ms} ms${s.reasons.length ? ' — ' + s.reasons.join('; ') : ''}\n`);
  for (const e of s.errors.slice(0, 10)) process.stdout.write(`     ${e.kind}: ${e.message}${e.at ? `  [${e.at}]` : ''}\n`);
  if (s.errors.length > 10) process.stdout.write(`     … ${s.errors.length - 10} more\n`);
  if (s.step === 'lint') for (const w of s.warnings.slice(0, 10)) process.stdout.write(`     warn ${w.kind}: ${w.message}  [${w.at}]\n`);
  if (s.step === 'scenarios') {
    for (const r of s.results || []) {
      const notes = r.notes || [];
      for (const n of notes.slice(0, 40)) process.stdout.write(`     note ${path.basename(r.scenario)}: ${n}\n`);
      if (notes.length > 40) process.stdout.write(`     … ${notes.length - 40} more notes (--json has all)\n`);
    }
    for (const r of s.results || []) for (const sh of r.shots || []) {
      if (sh.result === 'PASS') process.stdout.write(`     shot ${sh.name}: ${sh.differing} px differ from the baseline\n`);
      else if (sh.result === 'accepted') process.stdout.write(`     shot ${sh.name}: accepted as the new baseline\n`);
      else if (sh.result === 'taken') process.stdout.write(`     shot ${sh.name}: ${sh.file}\n`);
    }
  }
}

function fmtNum(v, digits = 2) {
  return typeof v === 'number' ? v.toFixed(digits) : '?';
}

function writeReport(dir, report) {
  const out = path.join(dir, '.ai', 'verify');
  try {
    fs.mkdirSync(out, { recursive: true });
    fs.writeFileSync(path.join(out, 'last.json'), JSON.stringify(report, null, 2));
    return path.join(out, 'last.json');
  } catch {
    return null;
  }
}

function cmdCredits(opts) {
  const dir = findProjectDir(opts.path || process.cwd());
  if (!dir) throw new UserError('No project.godot found (use --path).');
  const C = require('./credits.js');
  const reg = safeRead(path.join(dir, '.ai', 'assets', 'REGISTER.md'));
  if (reg === null) throw new UserError('No .ai/assets/REGISTER.md — every asset needs a row there first.');
  const rows = C.parseRegister(reg);
  const problems = C.check(rows, dir);
  const title = (/^config\/name="([^"]*)"/m.exec(safeRead(path.join(dir, 'project.godot')) || '') || [])[1] || path.basename(dir);
  const out = path.join(dir, 'CREDITS.md');
  fs.writeFileSync(out, C.render(rows, title));
  process.stdout.write(`${problems.length ? 'FAIL' : 'PASS'} credits — ${rows.length} asset(s) → ${out}\n`);
  for (const p of problems) process.stdout.write(`     ${p}\n`);
  return problems.length ? 1 : 0;
}

function cmdRecipe(opts) {
  const root = path.join(PLUGIN_ROOT, 'recipes');
  if (!fs.existsSync(path.join(root, 'README.md'))) throw new UserError('recipes/ not found — run the plugin copy: node <plugin>/tools/gb/gb.js recipe …');
  const R = require('./recipe.js');
  const sub = opts._.shift();
  if (sub === 'list') {
    const info = R.catalog(root);
    if (opts.json) { process.stdout.write(JSON.stringify(info, null, 2) + '\n'); return 0; }
    for (const [d, v] of Object.entries(info)) process.stdout.write(`${d.padEnd(28)} ${v.title}${v.deps.length ? `  (needs ${v.deps.join(', ')})` : ''}\n`);
    process.stdout.write(`\nDetails: ${path.join(root, 'README.md')}\n`);
    return 0;
  }
  if (sub === 'add') {
    if (!opts._.length) throw new UserError('Usage: gb recipe add <NN|name> [more…] --path <game>');
    const dir = findProjectDir(opts.path || process.cwd());
    if (!dir) throw new UserError('No project.godot found (use --path).');
    const r = R.add(root, dir, opts._);
    process.stdout.write(`Recipes: ${r.recipes.join(', ')}\n`);
    for (const f of r.added) process.stdout.write(`  + ${f}\n`);
    for (const f of r.skipped) process.stdout.write(`  = ${f} (exists — not overwritten)\n`);
    process.stdout.write('Next: read each recipes/<NN>/README.md (Tuning, Pitfalls), then gb verify.\n');
    return 0;
  }
  throw new UserError('Usage: gb recipe list | gb recipe add <NN|name…> --path <game>');
}

function main(argv) {
  // kb/assets pass their flags straight through to the knowledge-base search.
  if (argv[0] === 'kb') return kbSearch(argv.slice(1));
  if (argv[0] === 'doc') return docCommand(argv.slice(1));
  if (argv[0] === 'assets') return kbSearch(['--assety', ...argv.slice(1)]);
  if (argv[0] === 'scaffold') return cmdScaffold(argv.slice(1));
  if (argv[0] === 'tools' && argv[1] === 'update') return cmdToolsUpdate(parseArgs(argv.slice(2)));
  if (argv[0] === 'doctor') return cmdDoctor(parseArgs(argv.slice(1)));
  if (argv[0] === 'snapshot') return cmdSnapshot(argv.slice(1));
  if (argv[0] === 'recipe') return cmdRecipe(parseArgs(argv.slice(1)));
  if (argv[0] === 'credits') return cmdCredits(parseArgs(argv.slice(1)));
  const opts = parseArgs(argv);
  const cmd = opts._.shift();
  if (!cmd || cmd === 'help' || cmd === '--help' || cmd === '-h') {
    process.stdout.write(USAGE);
    return 0;
  }
  const ctx = context(opts);
  const header = { godot: ctx.bin, godotVersion: ctx.godotVersion, projectEngine: ctx.want, versionMatches: ctx.versionMatches, project: ctx.dir };

  if (cmd === 'godot') {
    if (opts.json) process.stdout.write(JSON.stringify(header, null, 2) + '\n');
    else process.stdout.write(`Godot ${ctx.godotVersion} at ${ctx.bin}\nProject expects ${ctx.want || '(unspecified)'} — ${ctx.versionMatches ? 'match' : 'MISMATCH'}\n`);
    return ctx.versionMatches ? 0 : 1;
  }

  if (cmd === 'harness' || cmd === 'tests') {
    const sub = opts._.shift();
    if (sub !== 'install') throw new UserError(`Usage: gb ${cmd} install${cmd === 'tests' ? ' [gut]' : ''}`);
    const lines = cmd === 'harness' ? installHarness(ctx) : installTests(ctx, opts._[0] || 'gut');
    process.stdout.write(lines.join('\n') + '\n');
    return lines.some((l) => /failed/.test(l)) ? 1 : 0;
  }

  if (cmd === 'record') {
    if (!hasHarness(ctx.dir)) throw new UserError('gb_harness not installed — node <plugin>/tools/gb/gb.js harness install');
    const name = opts._[0] || opts.name || `play-${new Date().toISOString().slice(0, 16).replace(/[:T]/g, '-')}`;
    const outDir = path.join(ctx.dir, 'tests', 'replays');
    fs.mkdirSync(outDir, { recursive: true });
    process.stdout.write(`Recording "${name}" — the game window opens; play, then close the window.\n`);
    const r = gameRun(ctx, { window: true, scene: opts.scene, cap: 0, fixedFps: 0, userArgs: [`--gb-record=${name}`, `--gb-out=${outDir}`, `--gb-seed=${opts.seed || 12345}`], timeout: 3600000 });
    const m = /GB_RECORD path=(.+?) events=(\d+) frames=(\d+)/.exec(r.log);
    process.stdout.write(m ? `RECORDED ${m[2]} input events over ${m[3]} physics frames → ${m[1]}\nReplay it any time: node tools/gb/gb.js replay ${path.relative(ctx.dir, m[1])}\n` : 'FAIL no recording written\n');
    return m ? 0 : 1;
  }

  const pre = ['run', 'test', 'scenario', 'replay', 'shot', 'perf', 'export'].includes(cmd) && classCacheStale(ctx.dir) ? [stepImport(ctx)] : [];
  let steps;
  if (cmd === 'import') steps = [stepImport(ctx)];
  else if (cmd === 'check') steps = [stepCheck(ctx)];
  else if (cmd === 'lint') steps = [stepLint(ctx)];
  else if (cmd === 'run') steps = [stepRun(ctx, opts.frames || 120, opts.scene)];
  else if (cmd === 'test') steps = [stepTest(ctx)];
  else if (cmd === 'scenario') {
    const so = { only: opts._[0] || null, window: !!opts.window || !!opts.accept || !!opts.compare, accept: !!opts.accept, compare: !!opts.compare, threshold: opts.threshold ?? 0, tolerance: opts.tolerance ?? 0.02, endShot: !!opts.endShot };
    steps = [opts.repeat > 1 ? stepScenariosRepeat(ctx, so, opts.repeat) : stepScenarios(ctx, so)];
  }
  else if (cmd === 'replay') steps = [stepReplays(ctx, { only: opts._[0] || null })];
  else if (cmd === 'shot') steps = [stepShot(ctx, { name: opts.name || 'main', frames: opts.frames || 60, scene: opts.scene, compare: !!opts.compare, accept: !!opts.accept, threshold: opts.threshold ?? 0, tolerance: opts.tolerance ?? 0.02, movie: !!opts.movie })];
  else if (cmd === 'perf') steps = [stepPerf(ctx, { name: opts.name || 'perf', seconds: opts.seconds || 10, scene: opts.scene, window: !opts.headless })];
  else if (cmd === 'export') steps = stepExport(ctx, opts.preset, !!opts.smoke);
  else if (cmd === 'verify') {
    steps = [stepImport(ctx)];
    // A parse error surfaces during import already; still run check so the report names every
    // broken script, not just the first scene that tripped over one. Only an import that could
    // not run at all (no binary, timeout) stops here.
    const imp = steps[0];
    if (imp.status === 'ok' || !imp.reasons.some((r) => /could not start|timed out/.test(r))) steps.push(stepCheck(ctx));
    steps.push(stepLint(ctx));
    if (steps.every((s) => s.status !== 'fail')) steps.push(stepRun(ctx, opts.frames || 120, opts.scene));
    if (steps.every((s) => s.status !== 'fail')) {
      steps.push(stepTest(ctx));
      if (!opts.quick) {
        steps.push(stepScenarios(ctx));
        steps.push(stepReplays(ctx));
      }
    }
  } else {
    throw new UserError(`Unknown command: ${cmd}`);
  }
  steps = [...pre, ...steps];

  const failed = steps.some((s) => s.status === 'fail');
  const report = { tool: 'game-builder gb', command: cmd, at: new Date().toISOString(), ...header, result: failed ? 'FAIL' : 'PASS', steps };
  const file = cmd === 'verify' ? writeReport(ctx.dir, report) : null;
  if (opts.json) process.stdout.write(JSON.stringify(report, null, 2) + '\n');
  else {
    if (!ctx.versionMatches) process.stdout.write(`WARN Godot ${ctx.godotVersion} does not match project engine ${ctx.want}\n`);
    steps.forEach(printStep);
    process.stdout.write(`${report.result} — Godot ${ctx.godotVersion}${file ? ` — report: ${path.relative(ctx.dir, file)}` : ''}\n`);
  }
  return failed ? 1 : 0;
}

// ---------------------------------------------------------------------------------------------
// scaffold (plugin copy only) and doctor (repo definition of done)
// ---------------------------------------------------------------------------------------------

function cmdScaffold(argv) {
  let sc;
  try {
    sc = require('./scaffold.js');
  } catch {
    throw new UserError('scaffold runs from the game-builder plugin copy of gb (tools/gb/gb.js inside the plugin), not from a game repo.');
  }
  const o = sc.parseScaffoldArgs(argv);
  const existing = path.join(o.dir, 'project.godot');
  if (fs.existsSync(existing) && !o.adopt) {
    throw new UserError(`${existing} exists — this is an existing project. Use --adopt (game-bootstrap Case C), which never overwrites anything.`);
  }
  if (o.adopt && !fs.existsSync(existing)) throw new UserError('--adopt needs an existing project.godot in --dir.');
  const g = pickGodot(o.adopt ? projectEngineVersion(fs.readFileSync(existing, 'utf8')) : null);
  if (!o.engine) o.engine = o.adopt ? projectEngineVersion(fs.readFileSync(existing, 'utf8')) || '4.7' : (g.version ? parseGodotVersion(g.version).majorMinor : '4.7');
  const full = g.version && /^(\d+\.\d+(?:\.\d+)?)/.exec(g.version);
  o.engineFull = full && full[1].startsWith(o.engine) ? full[1] : o.engine;
  fs.mkdirSync(o.dir, { recursive: true });
  const runner = g.bin ? (args) => runGodot(g.bin, args, o.dir, 180000).log : null;
  const report = sc.scaffold(o, { runGodot: runner, dryRun: o.dryRun });
  if (o.adopt && !o.dryRun && g.bin) {
    const actx = { dir: o.dir, bin: g.bin, timeouts: { import: 300000 } };
    report.push(...installHarness(actx).map((l) => `INSTALL ${l}`));
    if (o.tests === 'gut' && !detectTestFramework(o.dir)) report.push(...installTests(actx, 'gut').map((l) => `INSTALL ${l}`));
  }
  process.stdout.write(report.join('\n') + '\n');
  if (!g.bin) process.stdout.write('WARN    Godot not found — input actions not added; set GODOT_BIN and run: godot --headless --path . --script tools/gb/setup_input.gd\n');
  if (!o.dryRun && g.bin) {
    const imp = runGodot(g.bin, ['--headless', '--path', o.dir, '--import'], o.dir, 300000);
    const impErrors = parseLog(imp.log).errors;
    process.stdout.write(`IMPORT  ${imp.code === 0 && !impErrors.length ? 'ok' : `exit ${imp.code}, ${impErrors.length} error(s) — run gb verify`} (Godot ${g.version})\n`);
    for (const e of impErrors.slice(0, 5)) process.stdout.write(`        ${e.kind}: ${e.message}${e.at ? `  [${e.at}]` : ''}\n`);
  }
  process.stdout.write(`\nNext: write .ai/brief.md, git init + first commit, then: node tools/gb/gb.js doctor && node tools/gb/gb.js verify\n`);
  return report.some((l) => l.startsWith('FAIL')) ? 1 : 0;
}

/** Framework files a game repo carries in tools/gb/ — replaced by `gb tools update`; ignore-errors.txt is the repo's own. */
const TOOL_FILES = ['gb.js', 'lint.js', 'credits.js', 'check_all.gd', 'setup_input.gd', 'project_setting.gd', 'imgdiff.gd'];

function toolsOutdated(dir) {
  if (!fs.existsSync(path.join(PLUGIN_ROOT, 'templates'))) return null; // running from a repo copy: nothing to compare with
  return TOOL_FILES.filter((f) => {
    const a = safeRead(path.join(HERE, f));
    const b = safeRead(path.join(dir, 'tools', 'gb', f));
    return a !== null && a !== b;
  });
}

const HARNESS_FILES = ['harness.gd', 'scenario.gd'];

/** Harness framework files that differ from the plugin's (only when the game has the harness). */
function harnessOutdated(dir) {
  const src = path.join(PLUGIN_ROOT, 'templates', 'addons', 'gb_harness');
  const dst = path.join(dir, 'addons', 'gb_harness');
  if (!fs.existsSync(src) || !fs.existsSync(dst)) return [];
  return HARNESS_FILES.filter((f) => {
    const a = safeRead(path.join(src, f));
    return a !== null && a !== safeRead(path.join(dst, f));
  });
}

/**
 * Autonomous mode keeps phases as tree snapshots instead of commits (commits wait for the human).
 *   gb snapshot                       → git add -A, git write-tree, prints SNAPSHOT <tree>
 *   gb snapshot checkout <tree> <dir> → a clean copy of the tree in <dir>, through a temporary index, so a reviewer
 *                                       can run gb verify --path <dir> while the maker keeps working in the repo
 */
function cmdSnapshot(argv) {
  const opts = parseArgs(argv.filter((a, i) => !(argv[0] === 'checkout' && (i === 0 || i === 1 || i === 2))));
  const repo = opts.path ? path.resolve(opts.path) : process.cwd();
  const git = (args, env = {}) => {
    const r = spawnSync('git', ['-C', repo, ...args], { encoding: 'utf8', env: { ...process.env, ...env } });
    if (r.status !== 0) throw new UserError(`git ${args.join(' ')}: ${(r.stderr || '').trim()}`);
    return r.stdout.trim();
  };
  if (argv[0] === 'checkout') {
    const [, tree, out] = argv;
    if (!tree || !out) throw new UserError('usage: gb snapshot checkout <tree> <dir>');
    const dir = path.resolve(out);
    fs.mkdirSync(dir, { recursive: true });
    const index = path.join(os.tmpdir(), `gb-snapshot-${process.pid}-${Date.now()}.idx`);
    try {
      git(['read-tree', tree], { GIT_INDEX_FILE: index });
      git(['checkout-index', '-a', `--prefix=${dir.replace(/\\/g, '/')}/`], { GIT_INDEX_FILE: index });
    } finally {
      fs.rmSync(index, { force: true });
    }
    process.stdout.write(`CHECKOUT ${tree} → ${dir}\nNext: node tools/gb/gb.js verify --path "${dir}"\n`);
    return 0;
  }
  git(['add', '-A']);
  const tree = git(['write-tree']);
  process.stdout.write(`SNAPSHOT ${tree}\n(staged, no commit — list it in STATUS.md; gb snapshot checkout ${tree} <dir> gives a clean copy)\n`);
  return 0;
}

function cmdToolsUpdate(opts) {
  if (!fs.existsSync(path.join(PLUGIN_ROOT, 'templates'))) throw new UserError('tools update runs from the plugin copy of gb: node <plugin>/tools/gb/gb.js tools update --path <game>');
  const dir = opts.path ? path.resolve(opts.path) : findProjectDir(process.cwd());
  if (!dir) throw new UserError('No project.godot found (pass --path).');
  const changed = toolsOutdated(dir);
  fs.mkdirSync(path.join(dir, 'tools', 'gb'), { recursive: true });
  for (const f of changed) fs.copyFileSync(path.join(HERE, f), path.join(dir, 'tools', 'gb', f));
  if (!fs.existsSync(path.join(dir, 'tools', 'gb', '.gdignore'))) fs.writeFileSync(path.join(dir, 'tools', 'gb', '.gdignore'), '');
  process.stdout.write(changed.length ? `UPDATED tools/gb: ${changed.join(', ')} (ignore-errors.txt untouched)\n` : 'tools/gb already matches the plugin\n');
  // The harness is framework too: a game scaffolded earlier must get new scenario helpers (e.g. note()).
  const harness = harnessOutdated(dir);
  for (const f of harness) fs.copyFileSync(path.join(PLUGIN_ROOT, 'templates', 'addons', 'gb_harness', f), path.join(dir, 'addons', 'gb_harness', f));
  if (harness.length) process.stdout.write(`UPDATED addons/gb_harness: ${harness.join(', ')}\n`);
  return 0;
}

const DOCTOR_FILES = [
  'project.godot', 'AGENTS.md', 'CLAUDE.md', 'README.md', 'STATUS.md', '.gitignore', '.gitattributes',
  '.ai/brief.md', '.ai/STATE.md', '.ai/lessons.md', '.ai/backlog.md', '.ai/specs/AGENTS.md',
  '.ai/specs/implemented', '.ai/specs/archived', '.ai/adr/template.md', '.ai/assets/REGISTER.md',
  '.ai/skills/spec-writing/SKILL.md', '.ai/checklists/testing.md', '.ai/checklists/playtest.md',
  '.ai/checklists/assets-and-licences.md', '.ai/checklists/release.md',
  'tools/gb/gb.js', 'tools/gb/lint.js', 'tools/gb/check_all.gd', 'tools/gb/imgdiff.gd', 'tools/gb/.gdignore',
  '.claude/settings.json', '.claude/hooks/session-start.sh', '.claude/hooks/guard-protected-paths.sh', '.claude/hooks/check-on-edit.sh',
  'addons/gb_harness/harness.gd', 'addons/gb_harness/scenario.gd', 'tests/scenarios', 'tests/replays',
  'export_presets.cfg', '.ai/perf-budget.json', '.github/workflows/verify.yml',
];

function cmdDoctor(opts) {
  const dir = opts.path ? path.resolve(opts.path) : findProjectDir(process.cwd());
  if (!dir) throw new UserError('No project.godot found (run inside the game repo or pass --path).');
  const lines = [];
  const ok = (m) => lines.push(`OK   ${m}`);
  const miss = (m) => lines.push(`MISS ${m}`);
  const warn = (m) => lines.push(`WARN ${m}`);

  for (const f of DOCTOR_FILES) (fs.existsSync(path.join(dir, f)) ? ok : miss)(f);
  if (!fs.existsSync(path.join(dir, '.ai', 'adr')) || !fs.readdirSync(path.join(dir, '.ai', 'adr')).some((f) => /^ADR-001/.test(f))) miss('.ai/adr/ADR-001-* (engine & setup decision)');
  else ok('.ai/adr/ADR-001-*');

  const agents = safeRead(path.join(dir, 'AGENTS.md'));
  if (agents !== null) (/Game-Builder-Version:\s*\d+\.\d+/.test(agents) ? ok : miss)('AGENTS.md stamped Game-Builder-Version');
  const claude = safeRead(path.join(dir, 'CLAUDE.md'));
  if (claude !== null) (/@AGENTS\.md/.test(claude) ? ok : miss)('CLAUDE.md → @AGENTS.md');
  const brief = safeRead(path.join(dir, '.ai', 'brief.md'));
  if (brief !== null) (/Decisions Ledger/i.test(brief) && !/AI-recommended-pending/i.test(brief) ? ok : miss)('.ai/brief.md has a Decisions Ledger with nothing AI-recommended-pending');
  const settings = safeRead(path.join(dir, '.claude', 'settings.json'));
  if (settings !== null) { try { JSON.parse(settings); ok('.claude/settings.json is valid JSON'); } catch { miss('.claude/settings.json is not valid JSON'); } }

  const pg = safeRead(path.join(dir, 'project.godot')) || '';
  (/^\s*move_left=/m.test(pg) && /^\s*jump=/m.test(pg) ? ok : warn)('input actions (move_*/jump/action/pause) in project.godot');
  (projectMainScene(pg) ? ok : miss)('run/main_scene set');
  (/^GbHarness="\*res:\/\/addons\/gb_harness\/harness\.gd"/m.test(pg) ? ok : miss)('GbHarness autoload registered');
  const tmpl = templatesDir(pickGodot(projectEngineVersion(pg)).version || '');
  for (const p of parsePresets(safeRead(path.join(dir, 'export_presets.cfg')))) {
    if (p.platform === 'Web' && !fs.existsSync(path.join(tmpl, 'web_nothreads_release.zip'))) warn(`export templates for Web not installed (${tmpl}) — Godot editor → Manage Export Templates`);
    if (p.platform === 'Windows Desktop' && !fs.readdirSync(fs.existsSync(tmpl) ? tmpl : dir).some((f) => /^windows_release/.test(f))) warn('export templates for Windows not installed');
  }

  const git = spawnSync('git', ['-C', dir, 'rev-list', '--count', 'HEAD'], { encoding: 'utf8' });
  const isRepo = spawnSync('git', ['-C', dir, 'rev-parse', '--git-dir'], { encoding: 'utf8' }).status === 0;
  const autonomous = /^\s*-\s*Process:\s*autonomous\b/m.test(agents || '');
  if (git.status === 0 && Number(git.stdout.trim()) > 0) ok(`git initialized, ${git.stdout.trim()} commit(s)`);
  // Autonomous mode: commits wait for the human's word at the end; phases keep `git write-tree` snapshots.
  else if (isRepo && autonomous) warn('git initialized, no commit yet (Process: autonomous: commits wait for the human; keep a git write-tree snapshot per phase in STATUS.md)');
  else miss('git initialized with at least one commit');

  const want = projectEngineVersion(pg);
  const g = pickGodot(want);
  if (!g.bin) miss('Godot binary found (set GODOT_BIN)');
  else (g.matches ? ok : warn)(`Godot ${g.version} ${g.matches ? 'matches' : 'does NOT match'} project engine ${want}`);

  const outdated = toolsOutdated(dir);
  if (outdated && outdated.length) warn(`tools/gb differs from the plugin (${outdated.join(', ')}) — node <plugin>/tools/gb/gb.js tools update --path .`);
  const staleHarness = harnessOutdated(dir);
  if (staleHarness.length) warn(`addons/gb_harness differs from the plugin (${staleHarness.join(', ')}) — node <plugin>/tools/gb/gb.js tools update --path .`);

  const fw = detectTestFramework(dir);
  (fw ? ok : warn)(`test framework ${fw || 'not installed yet (gb test → SKIP)'}`);

  const last = safeRead(path.join(dir, '.ai', 'verify', 'last.json'));
  if (!last) warn('no gb verify report yet — run: node tools/gb/gb.js verify');
  else {
    try {
      const r = JSON.parse(last);
      (r.result === 'PASS' ? ok : miss)(`last gb verify: ${r.result} at ${r.at}`);
    } catch {
      warn('unreadable .ai/verify/last.json');
    }
  }

  const missing = lines.filter((l) => l.startsWith('MISS')).length;
  process.stdout.write(lines.join('\n') + `\n${missing ? `NOT DONE — ${missing} MISS line(s)` : 'DONE — no MISS lines'} (presence + last verify; feel is judged by playing)\n`);
  return missing ? 1 : 0;
}

function safeRead(f) {
  try {
    return fs.readFileSync(f, 'utf8');
  } catch {
    return null;
  }
}

module.exports = { findProjectDir, projectEngineVersion, projectMainScene, candidateBinaries, parseGodotVersion, parseLog, detectTestFramework, findKnowledgeBase, findWiedza, kbVersionNote, exportBytes, versionFromName, wavPeakDb, TOOL_FILES };

if (require.main === module) {
  try {
    process.exitCode = main(process.argv.slice(2));
  } catch (e) {
    process.stderr.write(`gb: ${e instanceof UserError ? e.message : e.stack}\n`);
    process.exitCode = 2;
  }
}
