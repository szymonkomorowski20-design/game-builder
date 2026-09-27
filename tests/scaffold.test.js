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
  assert.match(pg, /window\/stretch\/scale_mode="integer"/);
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
  const router = fs.readFileSync(path.join(__dirname, '..', 'hooks', 'session-router.js'), 'utf8');
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
  // scaffold copies exactly the files `gb tools update` keeps current
  const copied = fs.readdirSync(path.join(o.dir, 'tools', 'gb')).filter((f) => !['.gdignore', 'ignore-errors.txt'].includes(f)).sort();
  assert.deepEqual(copied, [...require('../tools/gb/gb.js').TOOL_FILES].sort());
});

test('process weight: standard by default; --rigor light goes to AGENTS.md and ADR-001; other values rejected', () => {
  const o = opts();
  sc.scaffold(o);
  assert.match(fs.readFileSync(path.join(o.dir, 'AGENTS.md'), 'utf8'), /^- Process: standard\b/m);
  const l = opts(['--rigor', 'light']);
  sc.scaffold(l);
  assert.match(fs.readFileSync(path.join(l.dir, 'AGENTS.md'), 'utf8'), /^- Process: light\b/m);
  assert.match(fs.readFileSync(path.join(l.dir, '.ai', 'adr', 'ADR-001-engine-and-setup.md'), 'utf8'), /Process weight: light/);
  const a = opts(['--rigor', 'autonomous']);
  sc.scaffold(a);
  assert.match(fs.readFileSync(path.join(a.dir, 'AGENTS.md'), 'utf8'), /^- Process: autonomous\b/m);
  assert.throws(() => sc.parseScaffoldArgs(['--rigor', 'turbo']), /--rigor must be standard, light or autonomous/);
});

test('credits: CREDITS.md from the register; NC/unknown/proprietary licences and missing files fail', () => {
  const C = require('../tools/gb/credits.js');
  const reg = '| Path | Source | Author | Licence | Attribution needed | Added |\n|---|---|---|---|---|---|\n'
    + '| assets/audio/jump.wav | https://kenney.nl | Kenney | CC0-1.0 | no | 2026-09-26 |\n'
    + '| assets/music/theme.mp3 | mirror | Deceased Superior Technician | CC-BY | Music by DST (No Soap Radio), CC BY | 2026-09-26 |\n'
    + '| assets/audio/hit.wav | forum | ? | royalty free | | 2026-09-26 |\n'
    + '| assets/audio/boss.ogg | freesound | someone | CC-BY-NC-4.0 | x | 2026-09-26 |\n';
  const rows = C.parseRegister(reg);
  assert.equal(rows.length, 4);
  const d = tmp();
  for (const r of rows.slice(0, 3)) { fs.mkdirSync(path.dirname(path.join(d, r.path)), { recursive: true }); fs.writeFileSync(path.join(d, r.path), 'x'); }
  const problems = C.check(rows, d);
  assert.ok(problems.some((p) => /hit\.wav: no identifiable licence/.test(p)));
  assert.ok(problems.some((p) => /boss\.ogg: non-commercial/.test(p)));
  assert.ok(problems.some((p) => /boss\.ogg: listed in the register but not found/.test(p)));
  assert.ok(!problems.some((p) => /jump\.wav|theme\.mp3/.test(p)));
  const md = C.render(rows, 'Test');
  assert.match(md, /Deceased Superior Technician\*\* — CC-BY/);
  assert.match(md, /Music by DST \(No Soap Radio\), CC BY/);
});

test('adopt mode never generates game files', () => {
  const o = opts(['--adopt']);
  fs.writeFileSync(path.join(o.dir, 'project.godot'), 'config_version=5\n');
  const report = sc.scaffold(o);
  assert.ok(!report.some((l) => /scenes\/main\.tscn|scripts\/main\.gd|autoload\/events\.gd/.test(l)));
  assert.ok(report.includes('CREATED AGENTS.md'));
  assert.equal(fs.readFileSync(path.join(o.dir, 'project.godot'), 'utf8'), 'config_version=5\n');
});

