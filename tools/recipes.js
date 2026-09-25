#!/usr/bin/env node
'use strict';

/**
 * Prepare and verify the recipes project (recipes/): copy the harness and the vendored GUT into
 * recipes/addons (git-ignored — the plugin carries them once), make sure the input map exists,
 * then run `gb verify` on it. Usage: node tools/recipes.js [--quick]
 */

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const ROOT = path.resolve(__dirname, '..');
const RECIPES = path.join(ROOT, 'recipes');
const GB = path.join(ROOT, 'tools', 'gb', 'gb.js');

function copyDir(src, dst) {
  fs.mkdirSync(dst, { recursive: true });
  for (const e of fs.readdirSync(src, { withFileTypes: true })) {
    const s = path.join(src, e.name);
    const d = path.join(dst, e.name);
    if (e.isDirectory()) copyDir(s, d);
    else fs.copyFileSync(s, d);
  }
}

function prepare() {
  copyDir(path.join(ROOT, 'templates', 'addons', 'gb_harness'), path.join(RECIPES, 'addons', 'gb_harness'));
  copyDir(path.join(ROOT, 'vendor', 'gut', 'addons', 'gut'), path.join(RECIPES, 'addons', 'gut'));
  const pg = fs.readFileSync(path.join(RECIPES, 'project.godot'), 'utf8');
  if (!/^move_left=/m.test(pg)) {
    const g = JSON.parse(spawnSync(process.execPath, [GB, 'godot', '--json', '--path', RECIPES], { encoding: 'utf8' }).stdout);
    spawnSync(g.godot, ['--headless', '--path', RECIPES, '--script', path.join(ROOT, 'tools', 'gb', 'setup_input.gd')], { encoding: 'utf8' });
  }
}

if (require.main === module) {
  prepare();
  const r = spawnSync(process.execPath, [GB, 'verify', '--path', RECIPES, ...process.argv.slice(2)], { stdio: 'inherit' });
  process.exitCode = r.status;
}

module.exports = { prepare, RECIPES };
