---
name: game-spec
description: Use when turning a confirmed Game/Feature Brief into a phased, testable spec for a mechanic, system, level or the first playable — or when reviewing an existing game spec — after game-discovery/game-bootstrap and BEFORE gameplay code. Triggers — "napisz spec", "spec mechaniki", "rozpisz to na fazy", "plan pierwszej grywalnej wersji", "zrób plan wdrożenia", "przejrzyj spec". Prefers the repo's local .ai/skills/spec-writing when present; this is the full method and the fallback. Produces a spec with an Open Questions gate, a tuning table, observable Done-when per phase, playtest gates, assets with licences, save compatibility and non-goals.
---

# Game Spec — a spec the engine can check and the human can play

## Overview

The spec says **what the player can do when a phase is finished, how the engine will prove it, and
where the human plays it**. Implementation follows it phase by phase (`game-implement`); tests are
derived from it (`game-test`); the readiness check reads it (`game-pre-implement`).

**Core principles**
- **Every phase ends in a playable build** and a green `gb verify`. A phase that cannot be run is split or merged.
- **Done-when is observable** — a command and its expected result, a scenario expectation, a test ID, or the human's verdict at a playtest gate. Never "works well", "feels good", "is polished".
- **Feel is data.** Every number someone will want to tune lives in the Tuning table and maps to one `@export` variable or Resource field. The human sets final values after playing.
- **The human decides** anything that changes the game (rules, feel targets, scope); unknowns go to the Open Questions gate, never into silent assumptions.

## When to use / not
**Use:** after a confirmed brief (new game → first playable; feature → that mechanic). Also to review a spec someone else wrote.
**Not:** a one-line tuning change (change the value, playtest); a bug (reproduce + fix, record an incident if it is not trivial).

## Step 0 — Local skill first
If `.ai/skills/spec-writing/SKILL.md` exists, follow it — it is this method tuned to the repo. This skill adds the review checklist below and is the fallback when no local copy exists.

## Step 1 — Skeleton + Open Questions gate
1. Read `.ai/brief.md` (+ the Feature Brief), `AGENTS.md`, `.ai/lessons.md`, existing specs touching the area, and — for mechanics — `node tools/gb/gb.js kb "<mechanic> godot 4"` for known approaches and pitfalls. If the game's genre has a `gb doc genre-*` document, map its principles to phases and recipes (its last table does this) and put its readability/fairness rules into Done-when checks, e.g. a boss's `validate()` passing or offers seeded.
2. Write the skeleton from `spec-template.md` with `Status: draft`.
3. List **Open Questions** — everything that changes design or scope and that the brief does not answer (e.g. "Czy odbicie piłki zależy od miejsca uderzenia w paletkę?", "Co się dzieje przy remisie?"). Ask them via `AskUserQuestion` in rounds of 3–4 with options and a recommendation. **Hard gate:** the spec is not finalised while any is open.

## Step 2 — Fill the spec
Before designing a mechanic you have not built in this repo, check `node <plugin>/tools/gb/gb.js recipe list` (tested building blocks) and, for anything unfamiliar (an API, a system like navigation or adaptive music, an asset source), spawn the `game-builder:game-researcher` agent with the question — it returns sourced facts and what it could not establish. Reference the recipe in the phase that uses it.

Walk `spec-template.md` section by section. Rules per section:
- **Design**: inputs → states → feedback; states as a table incl. illegal transitions; proposed node tree with names (scenario/test authors will use them); signals/Events.
- **Tuning table**: parameter · value · unit · where (script var / resource field) · range to try. Units always (px/s, tiles, s, frames).
- **Assets**: each with source, licence, register row; placeholders marked as such.
- **Phases**: small; each with Build, Tests (unit / scenario / replay / shot as fits), **Done-when** (commands + expected results), **Playtest gate** (yes/no + what the human judges). First phase of a new game = the toy/first playable rung only.
- **Save/compat**: does it change saved data, exported var names, input action names, scene paths? Migration or explicit break.
- **Performance budget**: worst case on screen on the weakest target.
- **Non-goals** + backlog entries.
- **Decisions Ledger** for decisions made in this spec.

**Process: light** (AGENTS.md): a **short spec** is enough. It has goal, non-goals, the Tuning table, a Done-when list (commands + expected results), the tests per Done-when and at most 2 phases, each still ending playable. Open Questions are still resolved with the human, and the review checklist below still applies (`<plugin>/docs/rigor.md`).

## Step 3 — Review checklist (run before asking for approval)
- [ ] No open question left; every assumption either confirmed or listed as a decision.
- [ ] Every phase is playable at its end and has a runnable Done-when.
- [ ] Every tunable number is in the Tuning table with a unit and a code location.
- [ ] Every behaviour has a failure path (what happens on wrong input, on death, at zero, at max).
- [ ] Tests named per phase: logic → GUT, behaviour → scenario, regression → replay (recorded by the human after the feel gate), visuals → shot.
- [ ] Assets have licences; nothing from a "prototype only" source is planned for release.
- [ ] Save/input/scene-path compatibility considered.
- [ ] Scope matches the ladder rung; later ideas are in non-goals/backlog.
- [ ] Design check (`gb doc design-theory` (gry-wiedza)): every mechanic serves the brief's target experience; positive loops are capped; every choice has a trade-off; each level/wave adds something new; the difficulty table rises with rests.

## Step 4 — Approval
Show the human the spec (or its phase list + Tuning table + Open Questions resolved). On approval: `Status: approved`, commit (`spec: <title>`), hand to `game-pre-implement` (non-trivial) or `game-implement` (small).

## Red Flags — STOP
- A Done-when you cannot run ("the jump feels right" without a playtest gate).
- A tunable number written inline in the design text but missing from the Tuning table.
- The first spec of a new game contains menus, save system, inventory or a second level.
- An Open Question answered by you instead of the human.
- A phase whose end state cannot be launched and played.
