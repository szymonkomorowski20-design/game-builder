---
name: game-bootstrap
description: Use right AFTER game-discovery (confirmed Game Brief) and BEFORE any gameplay code, to set up the Godot project AND the game-builder methodology — or to adopt an existing Godot project into it. Triggers — "ustaw projekt gry", "stwórz projekt w Godocie", "jaki silnik / renderer", "przygotuj repo gry", "przejmij mój projekt Godota", "ruszamy z grą". Classifies the game, walks the engine/renderer/resolution/test-framework/LFS decision cards, generates the project with `gb scaffold` (never overwriting), and proves it runs with `gb doctor` + `gb verify` before handing to the spec.
---

# Game Bootstrap — Project Setup & Methodology (Godot 4)

## Overview

**The bridge between knowing WHAT game to make (discovery) and building it.** It produces a Godot project that boots, a repo an agent can work in safely (stamped AGENTS.md, `.ai/`, guardrails), and the verification instrument (`tools/gb`) every later phase uses — then proves all of that on disk.

**Core principles:**
- **The human decides the setup** (engine, dimension, renderer, resolution, test framework, LFS) from decision cards; you recommend from `engine-baseline.md` and *their* brief.
- **Generation is mechanical, not hand-typed.** `gb scaffold` writes the project; Godot itself writes the input map (`setup_input.gd`), so the serialized format is always right for this engine version. Nothing existing is ever overwritten.
- **Done is proven, not claimed**: `gb doctor` (no MISS) + `gb verify` (PASS), outputs pasted.

The tool lives in the plugin: `<plugin>/tools/gb/gb.js`, where `<plugin>` is two folders above this skill's base directory (the Skill tool prints the base directory). After scaffolding, the game repo has its own copy at `tools/gb/gb.js`.

## Step 0 — Detect the case (trust the filesystem)

- **Case A — adopted repo** (`project.godot` + AGENTS.md stamped `Game-Builder-Version:`): read AGENTS.md → `.ai/brief.md` → relevant specs. Validate the setup covers the new work; scaffold nothing. `node tools/gb/gb.js doctor` to see the state.
- **Case B — no `project.godot`** (empty or near-empty folder): generate (Steps 1–5).
- **Case C — existing Godot project without the stamp** (real scenes/scripts, e.g. a project started before this workflow): **adopt, never rewrite** — `adopt-existing-repo.md`.

If told "empty folder" but a `project.godot` exists, say so and switch to Case C.

## Step 1 — Classify (decision mode)

Walk `decision-engine.md` in rounds of 3–4 (`AskUserQuestion`), carrying the brief in — most answers are already in the brief; ask only what is missing. It yields the **setup manifest**: dimension, renderer, base resolution/pixel art, target platforms, test framework, LFS, optional modules (save, localization, multiplayer…) — each chosen by the human from a card, recorded in the brief's Decisions Ledger. For each module show its status from `<plugin>/docs/modules.md` (tested recipe / skill / external / not yet) and its traps — e.g. multiplayer on a web target cannot use ENet, web saves depend on the browser keeping IndexedDB.

**Engine card first.** Godot 4 is the recommendation *because this workflow can verify it* (`gb`) and the knowledge base covers it. Unity/Unreal are legitimate choices — say plainly that `gb` does not verify them yet, so "done" would rest on the human's own testing. Check which engines are actually installed (`GODOT_BIN`, the binaries `gb` finds) rather than assuming; a missing or mismatched Godot version is a fact-finding question, not something to paper over.

## Step 2 — Working discipline

Commit to the spine for the session — **SPEC → HUMAN → VERIFIED → PLAYABLE → GATED** — and to `engine-baseline.md` "Godot conventions". Never bypass `gb verify`, silence errors, delete tests, publish builds, or commit without the human's go-ahead.

## Step 3 — Generate (Case B)

