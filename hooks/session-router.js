#!/usr/bin/env node
'use strict';

/**
 * SessionStart for game repos: tells the model where this game stands and which skill comes next.
 *
 * Skills can't be started from a hook, but a hook can put text in front of the model. So the state is read
 * from disk (stamp, specs, incidents, the last verify report, the process choice) instead of being guessed
 * from the conversation. It runs on startup, resume, clear and compact, because a fresh or compacted
 * context is exactly when the method is forgotten.
 *
 *   repo stamped `Game-Builder-Version:`  → the full briefing below
 *   Godot project without the stamp       → a single line offering adoption
 *   anything else                         → nothing
 */

const path = require('path');
const game = require('./lib/game-repo');

const SPECS_NAMED = 5;
const SPECS_SUSPICIOUS = 10;
const RIGOR_DOC = path.join(__dirname, '..', 'docs', 'rigor.md');

/**
 * The spine, word for word as in templates/repo/AGENTS.md.tmpl (a test compares them): the generated
 * AGENTS.md and this briefing must say the same thing.
 */
const SPINE = 'SPEC → HUMAN → VERIFIED → PLAYABLE → GATED';

const SPINE_RULES = [
  '- SPEC — No feature code before an approved spec exists on disk. A one-line fix is exempt; a mechanic is not.',
  '- HUMAN — The human owns every key decision (engine, scope, genre, art direction, feel). Recommend with trade-offs, then let them choose.',
  '- VERIFIED — Done means the engine said so: `node tools/gb/gb.js verify` green, output shown. Reading your own GDScript is not evidence.',
  '- PLAYABLE — Every phase ends in a build the human can run and play. "It compiles" is not a phase result.',
  '- GATED — Phases are gated. Do not cross a gate because the next phase looks obvious; game feel is judged by the human who played it.',
];

function sessionRoot() {
  let cwd = process.cwd();
  try {
    cwd = JSON.parse(game.stdinText() || '{}').cwd || cwd;
  } catch {
    /* stdin was not JSON: use the process directory */
  }
  return game.repoRootFrom(cwd);
}

function engineState(root) {
  const last = game.verifySummary(root);
  if (!last) return 'No `gb verify` report yet (`.ai/verify/last.json`). Run `node tools/gb/gb.js verify` before claiming anything works.';
  if (last.result === 'PASS') return `Last \`gb verify\`: PASS at ${last.at} (Godot ${last.godotVersion}). Re-run after every change you intend to call done.`;
  const steps = last.failed.length ? last.failed.join(', ') : 'unknown';
  return `Last \`gb verify\`: **FAIL** at ${last.at} — failing step(s): ${steps}. ` +
    'The game is known to be broken; fix that (or diagnose it) before building anything new on top.';
}

/** Pipeline text and the PROCESS line for the human's choice in AGENTS.md (`- Process:`). */
function processText(root) {
  const choice = game.processWeight(root);
  const note = choice.unknown ? ` AGENTS.md names an unknown process "${choice.unknown}" — using standard; ask the human which they meant.` : '';
  if (choice.weight === 'light') {
    return {
      pipeline:
        'game-start → game-discovery (short brief) → game-bootstrap → game-spec (short spec allowed) → ' +
        'game-pre-implement only if the spec touches saves, autoloads, input action names or shared scenes → ' +
        'game-implement (phase by phase, gb verify every step; your own Run result with shots you looked at; ' +
        'game-checker once per spec, before the last human gate) → human playtest gate at least at the end of the spec → game-release.',
      process:
        'PROCESS: light — chosen by the human in AGENTS.md. It lightens paperwork and review rounds, never the spine ' +
        "below: approved spec, green gb verify with evidence, a playable build per phase, the human's gate and " +
        `their word before any commit. Details: ${RIGOR_DOC}.${note}`,
    };
  }
  return {
    pipeline:
      'game-start → game-discovery → game-bootstrap → game-spec (local .ai/skills/spec-writing) → ' +
      'game-pre-implement → game-implement (phase by phase, gb verify every step; game-checker + game-playtester at each phase gate) → game-test → human playtest gate (game-playtest) → game-release.',
    process: `PROCESS: standard (AGENTS.md; the human may choose light — ${RIGOR_DOC}).${note}`,
  };
}

