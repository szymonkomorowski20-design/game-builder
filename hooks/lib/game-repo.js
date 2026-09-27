'use strict';

/**
 * What the SessionStart hooks need to know about the repo they start in, read straight from disk.
 *
 * A hook runs before the model sees anything, so it must never break a session: every reader here
 * swallows its own errors and answers with a neutral value (null, false or an empty list).
 */

const fs = require('fs');
const path = require('path');

const HEADER_LINES = 40;                       // the version stamp lives in the AGENTS.md header
const INCIDENTS_SHOWN = 3;
const NOT_WORK_ITEMS = new Set(['readme.md', 'template.md', 'agents.md', 'claude.md']);

function attempt(fn, fallback) {
  try {
    return fn();
  } catch {
    return fallback;
  }
}

const textOf = (file) => attempt(() => fs.readFileSync(file, 'utf8'), null);
const isThere = (p) => attempt(() => Boolean(fs.statSync(p)), false);
const stdinText = () => attempt(() => fs.readFileSync(0, 'utf8'), '');

/** The directory the session belongs to: the closest parent holding `.git` or `project.godot`. */
function repoRootFrom(startDir) {
  const start = path.resolve(startDir);
  let dir = start;
  for (let depth = 0; depth < 10; depth++) {
    if (isThere(path.join(dir, '.git')) || isThere(path.join(dir, 'project.godot'))) return dir;
    const up = path.dirname(dir);
    if (up === dir) break;
    dir = up;
  }
  return start;
}

/** Text after `Game-Builder-Version:` in the AGENTS.md header, or null when the repo never adopted us. */
function versionStamp(root) {
  const agents = textOf(path.join(root, 'AGENTS.md'));
  if (agents === null) return null;
  const header = agents.split(/\r?\n/, HEADER_LINES).join('\n');
  const hit = header.match(/Game-Builder-Version:[ \t]*(.+)/i);
  return hit ? hit[1].trim() : null;
}

/**
 * Only our stamp makes a repo ours. AGENTS.md and `.ai/` alone prove nothing — other workflows use
 * them too — and a game repo must be governed by exactly one workflow.
 */
const usesGameBuilder = (root) => versionStamp(root) !== null;
const hasGodotProject = (root) => isThere(path.join(root, 'project.godot'));

/**
 * The human's process choice (`- Process: light` in AGENTS.md). Missing means standard (repos from before
 * 0.17.0); an unknown word also means standard, and is handed back so the router can name it.
 */
function processWeight(root) {
  const agents = textOf(path.join(root, 'AGENTS.md'));
  const hit = agents === null ? null : agents.match(/^- Process:\s*([A-Za-z-]+)/m);
  if (!hit) return { weight: 'standard', unknown: null };
  const word = hit[1].toLowerCase();
  return ['standard', 'light', 'autonomous'].includes(word) ? { weight: word, unknown: null } : { weight: 'standard', unknown: hit[1] };
}

/** Markdown work items in a folder, oldest name first; READMEs and templates are not work items. */
function workItems(dir) {
  return attempt(
    () =>
      fs
        .readdirSync(dir, { withFileTypes: true })
        .filter((entry) => entry.isFile() && /\.md$/i.test(entry.name) && !NOT_WORK_ITEMS.has(entry.name.toLowerCase()))
        .map((entry) => entry.name)
        .sort(),
    []
  );
}

/** Specs still in `.ai/specs/` (finished ones are moved to `implemented/`, a subfolder, so they drop out). */
const specsInFlight = (root) => workItems(path.join(root, '.ai', 'specs'));

/** Newest incidents whose Status is not fixed/resolved/closed, as display strings. */
function unresolvedIncidents(root) {
  const dir = path.join(root, '.ai', 'incidents');
  const shown = [];
  for (const name of workItems(dir).reverse()) {
    const body = textOf(path.join(dir, name));
    if (body === null) continue;
    const statusLine = body.match(/^[ \t]*Status:[ \t]*(.+)$/im);
    const status = statusLine ? statusLine[1].trim() : '';
    if (/^(fixed|resolved|closed)\b/i.test(status)) continue;
    shown.push(status ? `\`${name}\` (${status})` : `\`${name}\``);
    if (shown.length === INCIDENTS_SHOWN) break;
  }
  return shown;
}

/** Summary of the last `gb verify` report, or null when there is none or it is unreadable. */
function verifySummary(root) {
  const report = attempt(() => JSON.parse(textOf(path.join(root, '.ai', 'verify', 'last.json'))), null);
  if (!report || typeof report !== 'object') return null;
  const steps = Array.isArray(report.steps) ? report.steps : [];
  return {
    result: report.result,
    at: report.at,
    godotVersion: report.godotVersion,
    failed: steps.filter((s) => s && s.status === 'fail').map((s) => s.step),
  };
}

/** Hand text to the model as SessionStart context (the hook protocol's JSON on stdout). */
function injectContext(eventName, text) {
  process.stdout.write(JSON.stringify({ hookSpecificOutput: { hookEventName: eventName, additionalContext: text } }));
}

module.exports = {
  textOf,
  stdinText,
  repoRootFrom,
  versionStamp,
  usesGameBuilder,
  hasGodotProject,
  processWeight,
  specsInFlight,
  unresolvedIncidents,
  verifySummary,
  injectContext,
};