1. Confirm once: "Wygeneruję projekt w `<folder>` i zrobię pierwszy commit — OK?"
2. Run scaffold with the manifest:
   ```
   node <plugin>/tools/gb/gb.js scaffold --dir <folder> --name "<title>" --dim 2d|3d \
     [--renderer forward_plus|mobile|gl_compatibility] [--pixel-art] [--width W --height H] \
     [--tests gut|gdunit4|none] [--lfs] [--template platformer-2d]
   ```
   With `--template`, the starter game replaces the placeholder scene (dimension/resolution come from the template); read its implemented spec in `.ai/specs/implemented/` with the human before the first spec.
   It creates `project.godot`, a placeholder main scene, the `Events` autoload, default input actions (via Godot), `tools/gb/`, stamped `AGENTS.md`, `CLAUDE.md`, `README.md`, `STATUS.md`, the full `.ai/` tree (specs, adr + ADR-001, checklists, asset register, STATE/lessons/backlog, local `spec-writing` skill) and `.claude/` guardrails (settings with Sailes disabled for this repo, session-start + protected-path hooks), then imports the project. Read its report: every line is CREATED or KEPT.
3. Write `.ai/brief.md` from the confirmed brief (it must contain the Decisions Ledger with nothing pending).
4. Review `AGENTS.md` "Project" section against the manifest; add genre-specific notes only if they are judgment rules (keep it short — it is a map).
5. `git init` (if needed), `git add -A`, first commit: `chore: bootstrap <title> (game-builder <version>)`.

The verification layer comes with the project: `addons/gb_harness` (autoload `GbHarness`, inert in normal play — scenarios, record/replay, screenshots, perf), GUT (vendored, pinned; with `--tests gut`), a smoke scenario, an example unit test, `export_presets.cfg` (Windows Desktop + Web), `.ai/perf-budget.json`, the CI workflow and the check-on-edit hook. With `--tests none`, `gb test` reports **SKIP** and you say so — a SKIP is never reported as a pass. Web export needs the Web export templates installed once in the Godot editor; `gb doctor` warns when they are missing.

## Step 4 — Knowledge base wiring

The gry-wiedza library (BAZA-AI) is the reference for techniques and assets: `knowledge-base.md`. Check it is reachable: `node tools/gb/gb.js kb "CharacterBody2D"`. If not found, tell the human once how to set `GAME_BUILDER_KB`; never block on it.

## Step 5 — Verify, then hand off

Run and paste both outputs:
```
node tools/gb/gb.js doctor
node tools/gb/gb.js verify
```
- `doctor` must end in `DONE — no MISS lines`. WARN lines (e.g. test framework not installed) are stated to the human, not hidden.
- `verify` must be PASS. A presence check is not a boot check — report them as two results.
- Offer the first "playable": "Otwórz folder w Godocie i naciśnij F5 — zobaczysz pustą scenę startową; to dowód, że projekt działa, nie gra."

All green → hand to the spec phase: the local `.ai/skills/spec-writing/SKILL.md`, first spec = the first playable from the brief.

## Quick Reference

| | Case A: adopted | Case B: new | Case C: adopt existing |
|---|---|---|---|
| Detect | stamped AGENTS.md | no project.godot | project.godot, no stamp |
| Classify | validate vs new work | `decision-engine.md` → manifest | document the existing setup |
| Generate | nothing | `gb scaffold …` | `gb scaffold --adopt` (methodology only) |
| Prove | `gb doctor` + `gb verify` | same | same + the game still runs as before |

Reference files: `decision-engine.md` · `engine-baseline.md` · `adopt-existing-repo.md` · `knowledge-base.md` · `repo-done-checklist.md`.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Hand-writing project.godot or the input map | `gb scaffold`; the engine writes the input map. |
| Picking 3D / Forward+ / pixel art silently | Decision cards; the human picks; ADR-001 records it. |
| Web in the platform list but renderer Forward+ | Web export needs the Compatibility renderer — surface the conflict on the card. |
| Declaring "set up" without `doctor` + `verify` output | Paste both; any MISS or FAIL means not done. |
| Case C: "cleaning up" the existing project while adopting | Additive only; never move, rename or rewrite game files. |
| Reporting `gb test` SKIP as passing | SKIP is stated as "no test framework yet". |
| Writing the first spec before bootstrap finished | Hand off only after both checks are green. |

## Red Flags — STOP

- You typed a `[input]` section or a `.tscn` by hand for the initial setup.
- The renderer/dimension/resolution was never chosen by the human from a card.
- `gb scaffold` printed a FAIL line and you moved on.
- You are about to say "project ready" and `doctor` has MISS lines or `verify` is not PASS in this session.
- Case C and your diff touches the game's scenes or scripts.
- You committed or pushed without the human's go-ahead.
