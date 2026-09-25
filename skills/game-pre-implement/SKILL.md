---
name: game-pre-implement
description: Use AFTER a game spec is approved and BEFORE gameplay code, to check the spec against the real project — save-data and scene compatibility, exported-variable and input-action renames, asset licences, performance and physics risks, gaps — and produce a readiness report. Triggers — "czy spec jest gotowy", "sprawdź spec przed kodowaniem", "analiza ryzyka", "pre-implement", before implementing any non-trivial game spec. Catches problems on paper instead of mid-implementation.
---

# Game Pre-Implement — readiness before any code

**Output: a readiness report, not code.** Fifteen minutes reading the spec against the actual project
saves the rework that comes from a renamed variable silently resetting every scene, a save file that no
longer loads, or an asset that cannot ship.

## When / not
**Use:** approved spec, non-trivial (more than one script/scene, touches saved data, shared scenes, autoloads, input, assets).
**Not:** trivial tuning or one-file change; spec still draft; no spec.

## Phase 1 — Load context
1. The spec (fully), `.ai/brief.md`, `AGENTS.md`, `.ai/lessons.md`, `.ai/STATE.md`.
2. Current engine state: `node tools/gb/gb.js verify --quick` — the baseline. A red baseline is reported first; nothing new is built on a broken game.
3. Map what the spec touches: scenes (`grep -rl` the scene/script names), autoloads (`project.godot [autoload]`), input actions (`[input]`), resources, save code. Large scope → read-only recon subagents, one area each.

## Phase 2 — Compatibility audit (the game-specific surfaces)
| Surface | Why it breaks silently | Check |
|---|---|---|
| `@export var` names | values are serialized in .tscn/.tres by NAME; a rename resets them to defaults in every scene without an error | grep scenes/resources for the old name; plan the rename in the editor or migrate the files |
| Save data | players' saves have the old shape | versioned save format; migration or explicit break approved by the human |
| Input action names | scenes/scripts/replays reference them by string | grep `is_action`/`action_` + tests/replays/*.json |
| Scene / resource paths | `res://` paths in other scenes; moving files outside the editor breaks them | `gb lint` after any move; prefer moving in the editor |
| Autoload API (signals, functions) | used from many scenes | grep usages |
| `class_name` | global identifier, used in type hints everywhere | grep |
| Node names/paths used by `get_node`/`$` | renames break at runtime only | grep `$`/`get_node` + scenarios' `node("…")` |
| Replays in `tests/replays/` | an intended gameplay change makes them mismatch | list which will need re-recording by the human |
| Screenshots in `tests/baselines/` | visual changes | list which will need re-accepting |

Each hit: **Critical** (fix the spec first) or **Warning** (needs a migration/bridge) + the path.

## Phase 3 — Gaps
Against `game-spec` Step 3 review checklist: open questions, unrunnable Done-when, numbers outside the Tuning table, missing failure paths, missing tests per phase, assets without licence, phases that leave the game unplayable.

## Phase 4 — Risks
Scenario · severity · mitigation · residual. Game-typical: physics tunnelling at high speed (continuous collision / smaller steps), frame-rate dependence (movement outside `_physics_process` or without `delta`), non-determinism breaking replays (unseeded RNG, real-time timers), performance worst case (particles, enemies, draw calls on the weakest target), content volume vs time, licence of planned assets, web-export constraints (Compatibility renderer, no threads by default).

## Phase 5 — Report
```
# Pre-Implement Report: {spec}
## Verdict: READY | READY-WITH-FIXES | NOT-READY
## Baseline: gb verify --quick → {PASS/FAIL, pasted}
## Compatibility: [Critical/Warning] surface → path
## Gaps: …
## Risks: scenario · severity · mitigation · residual
## Will need the human: replays to re-record · baselines to re-accept · saves that break
## Remediation (spec edits before coding) · Suggested phase order
```
NOT-READY / WITH-FIXES → fix the spec (game-spec) first. READY → `game-implement`.

## Red Flags — STOP
- You never ran the baseline `gb verify`.
- The spec renames an `@export` var or input action and nothing plans the migration.
- Saved data changes shape and no version/migration is in the spec.
- You found a Critical and started coding anyway.
