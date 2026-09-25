---
name: spec-writing
description: Write or update a game spec in this repo — a mechanic, system, level or the first playable — as a phased, testable document in .ai/specs/. Use after a Game/Feature Brief is confirmed and before any gameplay code. Triggers — "napisz spec", "rozpisz mechanikę", "spec prototypu", "plan tej funkcji".
---

# Spec writing (game)

Turns a confirmed brief into a spec the implementation can follow phase by phase. Output:
`.ai/specs/{YYYY-MM-DD}-{kebab-title}.md`, `Status: draft` until the human approves it.

## Rules
- **Open Questions gate first.** List every unknown that changes the design; the human answers them before the spec is finalised. No silent assumptions.
- **Every phase ends in a playable build** and a green `node tools/gb/gb.js verify`. A phase whose result cannot be run is split or merged.
- **Done-when is observable.** "Jump reaches 3 tiles (96 px) with default tuning — asserted by a test that simulates the jump", "restart takes < 3 s", "the human played 3 runs and chose: keep / tweak / cut". Never "works well".
- **Feel is data.** Every tunable number is in the Tuning table with unit and starting value, and maps to one `@export` variable or Resource field. Final values come from the human after playing.
- **Logic gets tests** (damage, state machines, inventory, save data, generation rules). Feel gets a playtest gate.
- **Assets listed with source and licence** before they are used; placeholders are fine and say so.
- **Non-goals are explicit**; deferred ideas go to `.ai/backlog.md`.
- First spec of a new game = the first playable from the brief. Nothing from later ladder rungs.

## Template

```markdown
# {Title}
Status: draft | approved | in-progress | implemented
Brief: .ai/brief.md (or Feature Brief section below)

## Goal
{What the player can do when this is done, in one or two sentences.}

## Open Questions (answer before approval)
- [ ] …

## Design
- Player-facing behaviour (inputs → states → feedback):
- States / transitions (table or list):
- Scenes & nodes (proposed tree, names):
- Data (Resources / exported vars):
- Signals / Events:

## Tuning table
| Parameter | Value | Unit | Where (script/resource) | Range to try |
|---|---|---|---|---|

## Assets
| Asset | Source (placeholder?) | Licence | Register row added? |
|---|---|---|---|

## Phases
### Phase 1 — {name}
- Build: …
- Tests: …
- Done when: `gb verify` PASS + {observable criteria}
- Playtest gate: {yes/no — what the human judges}

### Phase 2 — …

## Save / compatibility
## Performance budget (worst case on the weakest target)
## Non-goals
## Decisions Ledger (for this spec)
```

## After approval
Change `Status: approved`. Implement phase by phase; after each phase paste the `gb verify` summary into the spec's phase section and, where the phase has a playtest gate, the human's verdict. When done: `Status: implemented` and `git mv` the file to `.ai/specs/implemented/`.
