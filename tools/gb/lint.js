'use strict';

/**
 * gb lint — static checks a Godot 4 project can fail without the engine noticing at import time.
 *
 * ERROR (fails verify):  broken res:// references · Godot 3 APIs in GDScript · assets not in the
 *                        licence register · harness autoload missing
 * WARN  (reported):      unreferenced assets · textures larger than 4096 px on a side
 *
 * Pure Node, no engine boot, so it runs in milliseconds and inside a PostToolUse hook.
 */

const fs = require('fs');
const path = require('path');

const ASSET_EXT = /\.(png|jpe?g|webp|svg|bmp|tga|exr|hdr|wav|ogg|mp3|glb|gltf|fbx|obj|blend|dae|ttf|otf|woff2?)$/i;
const TEXT_EXT = /\.(gd|tscn|tres|godot|cfg|gdshader|json)$/i;

// Godot 3 → 4 renames that parse fine in a comment but break (or silently mislead) in code.
const GODOT3 = [
  [/\bKinematicBody(2D)?\b/, 'KinematicBody → CharacterBody2D/3D'],
  [/\bSpatial\b(?!Material)/, 'Spatial → Node3D'],
  [/\byield\s*\(/, 'yield(...) → await'],
  [/^\s*onready\s+var\b/m, 'onready var → @onready var'],
  [/^\s*export(\s*\(|\s+var)\b/m, 'export var → @export var'],
  [/\bsetget\b/, 'setget → property set/get syntax'],
  [/\.instance\(\)/, '.instance() → .instantiate()'],
  [/move_and_slide\s*\(\s*[^)\s]/, 'move_and_slide(velocity, ...) → set velocity, call move_and_slide()'],
  [/\bPool(String|Int|Real|Vector2|Vector3|Color|Byte)Array\b/, 'PoolXArray → PackedXArray'],
  [/\brand_range\s*\(/, 'rand_range → randf_range'],
  [/\b(deg2rad|rad2deg)\s*\(/, 'deg2rad/rad2deg → deg_to_rad/rad_to_deg'],
  [/\bconnect\s*\(\s*"[^"]+"\s*,\s*self\s*,/, 'connect("sig", self, "method") → signal.connect(method)'],
  [/\bget_tree\(\)\.change_scene\s*\(/, 'change_scene → change_scene_to_file'],
  [/\bOS\.get_ticks_msec\b/, 'OS.get_ticks_msec → Time.get_ticks_msec'],
];

function walk(dir, root, out = []) {
  let entries;
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch {
    return out;
  }
  if (entries.some((e) => e.name === '.gdignore')) return out;
  for (const e of entries) {
    if (e.name.startsWith('.')) continue;
    const p = path.join(dir, e.name);
    if (e.isDirectory()) {
      if (dir === root && (e.name === 'build' || e.name === 'node_modules')) continue;
      walk(p, root, out);
    } else out.push(p);
  }
  return out;
}

const rel = (root, p) => path.relative(root, p).split(path.sep).join('/');

function stripComments(gd) {
  return gd.split(/\r?\n/).map((l) => {
    let inStr = null;
    for (let i = 0; i < l.length; i++) {
      const c = l[i];
      if (inStr) { if (c === '\\') i++; else if (c === inStr) inStr = null; }
      else if (c === '"' || c === "'") inStr = c;
      else if (c === '#') return l.slice(0, i);
    }
    return l;
  }).join('\n');
}

function registerPaths(root) {
  let text;
  try {
    text = fs.readFileSync(path.join(root, '.ai', 'assets', 'REGISTER.md'), 'utf8');
  } catch {
    return null;
  }
  const paths = [];
  for (const line of text.split(/\r?\n/)) {
    const m = /^\|\s*`?([^|`]+?)`?\s*\|/.exec(line);
    if (m && !/^(Path|-+)$/.test(m[1].trim())) paths.push(m[1].trim().replace(/^res:\/\//, '').replace(/\/+$/, ''));
  }
  return paths;
}

function pngSize(file) {
  try {
    const fd = fs.openSync(file, 'r');
    const b = Buffer.alloc(24);
    fs.readSync(fd, b, 0, 24, 0);
    fs.closeSync(fd);
    if (b.readUInt32BE(12) !== 0x49484452) return null; // IHDR
    return [b.readUInt32BE(16), b.readUInt32BE(20)];
  } catch {
    return null;
  }
}

function lint(root, { harnessRequired = true } = {}) {
  const files = walk(root, root);
  const errors = [];
  const warnings = [];
  const texts = files.filter((f) => TEXT_EXT.test(f));
  const allText = new Map(texts.map((f) => [f, fs.readFileSync(f, 'utf8')]));

  // 1. res:// references that point nowhere
  for (const [f, t] of allText) {
    if (rel(root, f).startsWith('addons/')) continue; // third-party code: not ours to lint
    for (const m of t.matchAll(/res:\/\/([^"'\s)\]]+)/g)) {
      let target = m[1].replace(/[,;]+$/, '');
      if (target.includes('*') || target.includes('%') || target.includes('{')) continue;
      if (target.startsWith('.ai/') || target.startsWith('.godot/')) continue; // generated (git-ignored): written at run time
      if (!fs.existsSync(path.join(root, target))) errors.push({ rule: 'broken-ref', file: rel(root, f), message: `res://${target} does not exist` });
    }
  }

  // 2. Godot 3 APIs in scripts (outside addons — third-party code is not ours to lint)
  for (const [f, t] of allText) {
    if (!f.endsWith('.gd') || rel(root, f).startsWith('addons/')) continue;
    const code = stripComments(t);
    for (const [re, msg] of GODOT3) {
      const m = re.exec(code);
      if (m) {
        const line = code.slice(0, m.index).split('\n').length;
        errors.push({ rule: 'godot3-api', file: `${rel(root, f)}:${line}`, message: msg });
      }
    }
  }

  // 3. assets in assets/ must be in the licence register
  const register = registerPaths(root);
  const assets = files.filter((f) => ASSET_EXT.test(f) && rel(root, f).startsWith('assets/'));
  if (assets.length && register === null) errors.push({ rule: 'licence-register', file: '.ai/assets/REGISTER.md', message: 'missing — every asset needs a register row' });
  else if (register) {
    for (const a of assets) {
      const r = rel(root, a);
      const covered = register.some((p) => r === p || r.startsWith(p + '/'));
      if (!covered) errors.push({ rule: 'licence-register', file: r, message: 'not in .ai/assets/REGISTER.md (a row for the file or its folder)' });
    }
  }

  // 4. unreferenced assets (warning — may be loaded by computed paths)
  const haystack = [...allText.values()].join('\n');
  for (const a of assets) {
    const r = rel(root, a);
    if (!haystack.includes(r) && !haystack.includes(path.basename(r))) warnings.push({ rule: 'unreferenced-asset', file: r, message: 'not referenced by any scene/script/resource' });
  }

  // 5. oversized textures
  for (const f of files.filter((x) => /\.png$/i.test(x) && !rel(root, x).startsWith('addons/'))) {
    const s = pngSize(f);
    if (s && (s[0] > 4096 || s[1] > 4096)) warnings.push({ rule: 'texture-size', file: rel(root, f), message: `${s[0]}×${s[1]} — over 4096 px; downscale or check the target GPU` });
  }

  // 6. harness autoload — required in a game-builder repo (stamped AGENTS.md); elsewhere (e.g. the
  // baseline run before adopting a project) its absence is a warning, so the baseline is honest.
  const pg = allText.get(path.join(root, 'project.godot')) || '';
  if (!/^GbHarness="\*res:\/\/addons\/gb_harness\/harness\.gd"/m.test(pg)) {
    const item = { rule: 'harness', file: 'project.godot', message: 'GbHarness autoload missing — run: node <plugin>/tools/gb/gb.js harness install' };
    const stamped = /Game-Builder-Version:\s*\d/.test(safeRead(path.join(root, 'AGENTS.md')));
    (harnessRequired && stamped ? errors : warnings).push(item);
  }

  return { errors, warnings, files: files.length };
}

function safeRead(f) {
  try {
    return fs.readFileSync(f, 'utf8');
  } catch {
    return '';
  }
}

module.exports = { lint, stripComments, registerPaths, walk, GODOT3 };
