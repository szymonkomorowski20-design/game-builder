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
1. Read the spec, the readiness report, `.ai/STATE.md`, `.ai/lessons.md`, `AGENTS.md`, and — before writing engine API code — [godot-4.4-4.7-changes.md](godot-4.4-4.7-changes.md) (what changed since your training data). When a check fails in a way that makes no sense, look it up in [godot-pitfalls.md](godot-pitfalls.md) first. For a mechanic that has a tested recipe in the plugin (`recipes/README.md`: movement, camera, health, hitboxes, inventory, saves, dialogue, AI, navigation, audio…), start from the recipe, not from memory. No recipe for it → `gb doc reference-games` (gry-wiedza) (open-source Godot 4 games, licences checked) for how a real game structures it.
2. `Status: in-progress`. Branch `feat/<spec-slug>` (never implement on the default branch).
3. Baseline: `gb verify` — green before you start, or the failure is recorded first.
4. Long work (> ~5 commits): run log `.ai/runs/{YYYY-MM-DD}-{slug}.md` — goal, phases, decisions, what's left, and after each phase the pasted evidence — so work resumes after a context reset.

## Loop — per phase, per step
1. **Plan the step**: what changes, which check proves it. Name the RED check first:
   logic → a GUT test that fails now; behaviour → a scenario expectation that fails now.
2. **Implement** the minimal change. Godot rules from AGENTS.md: movement in `_physics_process` × `delta`, tunables as `@export`/Resources matching the Tuning table (a new gameplay number goes into the spec's table first — value, unit, where, range — marked as your proposal for the playtest gate; then the code), input via actions, signals up / calls down, static typing. The check-on-edit hook reports parse/lint errors immediately — fix them in the same turn.
3. **Verify**: `gb verify` (or `gb test` / `gb scenario <file>` while iterating, then full `verify` before commit). Paste the summary. Runtime errors count even when Godot exits 0 — read the report, not the exit code.
4. **Run and look** when the step changes anything the player can see or hear: `gb shot --name <x> [--scene res://…tscn]` (harness) or `gb shot --movie --name <x> [--scene …]` (Godot Movie Maker — works in any project, also records the audio and reports its peak level), or a visual scenario with `gb scenario <file> --window`. Launch straight into the scene the step touched. Open the PNG and compare it with the Done-when. Never claim a visual result you did not look at — in the Pong dogfood every logic test was green while the ball covered the end-of-match text. Copy the shot you judged to `.ai/evidence/<spec-slug>/<NN>-<what-it-shows>.png` and end the step summary with exactly one line:
   - `Run result: OBSERVED — <what is on screen / heard> — .ai/evidence/<file>` (one line, the path on it);
   - `Run result: NOT VERIFIED — <why>` (no window, crash, empty shot) — this **blocks** closing a visual step;
   - `Run result: N/A — <why>` only when nothing is observable (a save-format migration). "It is logic" is not a reason: a damage formula shows a number somewhere.
   A still shows layout, clipping, presence, colour — not timing, feel or audio sync; say which half you covered and leave feel to the playtest gate. `audio peak -inf dBFS` on a step that should make sound is a failed step. Accepted shots become baselines (`--accept`, later `--compare`). *(Rule adapted from Claude Code Game Studios, MIT.)*
5. **Commit point** — one focused commit per step (`feat(<spec>): …`); the game runs after every commit. The commit itself is made only when the human has told you to commit (the repo rule "NEVER commit/push without the human's instruction" wins); otherwise end the step with its files staged and say it is ready to commit. A missing git identity is a question for the human, not something to configure.
6. **Track**: tick the step in the spec's Progress; new unknown → stop and re-gate the spec (`game-spec`), never guess.

## Phase gate (binary)
1. Run every Done-when command from the spec; paste outputs into the spec's phase **Evidence**.
2. `gb doctor` has no MISS.
3. **Independent review** — spawn the `game-builder:game-checker` agent with ONLY: the diff range (`git diff <phase-start>...HEAD`, or `git diff --cached <phase-start>` while nothing is committed — stage the spec's Evidence and the run log first: the checker sees only the diff, and evidence written after staging is invisible to it), the spec path, the frozen test-plan path. Not your summary, not your reasoning. CHANGES-REQUIRED → fix and re-run the checker; NITS → fix or record in backlog.
4. **Machine playtest** — spawn `game-builder:game-playtester` with the spec path and phase: it runs the game, captures shots/audio, looks at them and returns a `Run result` per Done-when item plus the questions for the human. Any NOT VERIFIED → fix before the human plays.
5. **Playtest gate** (if marked): follow `.ai/checklists/playtest.md` — tell the human how to run it (F5 in the editor, or `gb export` build), what to try (3–5 things) and the current Tuning values. **Stop and wait** for their verdict: keep / tweak / cut per mechanic. Record it in the spec with date and commit.
6. **After a "keep" verdict on feel**: offer to record a replay — `node tools/gb/gb.js record <name>` (the human plays; it becomes a regression test) and to accept screenshots (`gb shot --accept` after you looked).
7. Update root `STATUS.md` (phase, playable yes/no, verdict).

**Process: autonomous** (AGENTS.md): steps 1–4 run at **every** phase, and they are the gate. Add a **completability scenario**: a bot finishes the phase's playable loop (template A8, recipe 37). A red one blocks the phase just like a red `gb verify`. Step 5 (the human) moves to the end of the game. Write its checklist into STATUS.md: how to run it, 3–5 things to try, the Tuning values, and the Decisions Ledger. Commits wait for the human's word, so keep a `git write-tree` snapshot per phase and list the ids in STATUS.md.

**Process: light** (AGENTS.md): steps 1, 2 and 7 stay. Step 3 (checker) runs **once per spec**, on the whole spec diff, before the last human gate. Step 4 is your own `Run result` per Done-when (shots opened and looked at, paths on the lines) instead of the playtester agent. Step 5 happens at least at the end of the spec, and at any phase the human asks for. Step 6 is optional. The run log is optional too, but STATE.md is still written at session end. Nothing else relaxes (`<plugin>/docs/rigor.md`).

## The tuning loop (after a "tweak" verdict)
Change only Tuning-table values (exported vars/resources), update the table in the spec, `gb verify`, short playtest again. Not a new spec, not new code paths. If the human asks for new behaviour during tuning, that is new scope → Feature Brief → spec.

## Replays and baselines after intended changes
A replay or screenshot that stops matching after a change is **either a regression or an intended change**. Never re-record or re-accept to make it green on your own: show the human what changed (expected vs actual state / the diff image) and let them decide; then they re-record or you re-accept with their go-ahead.
A baseline that contains changing text (a HUD with "1/5", a move counter) stops matching whenever that text changes — in Lodowy Loch adding floors 6–10 turned "Piętro 1/5" into "1/10" and broke all six board baselines. Keep counters out of baseline shots where you can, and when an intended text change breaks them, show the diff image and ask; do not re-accept.
A **first** baseline for a new screen is different: accept it after you have opened the shot and described it in the Run result — the human sees it at the gate. A compare that passes still prints how many pixels differ: a non-zero count after a visual change means the baseline no longer shows the game — tell the human, as above.

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
- A visual step closed with `Run result: NOT VERIFIED`, or with no `Run result` line at all.
- You used a Godot API from memory that the 4.4–4.7 change list says was renamed or changed.
- The session ends without updating STATE.md.