test('adopt mode documents the project as it is and generates tests that pass on it', () => {
  const dir = tmp();
  fs.writeFileSync(path.join(dir, 'project.godot'), 'config_version=5\n\n[application]\nconfig/name="Old"\n');
  const o = sc.parseScaffoldArgs(['--dir', dir, '--name', 'Old', '--engine', '4.7', '--adopt']);
  assert.equal(o.renderer, 'forward_plus'); // no [rendering] section → Godot's default, not the 2D new-project default
  assert.deepEqual([o.width, o.height], [1152, 648]);
  sc.scaffold(o);
  const adr = fs.readFileSync(path.join(dir, '.ai', 'adr', 'ADR-001-engine-and-setup.md'), 'utf8');
  assert.match(adr, /Forward Plus/);
  assert.match(adr, /1152×648/);
  assert.match(adr, /not detected/);
  assert.match(adr, /Read from the existing project\.godot/);
  const example = fs.readFileSync(path.join(dir, 'tests', 'unit', 'test_example.gd'), 'utf8');
  assert.doesNotMatch(example, /Events/); // adoption adds no Events autoload, so the example must not expect one
  assert.match(example, /func test_harness_is_inert_in_normal_runs/);
  assert.ok(fs.existsSync(path.join(dir, 'tests', 'baselines', '.gdignore')));

  const withEvents = tmp();
  fs.writeFileSync(path.join(withEvents, 'project.godot'), 'config_version=5\n\n[autoload]\n\nEvents="*res://events.gd"\n\n[rendering]\n\nrenderer/rendering_method="gl_compatibility"\ntextures/canvas_textures/default_texture_filter=0\n\n[display]\n\nwindow/size/viewport_width=384\nwindow/size/viewport_height=216\n');
  const o2 = sc.parseScaffoldArgs(['--dir', withEvents, '--engine', '4.7', '--adopt', '--dim', '2d']);
  assert.equal(o2.renderer, 'gl_compatibility');
  assert.deepEqual([o2.width, o2.height, o2.pixelArt], [384, 216, true]);
  sc.scaffold(o2);
  assert.match(fs.readFileSync(path.join(withEvents, 'tests', 'unit', 'test_example.gd'), 'utf8'), /test_events_autoload_exists/);
  assert.match(fs.readFileSync(path.join(withEvents, '.ai', 'adr', 'ADR-001-engine-and-setup.md'), 'utf8'), /Dimension: 2D/);
});

test('tools update refreshes framework files only and keeps ignore-errors.txt', () => {
  const o = opts();
  sc.scaffold(o);
  fs.writeFileSync(path.join(o.dir, 'tools', 'gb', 'gb.js'), '// old');
  fs.writeFileSync(path.join(o.dir, 'tools', 'gb', 'ignore-errors.txt'), '# mine\nfoo\n');
  fs.writeFileSync(path.join(o.dir, 'addons', 'gb_harness', 'scenario.gd'), '# old harness');
  const r = spawnSync(process.execPath, [GB, 'tools', 'update', '--path', o.dir], { encoding: 'utf8' });
  assert.equal(r.status, 0, r.stderr);
  assert.match(r.stdout, /UPDATED tools\/gb: gb\.js/);
  assert.match(r.stdout, /UPDATED addons\/gb_harness: scenario\.gd/, 'the harness is framework too');
  assert.equal(fs.readFileSync(path.join(o.dir, 'addons', 'gb_harness', 'scenario.gd'), 'utf8'),
    fs.readFileSync(path.join(__dirname, '..', 'templates', 'addons', 'gb_harness', 'scenario.gd'), 'utf8'));
  assert.equal(fs.readFileSync(path.join(o.dir, 'tools', 'gb', 'gb.js'), 'utf8'), fs.readFileSync(GB, 'utf8'));
  assert.equal(fs.readFileSync(path.join(o.dir, 'tools', 'gb', 'ignore-errors.txt'), 'utf8'), '# mine\nfoo\n');
  const again = spawnSync(process.execPath, [GB, 'tools', 'update', '--path', o.dir], { encoding: 'utf8' });
  assert.match(again.stdout, /already matches/);
});

