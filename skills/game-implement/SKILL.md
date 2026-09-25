---
name: game-implement
description: Use to implement an approved, ready game spec (or specific phases of it) — phase by phase, each step verified by the engine, each phase ending in a playable build the human plays at its gate, with tests, spec progress, a run log and session memory. Triggers — "zaimplementuj spec", "zrób fazę", "buduj", "realizuj spec", "implement", after game-pre-implement returns READY. Also governs the tuning loop after a playtest ("za wolno", "skok za niski").
---

# Game Implement — build it phase by phase, verified and played

**Core principle:** every step ends with `node tools/gb/gb.js verify` green (or the narrower `gb`
command that proves that step) with the output shown, and leaves the game runnable. Every phase ends
with its Done-when passing **and**, where the spec marks it, the human playing the build.

## When / not
**Use:** spec `approved` and READY (or obviously small). **Not:** no approved spec (→ `game-spec`); NOT-READY (fix the spec); something is broken (reproduce with `gb`, diagnose first).

## Pre-flight
1. Read the spec, the readiness report, `.ai/STATE.md`, `.ai/lessons.md`, `AGENTS.md`.
2. `Status: in-progress`. Branch `feat/<spec-slug>` (never implement on the default branch).
3. Baseline: `gb verify` — green before you start, or the failure is recorded first.
4. Long work (> ~5 commits): run log `.ai/runs/{YYYY-MM-DD}-{slug}.md` — goal, phases, decisions, what's left, and after each phase the pasted evidence — so work resumes after a context reset.

## Loop — per phase, per step
1. **Plan the step**: what changes, which check proves it. Name the RED check first:
   logic → a GUT test that fails now; behaviour → a scenario expectation that fails now.
2. **Implement** the minimal change. Godot rules from AGENTS.md: movement in `_physics_process` × `delta`, tunables as `@export`/Resources matching the Tuning table, input via actions, signals up / calls down, static typing. The check-on-edit hook reports parse/lint errors immediately — fix them in the same turn.
3. **Verify**: `gb verify` (or `gb test` / `gb scenario <file>` while iterating, then full `verify` before commit). Paste the summary. Runtime errors count even when Godot exits 0 — read the report, not the exit code.
4. **Look** when the step is visual: `gb shot --name <x> [--scene …]` or a visual scenario with `gb scenario <file> --window`, then open the PNG and describe what you see. Never claim a visual result you did not look at — in the Pong dogfood every logic test was green while the ball covered the end-of-match text. Accepted shots become baselines (`--accept`, later `--compare`).
5. **Commit** one focused commit per step (`feat(<spec>): …`); the game runs after every commit.
6. **Track**: tick the step in the spec's Progress; new unknown → stop and re-gate the spec (`game-spec`), never guess.

## Phase gate (binary)
1. Run every Done-when command from the spec; paste outputs into the spec's phase **Evidence**.
2. `gb doctor` has no MISS.
3. **Playtest gate** (if marked): follow `.ai/checklists/playtest.md` — tell the human how to run it (F5 in the editor, or `gb export` build), what to try (3–5 things) and the current Tuning values. **Stop and wait** for their verdict: keep / tweak / cut per mechanic. Record it in the spec with date and commit.
4. **After a "keep" verdict on feel**: offer to record a replay — `node tools/gb/gb.js record <name>` (the human plays; it becomes a regression test) and to accept screenshots (`gb shot --accept` after you looked).
5. Update root `STATUS.md` (phase, playable yes/no, verdict).

## The tuning loop (after a "tweak" verdict)
Change only Tuning-table values (exported vars/resources), update the table in the spec, `gb verify`, short playtest again. Not a new spec, not new code paths. If the human asks for new behaviour during tuning, that is new scope → Feature Brief → spec.

## Replays and baselines after intended changes
A replay or screenshot that stops matching after a change is **either a regression or an intended change**. Never re-record or re-accept to make it green on your own: show the human what changed (expected vs actual state / the diff image) and let them decide; then they re-record or you re-accept with their go-ahead.

## Keeping the repo's tools current
`gb doctor` warns when `tools/gb/` differs from the installed plugin. Update with
`node <plugin>/tools/gb/gb.js tools update --path .` (framework files only; `ignore-errors.txt` is kept), then `gb verify`, and commit the update on its own.

## Completion
- All phases done + verified + played where required → `Status: implemented — evidence: gb verify PASS (<date>, <commit>) · playtest: <verdict>` and `git mv` to `.ai/specs/implemented/`.
- Deferred ideas → `.ai/backlog.md`; lessons → `.ai/lessons.md` (promote recurring ones to checks); licences → `.ai/assets/REGISTER.md` complete.
- **Update `.ai/STATE.md` before walking away** (also when interrupted): Verified facts with evidence, Open failures, Last session. Set `Last-commit:`.
- Commit/push only as the human instructs.

## Red Flags — STOP
- You wrote gameplay code with no approved spec.
- A step ended without a `gb` run, or you judged a run by Godot's exit code.
- You tuned by changing logic instead of Tuning values, or added numbers not in the table.
- You re-recorded a replay or accepted a screenshot to turn a red check green without the human.
- A phase closed without its playtest gate (when marked) or without pasted Done-when evidence.
- The session ends without updating STATE.md.
