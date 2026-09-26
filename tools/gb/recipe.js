'use strict';

// gb recipe list | add <NN|name…> — copies tested recipes from the plugin into a game, with their tests.
// Plugin copy only (the recipes live next to tools/gb in the plugin, not in game repos).
//   recipes/NN-name/*           → <game>/recipes/NN-name/*        (res://NN-name/ rewritten to res://recipes/NN-name/)
//   recipes/tests/unit/test_rNN_*.gd      → <game>/tests/unit/
//   recipes/tests/scenarios/rNN_*.gd      → <game>/tests/scenarios/
// Dependencies (a recipe using another recipe's class_name) are added automatically. Never overwrites.

const fs = require('fs');
const path = require('path');

const walk = (d) => fs.existsSync(d) ? fs.readdirSync(d, { withFileTypes: true }).flatMap((f) => f.isDirectory() ? walk(path.join(d, f.name)) : [path.join(d, f.name)]) : [];
const COPY_EXT = /\.(gd|tscn|tres|gdshader|json|csv|md)$/i;

function recipeDirs(root) {
  return fs.readdirSync(root, { withFileTypes: true }).filter((d) => d.isDirectory() && /^\d\d-/.test(d.name)).map((d) => d.name).sort();
}

function testsFor(root, dir) {
  const nn = dir.slice(0, 2);
  const unit = walk(path.join(root, 'tests', 'unit')).filter((f) => path.basename(f).startsWith(`test_r${nn}_`) && f.endsWith('.gd'));
  const scen = walk(path.join(root, 'tests', 'scenarios')).filter((f) => path.basename(f).startsWith(`r${nn}_`) && f.endsWith('.gd'));
  return [...unit, ...scen];
}

/** Map of recipe dir → { title, classes defined, recipes it depends on }. */
function catalog(root) {
  const dirs = recipeDirs(root);
  const info = {};
  const owner = {};
  for (const d of dirs) {
    const files = walk(path.join(root, d)).filter((f) => f.endsWith('.gd'));
    const classes = [];
    for (const f of files) {
      const m = /^class_name\s+(\w+)/m.exec(fs.readFileSync(f, 'utf8'));
      if (m) { classes.push(m[1]); owner[m[1]] = d; }
    }
    const readme = path.join(root, d, 'README.md');
    const title = fs.existsSync(readme) ? fs.readFileSync(readme, 'utf8').split('\n')[0].replace(/^#\s*\d+\s*[—-]\s*/, '') : d;
    info[d] = { title, classes, deps: [] };
  }
  for (const d of dirs) {
    const text = [...walk(path.join(root, d)).filter((f) => /\.(gd|tscn)$/.test(f)), ...testsFor(root, d)].map((f) => fs.readFileSync(f, 'utf8')).join('\n');
    const deps = new Set();
    for (const [cls, o] of Object.entries(owner)) if (o !== d && new RegExp(`\\b${cls}\\b`).test(text)) deps.add(o);
    for (const m of text.matchAll(/res:\/\/(\d\d-[\w-]+)\//g)) if (m[1] !== d && info[m[1]]) deps.add(m[1]);
    info[d].deps = [...deps].sort();
  }
  return info;
}

function resolve(info, wanted) {
  const dirs = Object.keys(info);
  const pick = (w) => dirs.find((d) => d === w || d.slice(0, 2) === String(w).padStart(2, '0') || d.slice(3) === w);
  const out = [];
  const visit = (d) => { if (out.includes(d)) return; for (const x of info[d].deps) visit(x); out.push(d); };
  for (const w of wanted) {
    const d = pick(w);
    if (!d) throw new Error(`unknown recipe "${w}" — see gb recipe list`);
    visit(d);
  }
  return out;
}

const rewrite = (text, dirs) => dirs.reduce((t, d) => t.split(`res://${d}/`).join(`res://recipes/${d}/`), text);

/** Copies recipes (+deps, +tests) into a game. Returns { added, skipped } lists of relative paths. */
function add(root, game, wanted) {
  const info = catalog(root);
  const dirs = resolve(info, wanted);
  const all = Object.keys(info);
  const added = [], skipped = [];
  const put = (src, rel) => {
    const dst = path.join(game, rel);
    if (fs.existsSync(dst)) { skipped.push(rel); return; }
    fs.mkdirSync(path.dirname(dst), { recursive: true });
    const body = fs.readFileSync(src);
    fs.writeFileSync(dst, /\.(gd|tscn|tres)$/.test(src) ? rewrite(body.toString('utf8'), all) : body);
    added.push(rel);
  };
  for (const d of dirs) {
    for (const f of walk(path.join(root, d)).filter((x) => COPY_EXT.test(x))) put(f, path.join('recipes', d, path.relative(path.join(root, d), f)).split(path.sep).join('/'));
    for (const t of testsFor(root, d)) put(t, path.join('tests', path.basename(path.dirname(t)), path.basename(t)).split(path.sep).join('/'));
  }
  return { recipes: dirs, added, skipped };
}

module.exports = { catalog, resolve, add, rewrite };
