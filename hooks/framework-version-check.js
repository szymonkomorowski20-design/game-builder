#!/usr/bin/env node
'use strict';

/**
 * SessionStart triage: is this game repo on the current game-builder standard?
 *
 * Compares the repo's `Game-Builder-Version:` stamp (AGENTS.md header) with the installed plugin's
 * VERSION and, on a delta, names the CHANGELOG entries in between. It never scaffolds and never
 * edits — a script sees absence, not drift, and the human approves every upgrade.
 * Silence is the default: an up-to-date repo, or a repo that never adopted the workflow, costs nothing.
 */

const path = require('path');
const { readStdin, read, findRepoRoot, readStamp, emit } = require('./lib/repo-state');

const MAX_DELTA_ENTRIES = 8;

function parseVersion(raw) {
  const m = /^\s*v?(\d+)\.(\d+)(?:\.(\d+))?/.exec(String(raw || '').trim());
  return m ? [Number(m[1]), Number(m[2]), Number(m[3] || 0)] : null;
}

function compareVersions(a, b) {
  for (let i = 0; i < 3; i++) if (a[i] !== b[i]) return a[i] < b[i] ? -1 : 1;
  return 0;
}

const fmt = (v) => v.join('.');

function changelogDelta(changelog, from, to) {
  if (!changelog) return [];
  const out = [];
  for (const line of changelog.split(/\r?\n/)) {
    const m = /^##\s+(\d+\.\d+(?:\.\d+)?)\s*(?:[—–-]\s*(.*))?$/.exec(line.trim());
    if (!m) continue;
    const v = parseVersion(m[1]);
    if (v && compareVersions(v, from) > 0 && compareVersions(v, to) <= 0) out.push(`  - ${m[1]}${m[2] ? ` — ${m[2].trim()}` : ''}`);
  }
  return out.slice(0, MAX_DELTA_ENTRIES);
}

function main() {
  const pluginRoot = process.env.CLAUDE_PLUGIN_ROOT;
  if (!pluginRoot) return;
  const current = parseVersion(read(path.join(pluginRoot, 'VERSION')));
  if (!current) return;

  let input = {};
  try {
    input = JSON.parse(readStdin() || '{}');
  } catch {
    /* fall through to cwd */
  }
  const root = findRepoRoot(input.cwd || process.cwd());
  const raw = readStamp(root);
  if (raw === null) return; // not a game-builder repo — stay silent

  const stamped = parseVersion(raw);
  if (!stamped) {
    emit('SessionStart', `[game-builder] AGENTS.md has a Game-Builder-Version line but no readable version ("${raw}"). Current standard: ${fmt(current)}. Mention it once; fix the stamp when convenient.`);
    return;
  }
  const cmp = compareVersions(stamped, current);
  if (cmp === 0) return;
  if (cmp > 0) {
    emit('SessionStart', `[game-builder] This repo is stamped ${fmt(stamped)}, but the installed game-builder plugin is ${fmt(current)} — the plugin is behind the repo. Update the plugin; do not "downgrade" the repo.`);
    return;
  }
  const delta = changelogDelta(read(path.join(pluginRoot, 'CHANGELOG.md')), stamped, current);
  emit(
    'SessionStart',
    `[game-builder] This repo is stamped Game-Builder-Version ${fmt(stamped)}; the current standard is ${fmt(current)}.` +
      (delta.length ? `\nStandard changed in:\n${delta.join('\n')}\n` : '\n') +
      `Tell the human at the start of your first reply and OFFER an upgrade pass (game-bootstrap, adopt mode). ` +
      `Change nothing unless they accept; if they decline, do not raise it again this session.`
  );
}

try {
  main();
} catch {
  process.exit(0);
}
