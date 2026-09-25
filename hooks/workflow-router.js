#!/usr/bin/env node
'use strict';

/**
 * SessionStart routing mandate for game repos.
 *
 * A hook cannot invoke a skill; it can put text in the model's context. So it reads the repo's
 * state off disk and states which skill the session must enter — the filesystem decides, not the
 * model's read of the conversation. Fires on startup/resume/clear/compact: a context reset is
 * exactly when the methodology gets dropped.
 *
 * Three cases:
 *   adopted game repo (AGENTS.md stamped Game-Builder-Version) → full mandate
 *   Godot project without the stamp                           → one line offering adoption
 *   anything else                                             → silence
 */

const {
  readStdin,
  findRepoRoot,
  isGameBuilderRepo,
  isGodotProject,
  activeSpecs,
  openIncidents,
  lastVerify,
  emit,
} = require('./lib/repo-state');

const MAX_SPECS_LISTED = 5;
const DRIFT_THRESHOLD = 10;

/**
 * The hard rules in one repeatable line. The same literal appears in
 * skills/game-bootstrap/agents-md-template.md — keep them byte-identical so the generated
 * AGENTS.md and this mandate reinforce each other instead of competing.
 */
const SPINE = 'SPEC → HUMAN → VERIFIED → PLAYABLE → GATED';

const HARD_RULES = [
  '- SPEC — No feature code before an approved spec exists on disk. A one-line fix is exempt; a mechanic is not.',
  '- HUMAN — The human owns every key decision (engine, scope, genre, art direction, feel). Recommend with trade-offs, then let them choose.',
  '- VERIFIED — Done means the engine said so: `node tools/gb/gb.js verify` green, output shown. Reading your own GDScript is not evidence.',
  '- PLAYABLE — Every phase ends in a build the human can run and play. "It compiles" is not a phase result.',
  '- GATED — Phases are gated. Do not cross a gate because the next phase looks obvious; game feel is judged by the human who played it.',
].join('\n');

const SESSION_ROOT = (() => {
  try {
    const input = JSON.parse(readStdin() || '{}');
    return findRepoRoot(input.cwd || process.cwd());
  } catch {
    return findRepoRoot(process.cwd());
  }
})();

function verifyLine(root) {
  const v = lastVerify(root);
  if (!v) return 'No `gb verify` report yet (`.ai/verify/last.json`). Run `node tools/gb/gb.js verify` before claiming anything works.';
  if (v.result === 'PASS') return `Last \`gb verify\`: PASS at ${v.at} (Godot ${v.godotVersion}). Re-run after every change you intend to call done.`;
  return `Last \`gb verify\`: **FAIL** at ${v.at} — failing step(s): ${v.failed.join(', ') || 'unknown'}. ` +
    `The game is known to be broken; fix that (or diagnose it) before building anything new on top.`;
}

function main() {
  const root = SESSION_ROOT;

  if (!isGameBuilderRepo(root)) {
    if (isGodotProject(root)) {
      emit(
        'SessionStart',
        `[game-builder] This is a Godot project that has not adopted the game-builder workflow (no ` +
          `\`Game-Builder-Version:\` stamp in AGENTS.md). If the human wants to build or change gameplay, ` +
          `offer \`game-start\` Route C (adopt) once; do not scaffold anything unless they accept.`
      );
    }
    return;
  }

  const specs = activeSpecs(root);
  let route;
  if (specs.length) {
    const shown = specs.slice(0, MAX_SPECS_LISTED).map((s) => `\`${s}\``).join(', ');
    const more = specs.length > MAX_SPECS_LISTED ? ` (+${specs.length - MAX_SPECS_LISTED} more)` : '';
    const drift = specs.length > DRIFT_THRESHOLD
      ? `\n${specs.length} specs read as "in flight" — finished ones were probably never \`git mv\`'d to \`implemented/\`. Trust each spec's own status over this count.`
      : '';
    route =
      `Spec(s) in flight at \`.ai/specs/\`: ${shown}${more}.${drift}\n` +
      `Read the relevant one BEFORE proposing work. If the request is covered by it, continue at its ` +
      `current phase — \`game-pre-implement\` if it was not risk-checked yet, otherwise \`game-implement\` ` +
      `(phase by phase, each phase ending in a playable build and a green \`gb verify\`). ` +
      `If it is NOT covered, it is new scope: route to \`game-discovery\` and say so rather than quietly widening a spec.`;
  } else {
    route =
      `No active spec at \`.ai/specs/\` — nothing is in flight.\n` +
      `Any request to build, add or change gameplay starts the pipeline: invoke \`game-start\` (map + route), ` +
      `or \`game-discovery\` directly if the human only wants the concept interview. Never start from a one-line pitch.`;
  }

  const incidents = openIncidents(root);
  const incidentBlock = incidents.length
    ? `\nOPEN INCIDENT(S) in \`.ai/incidents/\`: ${incidents.join(', ')}. Read the record first and continue that diagnosis.\n`
    : '';

  emit(
    'SessionStart',
    `[game-builder] This repo runs the game-builder workflow (AGENTS.md stamped), so it governs this session — ` +
      `including after a context reset. It takes precedence over any web-app workflow (e.g. Sailes) that may also ` +
      `announce itself here: this is a game.\n\n` +
      `Pipeline: game-start → game-discovery → game-bootstrap → game-spec (local .ai/skills/spec-writing) → ` +
      `game-pre-implement → game-implement (phase by phase, gb verify every step) → game-test → human playtest gate → release.\n` +
      `BROKEN ≠ MISSING: if the request is about something failing (crash, error in the log, physics glitch, FPS drop), ` +
      `reproduce it with \`gb\` first; do not treat it as new scope.\n\n` +
      `ROUTING (from the repo's state on disk):\n${route}\n${incidentBlock}\n` +
      `ENGINE STATE: ${verifyLine(root)}\n\n` +
      `HARD RULES — ${SPINE}:\n${HARD_RULES}\n\n` +
      `Read \`AGENTS.md\` before your first substantive action. Do not recite this block to the human — act on it.`
  );
}

try {
  main();
} catch {
  try {
    if (isGameBuilderRepo(SESSION_ROOT)) {
      emit(
        'SessionStart',
        `[game-builder] The session router failed to read this repo's state. Fall back to the standard: read ` +
          `AGENTS.md and .ai/specs/ yourself; no gameplay code without an approved spec; verify with ` +
          `\`node tools/gb/gb.js verify\`. Mention the router failure to the human once — it is a real defect.`
      );
    }
  } catch {
    /* the fallback must never throw */
  }
  process.exit(0);
}
