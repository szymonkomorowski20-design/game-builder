#!/usr/bin/env node
'use strict';

/**
 * SessionStart: does this game repo follow the current game-builder standard?
 *
 * The repo records the plugin version it was set up with (`Game-Builder-Version:` in AGENTS.md). When the
 * installed plugin is newer, the model is told which releases lie in between and asked to OFFER an upgrade;
 * nothing is changed here, and the human decides. Repos that are current, or not ours, hear nothing.
 */

const path = require('path');
const { textOf, stdinText, repoRootFrom, versionStamp, injectContext } = require('./lib/game-repo');

const RELEASES_LISTED = 8;

/** "0.17.1", "v0.9", "1.2.0-beta" → [0, 17, 1] / [0, 9, 0] / [1, 2, 0]; anything else → null. */
function toVersion(text) {
  const token = String(text || '').trim().replace(/^v/i, '').split(/\s+/)[0].split(/[-+]/)[0];
  const parts = token.split('.');
  if (parts.length < 2 || parts.length > 3 || !parts.every((p) => /^\d+$/.test(p))) return null;
  return [0, 1, 2].map((i) => Number(parts[i] || 0));
}

/** Negative when a is older than b, positive when newer, 0 when equal. */
function versionOrder(a, b) {
  const i = [0, 1, 2].find((k) => a[k] !== b[k]);
  return i === undefined ? 0 : a[i] - b[i];
}

const show = (v) => v.join('.');

/** Release headings (`## 0.17.0 — title`) newer than `since` and not newer than `upTo`, as list lines. */
function releasesBetween(changelog, since, upTo) {
  if (!changelog) return [];
  const lines = [];
  for (const raw of changelog.split(/\r?\n/)) {
    if (!raw.startsWith('## ')) continue;
    const heading = raw.slice(3).trim();
    const [versionText, ...rest] = heading.split(/\s+[—–-]\s+/);
    const v = toVersion(versionText);
    if (!v || versionOrder(v, since) <= 0 || versionOrder(v, upTo) > 0) continue;
    const title = rest.join(' — ').trim();
    lines.push(`  - ${versionText.trim()}${title ? ` — ${title}` : ''}`);
    if (lines.length === RELEASES_LISTED) break;
  }
  return lines;
}

function main() {
  const pluginRoot = process.env.CLAUDE_PLUGIN_ROOT;
  if (!pluginRoot) return;
  const installed = toVersion(textOf(path.join(pluginRoot, 'VERSION')));
  if (!installed) return;

  let cwd = process.cwd();
  try {
    cwd = JSON.parse(stdinText() || '{}').cwd || cwd;
  } catch {
    /* keep process.cwd() */
  }
  const stampText = versionStamp(repoRootFrom(cwd));
  if (stampText === null) return; // not a game-builder repo

  const stamped = toVersion(stampText);
  if (!stamped) {
    injectContext('SessionStart', `[game-builder] AGENTS.md has a Game-Builder-Version line but no readable version ("${stampText}"). Current standard: ${show(installed)}. Mention it once; fix the stamp when convenient.`);
    return;
  }
  const order = versionOrder(stamped, installed);
  if (order === 0) return;
  if (order > 0) {
    injectContext('SessionStart', `[game-builder] This repo is stamped ${show(stamped)}, but the installed game-builder plugin is ${show(installed)} — the plugin is behind the repo. Update the plugin; do not "downgrade" the repo.`);
    return;
  }
  const releases = releasesBetween(textOf(path.join(pluginRoot, 'CHANGELOG.md')), stamped, installed);
  injectContext(
    'SessionStart',
    `[game-builder] This repo is stamped Game-Builder-Version ${show(stamped)}; the current standard is ${show(installed)}.` +
      (releases.length ? `\nStandard changed in:\n${releases.join('\n')}\n` : '\n') +
      `Tell the human at the start of your first reply and OFFER an upgrade pass (game-bootstrap, adopt mode). ` +
      `Change nothing unless they accept; if they decline, do not raise it again this session.`
  );
}

try {
  main();
} catch {
  process.exit(0);
}