test('templates: "recipes" in template.json are added with their dependencies and tests, from the plugin (no copies in the template)', () => {
  const tdir = path.join(__dirname, '..', 'templates', 'games', 'zz-recipe-probe');
  fs.mkdirSync(path.join(tdir, 'scenes'), { recursive: true });
  fs.writeFileSync(path.join(tdir, 'template.json'), JSON.stringify({ name: 'zz-recipe-probe', description: 'test only', dim: '2d', main_scene: 'res://scenes/main.tscn', tests: 'gut', recipes: ['06'] }));
  fs.writeFileSync(path.join(tdir, 'scenes', 'main.tscn'), '[gd_scene format=3]\n\n[node name="Main" type="Node2D"]\n');
  try {
    const o = sc.parseScaffoldArgs(['--dir', tmp(), '--template', 'zz-recipe-probe', '--engine', '4.7']);
    const report = sc.scaffold(o);
    assert.ok(fs.existsSync(path.join(o.dir, 'recipes', '06-hitbox-hurtbox', 'hitbox.gd')), 'the recipe itself');
    assert.ok(fs.existsSync(path.join(o.dir, 'recipes', '05-health', 'health.gd')), 'its dependency (Health)');
    assert.ok(fs.readdirSync(path.join(o.dir, 'tests', 'scenarios')).some((f) => f.startsWith('r06_')), 'its scenario');
    assert.ok(fs.readdirSync(path.join(o.dir, 'tests', 'unit')).some((f) => f.startsWith('test_r05_')), 'the dependency\'s unit test');
    assert.ok(report.some((l) => /RECIPES .*05-health.*06-hitbox-hurtbox/.test(l)), report.join('\n'));
  } finally {
    fs.rmSync(tdir, { recursive: true, force: true });
  }
});

test('templates: platformer-2d is listed; an unknown template is rejected with the list', () => {
  assert.ok(sc.listTemplates().includes('platformer-2d'));
  assert.ok(sc.listTemplates().includes('topdown-2d'));
  assert.ok(sc.listTemplates().includes('grid-puzzle-2d'));
  assert.ok(sc.listTemplates().includes('cards-2d'));
  assert.throws(() => sc.parseScaffoldArgs(['--template', 'mmo']), /unknown template "mmo".*platformer-2d/);
  const o = sc.parseScaffoldArgs(['--dir', tmp(), '--template', 'platformer-2d', '--engine', '4.7']);
  assert.equal(o.dim, '2d');
  assert.deepEqual([o.width, o.height], [640, 360]);
  const report = sc.scaffold(o);
  assert.ok(!report.some((l) => /scenes\/main\.tscn|scripts\/main\.gd/.test(l)), 'no placeholder main scene');
  assert.match(fs.readFileSync(path.join(o.dir, 'project.godot'), 'utf8'), /run\/main_scene="res:\/\/scenes\/level\/level_1\.tscn"/);
  assert.ok(fs.existsSync(path.join(o.dir, '.ai', 'specs', 'implemented', 'template-platformer-2d.md')));
  assert.ok(!fs.existsSync(path.join(o.dir, 'template.json')));
});

// ---- recipes (gb recipe) ----
const R = require('../tools/gb/recipe.js');
const RECIPES = path.join(__dirname, '..', 'recipes');

test('recipes: dependencies come from class_name use; add resolves them first', () => {
  const info = R.catalog(RECIPES);
  assert.deepEqual(info['23-hud'].deps, ['05-health', '11-shop']);
  assert.deepEqual(info['10-crafting'].deps, ['09-inventory']);
  const order = R.resolve(info, ['23']);
  assert.ok(order.indexOf('09-inventory') < order.indexOf('11-shop') && order.indexOf('11-shop') < order.indexOf('23-hud'));
  assert.throws(() => R.resolve(info, ['99']), /unknown recipe/);
});

