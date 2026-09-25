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
 *   assets <query...> [--typ audio|model_3d|animation|animation_clip|sprite_2d|ui_skin]
 * Common options: --path <project dir> (default: nearest dir with project.godot) · --json
 */

const fs = require('fs');
const path = require('path');
const os = require('os');
const { spawnSync } = require('child_process');

const USAGE = `Usage: node tools/gb/gb.js <command> [options]
  godot                    locate Godot; print version and whether it matches the project
  import                   headless import of all resources (fresh clone / new assets)
  check                    load every .gd in one boot; fail on any parse/compile error
  run [--frames N] [--scene res://x.tscn]   run headless for N frames; fail on log errors
  test                     run GUT or gdUnit4 if installed (skip if neither)
  verify                   import -> check -> run -> test; writes .ai/verify/last.json
  kb <query...>            search the gry-wiedza knowledge base (BAZA-AI)
  assets <query...> [--typ audio|model_3d|animation|animation_clip|sprite_2d|ui_skin]
Options: --path <project dir> (default: nearest dir with project.godot) · --json
Env: GODOT_BIN (Godot executable; on Windows prefer *_console.exe) · GAME_BUILDER_KB (BAZA-AI folder)
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

function stepImport(ctx) {
  const r = runGodot(ctx.bin, ['--headless', '--path', ctx.dir, '--import'], ctx.dir, ctx.timeouts.import);
  return stepResult('import', r, {}, ctx.ignores);
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

function stepTest(ctx) {
  const fw = detectTestFramework(ctx.dir);
  if (!fw) return { step: 'test', status: 'skip', reasons: ['no test framework installed (addons/gut or addons/gdUnit4)'], ms: 0, errors: [], warnings: [] };
  const args = fw === 'gut'
    ? ['--headless', '--path', ctx.dir, '-s', 'res://addons/gut/gut_cmdln.gd', '-gdir=res://tests', '-ginclude_subdirs', '-gexit']
    : ['--headless', '--path', ctx.dir, '-s', 'res://addons/gdUnit4/bin/GdUnitCmdTool.gd', '-a', 'res://tests', '--ignoreHeadlessMode'];
  const r = runGodot(ctx.bin, args, ctx.dir, ctx.timeouts.test);
  const res = stepResult('test', r, { framework: fw }, ctx.ignores);
  return res;
}

// ---------------------------------------------------------------------------------------------
// Knowledge base (gry-wiedza BAZA-AI)
// ---------------------------------------------------------------------------------------------

function findKnowledgeBase({ env = process.env, home = os.homedir() } = {}) {
  const c = [env.GAME_BUILDER_KB, path.join(home, 'Desktop', 'gry-wiedza', 'BAZA-AI'), path.join(home, 'gry-wiedza', 'BAZA-AI')].filter(Boolean);
  return c.find((d) => fs.existsSync(path.join(d, 'dla-ai', 'szukaj.mjs'))) || null;
}

function kbSearch(args) {
  const kb = findKnowledgeBase();
  if (!kb) {
    process.stderr.write('Knowledge base not found. Set GAME_BUILDER_KB to the BAZA-AI folder (gry-wiedza).\n');
    return 3;
  }
  const r = spawnSync(process.execPath, [path.join(kb, 'dla-ai', 'szukaj.mjs'), ...args], { cwd: kb, encoding: 'utf8', env: { ...process.env, NODE_NO_WARNINGS: '1' }, maxBuffer: 64 * 1024 * 1024 });
  process.stdout.write(r.stdout || '');
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
    else if (a === '--scene') opts.scene = argv[++i];
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
    timeouts: { import: 300000, check: 180000, run: 180000, test: 900000 },
  };
}

class UserError extends Error {}

function printStep(s) {
  const tag = s.status === 'ok' ? 'PASS' : s.status === 'skip' ? 'SKIP' : 'FAIL';
  const extra = s.step === 'check' && s.files != null ? ` (${s.files} scripts)` : s.step === 'run' ? ` (${s.frames} frames, ${s.scene || 'main scene'})` : s.framework ? ` (${s.framework})` : '';
  process.stdout.write(`${tag} ${s.step}${extra} — ${s.ms} ms${s.reasons.length ? ' — ' + s.reasons.join('; ') : ''}\n`);
  for (const e of s.errors.slice(0, 10)) process.stdout.write(`     ${e.kind}: ${e.message}${e.at ? `  [${e.at}]` : ''}\n`);
  if (s.errors.length > 10) process.stdout.write(`     … ${s.errors.length - 10} more\n`);
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

function main(argv) {
  // kb/assets pass their flags straight through to the knowledge-base search.
  if (argv[0] === 'kb') return kbSearch(argv.slice(1));
  if (argv[0] === 'assets') return kbSearch(['--assety', ...argv.slice(1)]);
  if (argv[0] === 'scaffold') return cmdScaffold(argv.slice(1));
  if (argv[0] === 'doctor') return cmdDoctor(parseArgs(argv.slice(1)));
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

  let steps;
  if (cmd === 'import') steps = [stepImport(ctx)];
  else if (cmd === 'check') steps = [stepCheck(ctx)];
  else if (cmd === 'run') steps = [stepRun(ctx, opts.frames || 120, opts.scene)];
  else if (cmd === 'test') steps = [stepTest(ctx)];
  else if (cmd === 'verify') {
    steps = [stepImport(ctx)];
    // A parse error surfaces during import already; still run check so the report names every
    // broken script, not just the first scene that tripped over one. Only an import that could
    // not run at all (no binary, timeout) stops here.
    const imp = steps[0];
    if (imp.status === 'ok' || !imp.reasons.some((r) => /could not start|timed out/.test(r))) steps.push(stepCheck(ctx));
    if (steps.every((s) => s.status !== 'fail')) steps.push(stepRun(ctx, opts.frames || 120, opts.scene));
    if (steps.every((s) => s.status !== 'fail')) steps.push(stepTest(ctx));
  } else {
    throw new UserError(`Unknown command: ${cmd}`);
  }

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
  fs.mkdirSync(o.dir, { recursive: true });
  const runner = g.bin ? (args) => runGodot(g.bin, args, o.dir, 180000).log : null;
  const report = sc.scaffold(o, { runGodot: runner, dryRun: o.dryRun });
  process.stdout.write(report.join('\n') + '\n');
  if (!g.bin) process.stdout.write('WARN    Godot not found — input actions not added; set GODOT_BIN and run: godot --headless --path . --script tools/gb/setup_input.gd\n');
  if (!o.dryRun && g.bin) {
    const imp = runGodot(g.bin, ['--headless', '--path', o.dir, '--import'], o.dir, 300000);
    process.stdout.write(`IMPORT  ${imp.code === 0 && !parseLog(imp.log).errors.length ? 'ok' : 'had errors — run gb verify'} (Godot ${g.version})\n`);
  }
  process.stdout.write(`\nNext: write .ai/brief.md, git init + first commit, then: node tools/gb/gb.js doctor && node tools/gb/gb.js verify\n`);
  return report.some((l) => l.startsWith('FAIL')) ? 1 : 0;
}

const DOCTOR_FILES = [
  'project.godot', 'AGENTS.md', 'CLAUDE.md', 'README.md', 'STATUS.md', '.gitignore', '.gitattributes',
  '.ai/brief.md', '.ai/STATE.md', '.ai/lessons.md', '.ai/backlog.md', '.ai/specs/AGENTS.md',
  '.ai/specs/implemented', '.ai/specs/archived', '.ai/adr/template.md', '.ai/assets/REGISTER.md',
  '.ai/skills/spec-writing/SKILL.md', '.ai/checklists/testing.md', '.ai/checklists/playtest.md',
  '.ai/checklists/assets-and-licences.md', '.ai/checklists/release.md',
  'tools/gb/gb.js', 'tools/gb/check_all.gd', 'tools/gb/.gdignore',
  '.claude/settings.json', '.claude/hooks/session-start.sh', '.claude/hooks/guard-protected-paths.sh',
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

  const git = spawnSync('git', ['-C', dir, 'rev-list', '--count', 'HEAD'], { encoding: 'utf8' });
  if (git.status === 0 && Number(git.stdout.trim()) > 0) ok(`git initialized, ${git.stdout.trim()} commit(s)`);
  else miss('git initialized with at least one commit');

  const want = projectEngineVersion(pg);
  const g = pickGodot(want);
  if (!g.bin) miss('Godot binary found (set GODOT_BIN)');
  else (g.matches ? ok : warn)(`Godot ${g.version} ${g.matches ? 'matches' : 'does NOT match'} project engine ${want}`);

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

module.exports = { findProjectDir, projectEngineVersion, projectMainScene, candidateBinaries, parseGodotVersion, parseLog, detectTestFramework, findKnowledgeBase, versionFromName };

if (require.main === module) {
  try {
    process.exitCode = main(process.argv.slice(2));
  } catch (e) {
    process.stderr.write(`gb: ${e instanceof UserError ? e.message : e.stack}\n`);
    process.exitCode = 2;
  }
}
