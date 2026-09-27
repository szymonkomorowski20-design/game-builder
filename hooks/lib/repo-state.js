'use strict';

/**
 * Shared repo-state reading for the game-builder SessionStart hooks.
 *
 * Answers from disk: "is this a game repo, did it adopt the game-builder workflow, and what is
 * in flight here?" Nothing in this module throws — a hook that cannot read the disk must degrade
 * to silence, never to a broken session — so every helper answers with null / false / [].
 *
 * Adapted from the Sailes app-builder hooks (same shape, same no-throw contract).
 */

const fs = require('fs');
const path = require('path');

const NOT_A_SPEC = /^(readme|template|agents|claude)\.md$/i;
const CLOSED_INCIDENT = /^\s*Status:\s*(FIXED\b|RESOLVED\b|CLOSED\b)/im;
const STAMP = /Game-Builder-Version:\s*(.+)$/i;
const MAX_HEADER_LINES = 40;
const MAX_INCIDENTS_LISTED = 3;

function readStdin() {
  try {
    return fs.readFileSync(0, 'utf8');
  } catch {
    return '';
  }
}

function read(file) {
  try {
    return fs.readFileSync(file, 'utf8');
  } catch {
    return null;
  }
}

function exists(p) {
  try {
    fs.statSync(p);
    return true;
  } catch {
    return false;
  }
}

/** Repo root = nearest ancestor with .git; a Godot project without git still counts by project.godot. */
function findRepoRoot(startDir) {
  let dir = path.resolve(startDir);
  for (let i = 0; i < 10; i++) {
    if (exists(path.join(dir, '.git')) || exists(path.join(dir, 'project.godot'))) return dir;
    const parent = path.dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  return path.resolve(startDir);
}

/** The `Game-Builder-Version:` stamp in the AGENTS.md header, raw string or null. */
function readStamp(root) {
  const agents = read(path.join(root, 'AGENTS.md'));
  if (agents === null) return null;
  for (const line of agents.split(/\r?\n/).slice(0, MAX_HEADER_LINES)) {
    const m = STAMP.exec(line);
    if (m) return m[1].trim();
  }
  return null;
}

function isGodotProject(root) {
  return exists(path.join(root, 'project.godot'));
}

/**
 * Adopted = the repo opted into the game-builder workflow: its AGENTS.md carries our stamp.
 * The stamp — not the mere presence of AGENTS.md or `.ai/` — is the test, because the Sailes
 * app-builder claims every repo with those, and a game repo must be governed by one workflow.
 */
function isGameBuilderRepo(root) {
  return readStamp(root) !== null;
}

/**
 * The human's process choice from AGENTS.md (`- Process: light`). Absent → standard (repos scaffolded
 * before 0.17.0). An unknown value also falls back to standard, and `unknown` carries it so the router
 * can say so instead of silently picking.
 */
function processWeight(root) {
  const agents = read(path.join(root, 'AGENTS.md'));
  const m = agents === null ? null : /^- Process:\s*([A-Za-z-]+)/m.exec(agents);
  if (!m) return { weight: 'standard', unknown: null };
  const v = m[1].toLowerCase();
  return ['standard', 'light'].includes(v) ? { weight: v, unknown: null } : { weight: 'standard', unknown: m[1] };
}

function activeSpecs(root) {
  try {
    return fs
      .readdirSync(path.join(root, '.ai', 'specs'), { withFileTypes: true })
      .filter((e) => e.isFile() && e.name.endsWith('.md') && !NOT_A_SPEC.test(e.name))
      .map((e) => e.name)
      .sort();
  } catch {
    return [];
  }
}

function openIncidents(root) {
  let names;
  try {
    names = fs
      .readdirSync(path.join(root, '.ai', 'incidents'), { withFileTypes: true })
      .filter((e) => e.isFile() && e.name.endsWith('.md') && !NOT_A_SPEC.test(e.name))
      .map((e) => e.name)
      .sort()
      .reverse();
  } catch {
    return [];
  }
  const out = [];
  for (const name of names) {
    const body = read(path.join(root, '.ai', 'incidents', name));
    if (body === null || CLOSED_INCIDENT.test(body)) continue;
    const status = /^\s*Status:\s*(.+)$/im.exec(body);
    out.push(`\`${name}\`${status ? ` (${status[1].trim()})` : ''}`);
    if (out.length === MAX_INCIDENTS_LISTED) break;
  }
  return out;
}

/** The last `gb verify` report, summarised; null when there is none or it cannot be read. */
function lastVerify(root) {
  const raw = read(path.join(root, '.ai', 'verify', 'last.json'));
  if (raw === null) return null;
  try {
    const r = JSON.parse(raw);
    const failed = (r.steps || []).filter((s) => s.status === 'fail').map((s) => s.step);
    return { result: r.result, at: r.at, failed, godotVersion: r.godotVersion };
  } catch {
    return null;
  }
}

function emit(hookEventName, context) {
  process.stdout.write(JSON.stringify({ hookSpecificOutput: { hookEventName, additionalContext: context } }));
}

module.exports = {
  NOT_A_SPEC,
  CLOSED_INCIDENT,
  readStdin,
  read,
  exists,
  findRepoRoot,
  readStamp,
  isGodotProject,
  isGameBuilderRepo,
  processWeight,
  activeSpecs,
  openIncidents,
  lastVerify,
  emit,
};