test('recipes: a node NAME in a scene or an inner enum with a class_name\'s spelling is not a dependency', () => {
  const info = R.catalog(RECIPES);
  assert.ok(!info['47-melee-combo'].deps.includes('06-hitbox-hurtbox'), `47 deps: ${info['47-melee-combo'].deps}`);
  assert.ok(!info['51-boss-phases'].deps.includes('14-state-machine'), `51 deps: ${info['51-boss-phases'].deps}`);
  assert.ok(info['50-run-meta'].deps.includes('48-boons-modifiers'), 'a real use (StatSheet) still counts');
  assert.ok(info['52-status-effects'].deps.includes('48-boons-modifiers'), 'StatModifier/StatSheet');
});

test('recipes: every recipe has a README and at least one test', () => {
  for (const d of Object.keys(R.catalog(RECIPES))) {
    assert.ok(fs.existsSync(path.join(RECIPES, d, 'README.md')), `${d} README`);
    const nn = d.slice(0, 2);
    const tests = [...fs.readdirSync(path.join(RECIPES, 'tests', 'unit')), ...fs.readdirSync(path.join(RECIPES, 'tests', 'scenarios'))].filter((f) => f.startsWith(`test_r${nn}_`) || f.startsWith(`r${nn}_`));
    assert.ok(tests.length > 0, `${d} has no test`);
  }
});