function nextStep(root) {
  const specs = game.specsInFlight(root);
  if (!specs.length) {
    return 'No active spec at `.ai/specs/` — nothing is in flight.\n' +
      'Any request to build, add or change gameplay starts the pipeline: invoke `game-start` (map + route), ' +
      'or `game-discovery` directly if the human only wants the concept interview. Never start from a one-line pitch.';
  }
  const named = specs.slice(0, SPECS_NAMED).map((name) => '`' + name + '`');
  if (specs.length > SPECS_NAMED) named.push(`and ${specs.length - SPECS_NAMED} more`);
  const suspicious = specs.length > SPECS_SUSPICIOUS
    ? `\nThat is ${specs.length} specs "in flight" — finished ones were probably never \`git mv\`'d to \`implemented/\`. Trust each spec's own status over this count.`
    : '';
  return `Spec(s) in flight at \`.ai/specs/\`: ${named.join(', ')}.${suspicious}\n` +
    'Read the relevant one BEFORE proposing work. If the request is covered by it, continue at its ' +
    'current phase — `game-pre-implement` if it was not risk-checked yet, otherwise `game-implement` ' +
    '(phase by phase, each phase ending in a playable build and a green `gb verify`). ' +
    'If it is NOT covered, it is new scope: route to `game-discovery` and say so rather than quietly widening a spec.';
}

function briefing(root) {
  const proc = processText(root);
  const incidents = game.unresolvedIncidents(root);
  const incidentText = incidents.length
    ? `\nUnresolved incident(s) in \`.ai/incidents/\`: ${incidents.join(', ')}. Read the record first and continue that diagnosis (game-diagnose).\n`
    : '';
  return [
    '[game-builder] This repo runs the game-builder workflow (AGENTS.md stamped), so it governs this session — ' +
      'including after a context reset. It takes precedence over any web-app workflow (e.g. Sailes) that may also ' +
      'announce itself here: this is a game.',
    '',
    `Pipeline: ${proc.pipeline}`,
    proc.process,
    'Side skills: game-audio (sound/music), game-assets (art/models/fonts), recipes (`gb recipe list` in the plugin copy).',
    'Something that used to work and now fails (a crash, an error in the log, a physics glitch, an FPS drop) is a bug, ' +
      'not a feature request: use game-diagnose and reproduce it with `gb` before touching code.',
    '',
    `Where the game stands (read from disk):\n${nextStep(root)}\n${incidentText}`,
    `ENGINE STATE: ${engineState(root)}`,
    '',
    `HARD RULES — ${SPINE}:\n${SPINE_RULES.join('\n')}`,
    '',
    'Read `AGENTS.md` before your first substantive action. This briefing is for you; act on it rather than repeating it to the human.',
  ].join('\n');
}

const ROOT = sessionRoot();

function main() {
  if (game.usesGameBuilder(ROOT)) {
    game.injectContext('SessionStart', briefing(ROOT));
    return;
  }
  if (game.hasGodotProject(ROOT)) {
    game.injectContext(
      'SessionStart',
      '[game-builder] This is a Godot project that has not adopted the game-builder workflow (no ' +
        '`Game-Builder-Version:` stamp in AGENTS.md). If the human wants to build or change gameplay, ' +
        'offer `game-start` Route C (adopt) once; do not scaffold anything unless they accept.'
    );
  }
}

try {
  main();
} catch {
  try {
    if (game.usesGameBuilder(ROOT)) {
      game.injectContext(
        'SessionStart',
        "[game-builder] The session router could not read this repo's state. Work from the standard instead: read " +
          'AGENTS.md and .ai/specs/ yourself; no gameplay code without an approved spec; verify with ' +
          '`node tools/gb/gb.js verify`. Tell the human once that the router failed — it is a real defect.'
      );
    }
  } catch {
    /* nothing may escape a hook */
  }
  process.exit(0);
}
