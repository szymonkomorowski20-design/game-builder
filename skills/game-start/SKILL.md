---
name: game-start
description: Use at the very START of making a game, when the user wants to be led through the whole flow end-to-end — a NEW game from scratch (concept → engine and project setup → spec → first playable), ADOPTING an existing Godot project (e.g. one built without this workflow), or DEEPENING a new mechanic/feature in a game that already runs the game-builder workflow. Triggers — "zróbmy grę", "nowa gra od zera", "chcę zrobić grę o…", "poprowadź mnie przez całość", "mam pomysł na grę", "dodajmy mechanikę", "przejmij mój projekt w Godocie", "od początku do końca". Thin orchestrator — runs game-discovery → game-bootstrap → spec-writing in order, with a human gate at every boundary.
---

# Game Start — End-to-End Orchestrator

## Overview

**The single entry point that runs the whole pre-production pipeline in order.** It re-implements nothing: it sequences existing skills and gates the handoffs, so no phase is skipped and none runs out of order.

```
        ┌─ ROUTE A: New game from scratch ──────────────────────────────────────┐
START → │ game-discovery(new) → game-bootstrap(Case B: generate Godot project +  │ → first playable
        │ methodology, verified by gb) → spec-writing(prototype spec)            │
        └────────────────────────────────────────────────────────────────────────┘
        ┌─ ROUTE B: New mechanic/feature (repo already on game-builder) ────────┐
        │ game-discovery(feature) → game-bootstrap(Case A: absorb + validate)   │ → implementation
        │ → spec-writing                                                         │
        └────────────────────────────────────────────────────────────────────────┘
        ┌─ ROUTE C: Adopt an existing Godot project (code, no methodology) ─────┐
        │ game-discovery(light) → game-bootstrap(Case C: add methodology over    │ → implementation
        │ the EXISTING project, never rewriting it) → spec-writing               │
        └────────────────────────────────────────────────────────────────────────┘
```

**Core principle:** the user asked to be *led*. First show the map (phases, where they are, the gates), then walk it — never dive into phase 1 as if it were the whole task.

**The game-specific principle:** a game is judged by playing it. Every phase of this pipeline ends in something the human can run, and the gate that matters most — *does it feel right?* — is theirs, after playing. Automated checks (`gb verify`) prove it runs; only the human proves it is fun.

## When to Use / When NOT to

**Use when:** the user wants end-to-end guidance — a new game, adopting a Godot project, or a new mechanic where the path from idea to playable build is the ask.

**Do NOT use when:**
- The user wants one phase only (only the concept interview, only project setup, only a spec) — call that skill directly.
- Mid-implementation of an approved spec — continue it.
- Something is broken (crash, error in the log, physics glitch) — reproduce it with `gb` and diagnose; that is not new scope.
- A trivial one-line change.

## Step 0 — Show the map, then route

1. **Show the pipeline** (the diagram, in one breath) and say you will stop for their confirmation between phases.
2. **Route** — the only decision needed before phase 1:

> "Robimy **nową grę od zera (A)**, **dokładamy mechanikę do gry, która już pracuje w naszym stylu (B)**, czy **przejmujemy istniejący projekt Godota, który powstał bez tej metody (C)**?"

Detect from the filesystem and confirm if ambiguous — **trust the filesystem**:
- empty dir / no `project.godot` → A
- `project.godot` + AGENTS.md stamped `Game-Builder-Version:` → B
- `project.godot` (real scenes/scripts) without the stamp → C — even if it has an AGENTS.md from another workflow.

3. **Engine check (before phase 1).** This workflow's verification layer (`tools/gb`) and knowledge base are built for **Godot 4**. If the user wants Unity/Unreal/other, say so plainly: discovery and specs still apply, but `gb` cannot verify a non-Godot build yet — every "done" would rest on the human's own test. Let them choose knowingly.
4. **Fog check.** If the idea is too big or foggy for one interview — unknowns depending on other unknowns, an MMO/open-world scale pitch, "I don't know what genre yet" — say so and cut it down first (`game-discovery/scope-guard.md` — the scope ladder). A giant pitch is never discovered in one sitting; it is reduced to a first playable.

## The pipeline (run in order, gate each boundary)

### Phase 1 — Concept  →  invoke `game-discovery`
- A → new-game variant (player fantasy, core loop, references, platform, controls, scope, art source, constraints).
- B → feature variant (does it already exist? exact behaviour, feel parameters, acceptance).
- C → light variant (what does the game do today, what does the user want from the adoption).
- **Gate:** the human confirms the **Game Brief** (and its Decisions Ledger) before phase 2.

### Phase 2 — Project setup  →  invoke `game-bootstrap`
- A → Case B: classify (`decision-engine.md`), walk the engine/renderer/test-framework decision cards, **generate** the Godot project + methodology (AGENTS.md stamped, `.ai/`, guardrails, `tools/gb`), git init + first commit.
- B → Case A: absorb the repo's rules; validate the engine setup covers the new mechanic.
- C → Case C: document the existing project, add the methodology **additively**; never rewrite running code (`adopt-existing-repo.md`).
- **Gate:** `repo-done-checklist.md` all green **and** `node tools/gb/gb.js verify` PASS with its output shown. "I created the files" is not evidence.

### Phase 3 — Spec  →  the local `.ai/skills/spec-writing/SKILL.md` bootstrap generated
- For a new game the first spec is the **prototype**: the core loop with placeholder art, one level/arena, win/lose — nothing else.
- **Gate:** the human approves the spec before any gameplay code.

### Then — implementation (skill-backed)
`game-pre-implement` (readiness report) → `game-implement` (phase by phase, `gb verify` every step, playtest gate per phase) → `game-test` (tests derived from the spec, frozen with the human). Phase by phase per the spec. Each phase ends in a **playable build** + green `gb verify` + the human playing it at the gates the spec marks. This orchestrator's job ends when the spec is approved.

## Hard rules

- **Always show the map first**, always route before phase 1.
- **Never skip a phase or a gate.** Brief → project + verify → spec → implementation, each boundary confirmed.
- **Never re-implement** discovery/bootstrap/spec logic inline — invoke the skills.
- **Never write gameplay code before the spec is approved.**
- **Never claim a phase done without evidence** — `gb verify` output and the done-checklist output, pasted.
- **Never decide the game for the human** — genre, scope, feel, art direction are theirs (decision cards).

## Quick Reference

| Phase | Skill | Route A (new) | Route B (feature) | Route C (adopt) | Gate |
|---|---|---|---|---|---|
| 0 | — | map + route + engine + fog | map + route | map + route | route chosen |
| 1 | `game-discovery` | new-game | feature | light | Brief confirmed |
| 2 | `game-bootstrap` | Case B (generate) | Case A (absorb) | Case C (adopt) | checklist green + `gb verify` PASS |
| 3 | local spec-writing | prototype spec | feature spec | feature spec | spec approved |
| → | implementation | phase by phase, playable each | same | same | human plays at gates |

## Red Flags — STOP

- You started asking concept questions and the user never saw the phase map.
- The pitch is "an open-world RPG with multiplayer" and you are about to interview for it as-is — run the scope ladder first.
- You are about to write a spec and bootstrap never ran (no stamped AGENTS.md, no `tools/gb`, no git).
- You are about to say "project ready" without a `gb verify` PASS in this session.
- You picked the genre, perspective, art style or engine yourself.
- You are writing gameplay code and no spec was approved.
