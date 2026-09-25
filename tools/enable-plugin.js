#!/usr/bin/env node
'use strict';

/**
 * Enable the game-builder marketplace + plugin for THIS user on THIS machine.
 * Idempotent: merges into ~/.claude/settings.json without touching other keys.
 * Node is required anyway (gb is a Node tool), so one script serves Windows, macOS and Linux;
 * enable-plugin.ps1 / enable-plugin.sh are thin wrappers.
 */

const fs = require('fs');
const os = require('os');
const path = require('path');

const REPO = 'szymonkomorowski20-design/game-builder';
const settingsPath = path.join(os.homedir(), '.claude', 'settings.json');

fs.mkdirSync(path.dirname(settingsPath), { recursive: true });
let s = {};
try {
  const raw = fs.readFileSync(settingsPath, 'utf8').trim();
  if (raw) s = JSON.parse(raw);
} catch (e) {
  if (e.code !== 'ENOENT') {
    console.error(`Cannot parse ${settingsPath}: ${e.message}. Fix it by hand; nothing was changed.`);
    process.exit(1);
  }
}

s.extraKnownMarketplaces = s.extraKnownMarketplaces || {};
s.extraKnownMarketplaces['game-builder'] = { source: { source: 'github', repo: REPO }, autoUpdate: true };
s.enabledPlugins = s.enabledPlugins || {};
s.enabledPlugins['game-builder@game-builder'] = true;

fs.writeFileSync(settingsPath, JSON.stringify(s, null, 2) + '\n');
console.log(`game-builder marketplace + plugin enabled in ${settingsPath}`);
console.log('Restart Claude Code (or open a new session) — the game-builder plugin will install from GitHub.');