test('recipes: add rewrites res:// paths into recipes/, copies tests, never overwrites', () => {
  const game = tmp();
  fs.writeFileSync(path.join(game, 'project.godot'), 'config_version=5\n');
  const r = R.add(RECIPES, game, ['06']);
  assert.deepEqual(r.recipes, ['05-health', '06-hitbox-hurtbox']);
  const arena = fs.readFileSync(path.join(game, 'recipes', '06-hitbox-hurtbox', 'arena.tscn'), 'utf8');
  assert.match(arena, /res:\/\/recipes\/06-hitbox-hurtbox\/hitbox\.gd/);
  assert.match(arena, /res:\/\/recipes\/05-health\/health\.gd/);
  assert.doesNotMatch(arena, /"res:\/\/0\d-/);
  assert.ok(fs.existsSync(path.join(game, 'tests', 'scenarios', 'r06_hitbox_hurtbox.gd')));
  assert.ok(fs.existsSync(path.join(game, 'tests', 'unit', 'test_r05_health.gd')));
  fs.writeFileSync(path.join(game, 'recipes', '05-health', 'health.gd'), '# mine');
  const again = R.add(RECIPES, game, ['05']);
  assert.equal(again.added.length, 0);
  assert.equal(fs.readFileSync(path.join(game, 'recipes', '05-health', 'health.gd'), 'utf8'), '# mine');
});

// ---- end-to-end with the real engine ----
const haveGodot = spawnSync(process.execPath, [GB, 'godot', '--path', path.join(__dirname, 'fixtures', 'ok')], { encoding: 'utf8' }).status !== 2;
const skip = haveGodot ? false : 'no Godot binary found — e2e skipped';

test('e2e: cards-2d template passes its own scenarios and unit tests out of the box', { skip, timeout: 900000 }, () => {
  const dir = path.join(tmp(), 'cd');
  const s = spawnSync(process.execPath, [GB, 'scaffold', '--dir', dir, '--name', 'CD', '--template', 'cards-2d'], { encoding: 'utf8', timeout: 600000 });
  assert.equal(s.status, 0, s.stdout + s.stderr);
  const v = spawnSync(process.execPath, [GB, 'verify', '--path', dir], { encoding: 'utf8', timeout: 600000 });
  assert.equal(v.status, 0, v.stdout);
  assert.match(v.stdout, /PASS scenarios \(5\/5 passing\)/);
  assert.match(v.stdout, /PASS test \(gut: 11\/11 passing\)/);
});

test('e2e: grid-puzzle-2d template passes its own scenarios and unit tests out of the box', { skip, timeout: 900000 }, () => {
  const dir = path.join(tmp(), 'gp');
  const s = spawnSync(process.execPath, [GB, 'scaffold', '--dir', dir, '--name', 'GP', '--template', 'grid-puzzle-2d'], { encoding: 'utf8', timeout: 600000 });
  assert.equal(s.status, 0, s.stdout + s.stderr);
  const v = spawnSync(process.execPath, [GB, 'verify', '--path', dir], { encoding: 'utf8', timeout: 600000 });
  assert.equal(v.status, 0, v.stdout);
  assert.match(v.stdout, /PASS scenarios \(5\/5 passing\)/);
  assert.match(v.stdout, /PASS test \(gut: 6\/6 passing\)/);
});

test('e2e: topdown-2d template passes its own scenarios and unit tests out of the box', { skip, timeout: 900000 }, () => {
  const dir = path.join(tmp(), 'td');
  const s = spawnSync(process.execPath, [GB, 'scaffold', '--dir', dir, '--name', 'TD', '--template', 'topdown-2d'], { encoding: 'utf8', timeout: 600000 });
  assert.equal(s.status, 0, s.stdout + s.stderr);
  const v = spawnSync(process.execPath, [GB, 'verify', '--path', dir], { encoding: 'utf8', timeout: 600000 });
  assert.equal(v.status, 0, v.stdout);
  assert.match(v.stdout, /PASS scenarios \(9\/9 passing\)/);
  assert.match(v.stdout, /PASS test \(gut: 5\/5 passing\)/);
});

test('e2e: platformer-2d template passes its own 9 scenarios and unit tests out of the box', { skip, timeout: 900000 }, () => {
  const dir = path.join(tmp(), 'plat');
  const s = spawnSync(process.execPath, [GB, 'scaffold', '--dir', dir, '--name', 'Plat', '--template', 'platformer-2d'], { encoding: 'utf8', timeout: 600000 });
  assert.equal(s.status, 0, s.stdout + s.stderr);
  assert.match(s.stdout, /IMPORT {2}ok/);
  const v = spawnSync(process.execPath, [GB, 'verify', '--path', dir], { encoding: 'utf8', timeout: 600000 });
  assert.equal(v.status, 0, v.stdout);
  assert.match(v.stdout, /PASS scenarios \(9\/9 passing\)/);
  assert.match(v.stdout, /PASS test \(gut: 5\/5 passing\)/);
});

test('e2e: platformer-3d template passes its own 8 scenarios and unit tests out of the box (Forward+, Jolt)', { skip, timeout: 900000 }, () => {
  const dir = path.join(tmp(), 'p3d');
  const s = spawnSync(process.execPath, [GB, 'scaffold', '--dir', dir, '--name', 'P3D', '--template', 'platformer-3d'], { encoding: 'utf8', timeout: 600000 });
  assert.equal(s.status, 0, s.stdout + s.stderr);
  assert.match(s.stdout, /IMPORT {2}ok/);
  assert.match(fs.readFileSync(path.join(dir, 'project.godot'), 'utf8'), /config\/features=PackedStringArray\("4\.\d+", "Forward Plus"\)/);
  const v = spawnSync(process.execPath, [GB, 'verify', '--path', dir], { encoding: 'utf8', timeout: 600000 });
  assert.equal(v.status, 0, v.stdout);
  assert.match(v.stdout, /PASS scenarios \(8\/8 passing\)/);
  assert.match(v.stdout, /PASS test \(gut: 5\/5 passing\)/);
});

test('e2e: action-roguelite-3d template gets its recipes and actions, and passes every scenario (a bot wins the run) out of the box', { skip, timeout: 1200000 }, () => {
  const dir = path.join(tmp(), 'rogue');
  const s = spawnSync(process.execPath, [GB, 'scaffold', '--dir', dir, '--name', 'Rogue', '--template', 'action-roguelite-3d'], { encoding: 'utf8', timeout: 600000 });
  assert.equal(s.status, 0, s.stdout + s.stderr);
  assert.match(s.stdout, /RECIPES 05-health, 13-save-load, 43-dash-knockback, 47-melee-combo, 48-boons-modifiers, 49-encounter-director, 50-run-meta, 51-boss-phases, 52-status-effects/);
  const pg = fs.readFileSync(path.join(dir, 'project.godot'), 'utf8');
  assert.match(pg, /^attack=\{/m);
  assert.match(pg, /^dash=\{/m);
  const v = spawnSync(process.execPath, [GB, 'verify', '--path', dir], { encoding: 'utf8', timeout: 900000 });
  assert.equal(v.status, 0, v.stdout);
  const sc = /PASS scenarios \((\d+)\/(\d+) passing\)/.exec(v.stdout);
  assert.ok(sc && sc[1] === sc[2] && Number(sc[1]) >= 14, v.stdout);
  assert.match(v.stdout, /PASS test \(gut: (\d+)\/\1 passing\)/);
});

test('e2e: fps-3d template adds its own input actions (shoot on the mouse) and passes its scenarios out of the box', { skip, timeout: 900000 }, () => {
  const dir = path.join(tmp(), 'fps');
  const s = spawnSync(process.execPath, [GB, 'scaffold', '--dir', dir, '--name', 'FPS', '--template', 'fps-3d'], { encoding: 'utf8', timeout: 600000 });
  assert.equal(s.status, 0, s.stdout + s.stderr);
  assert.match(s.stdout, /INPUT {3}12 action\(s\) added via Godot/);
  const pg = fs.readFileSync(path.join(dir, 'project.godot'), 'utf8');
  assert.match(pg, /^shoot=\{[\s\S]*?InputEventMouseButton[\s\S]*?"button_index":1/m, 'shoot is on the left mouse button');
  assert.match(pg, /^look_right=\{/m);
  const v = spawnSync(process.execPath, [GB, 'verify', '--path', dir], { encoding: 'utf8', timeout: 600000 });
  assert.equal(v.status, 0, v.stdout);
  assert.match(v.stdout, /PASS scenarios \(7\/7 passing\)/);
  assert.match(v.stdout, /PASS test \(gut: 6\/6 passing\)/);
});

test('e2e: recipes copied into a fresh game (with dependencies) pass gb verify there', { skip, timeout: 900000 }, () => {
  const dir = path.join(tmp(), 'rg');
  const s = spawnSync(process.execPath, [GB, 'scaffold', '--dir', dir, '--name', 'RG', '--dim', '2d'], { encoding: 'utf8', timeout: 600000 });
  assert.equal(s.status, 0, s.stdout + s.stderr);
  const a = spawnSync(process.execPath, [GB, 'recipe', 'add', '23', '13', '35', '24', '--path', dir], { encoding: 'utf8' });
  assert.equal(a.status, 0, a.stdout + a.stderr);
  assert.match(a.stdout, /Recipes: 05-health, 09-inventory, 11-shop, 23-hud, 13-save-load, 35-sfx-variants, 24-enemy-ai/);
  const v = spawnSync(process.execPath, [GB, 'verify', '--path', dir], { encoding: 'utf8', timeout: 600000 });
  assert.equal(v.status, 0, v.stdout);
  assert.match(v.stdout, /PASS scenarios \(3\/3 passing\)/);
});

test('e2e: scaffold → brief → git commit → doctor DONE → verify PASS', { skip, timeout: 900000 }, () => {
  const dir = path.join(tmp(), 'game');
  const run = (args, cwd = dir) => spawnSync(process.execPath, [GB, ...args], { cwd, encoding: 'utf8', timeout: 600000 });
  const s = run(['scaffold', '--dir', dir, '--name', 'E2E', '--dim', '2d', '--pixel-art'], os.tmpdir());
  assert.equal(s.status, 0, s.stdout + s.stderr);
  assert.match(s.stdout, /INPUT {3}7 action\(s\) added via Godot/);

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
