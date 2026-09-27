# Game spec template

File: `.ai/specs/{YYYY-MM-DD}-{kebab-title}.md`

```markdown
# {Title}
Status: draft | approved | in-progress | implemented
Brief: .ai/brief.md {+ Feature Brief section if a feature}
Ladder rung: toy | first playable | vertical slice | content | polish

## Goal
{What the player can do when this spec is done — one or two sentences.}

## Open Questions (all answered before approval)
- [x] {question} → {answer} (decided by: user, date)

## Design
### Player-facing behaviour
{inputs → what happens → feedback: sound / visual / camera / UI}
### States
| State | Enters when | Leaves when | Illegal transitions |
|---|---|---|---|
### Scene & node plan
{proposed tree with node names — scenario and test authors use these names}
### Data
{Resources / @export vars}
### Signals / Events

## Tuning table
| Parameter | Value | Unit | Where | Range to try |
|---|---|---|---|---|
| paddle_speed | 400 | px/s | Paddle.gd `@export var speed` | 300–600 |

## Assets
| Asset | Source (placeholder?) | Licence | Register row |
|---|---|---|---|

## Phases
### Phase 1 — {name}
- Build: …
- Tests: unit `test_…` · scenario `tests/scenarios/….gd` · replay (after feel gate) · shot `…`
- Done when:
  - `node tools/gb/gb.js verify` → PASS (paste summary)
  - {scenario/test IDs that must pass}
- Playtest gate: {yes — what the human judges | no}
- Evidence: {pasted after implementation}

### Phase 2 — …

## Save / compatibility
{saved data, exported var names, input actions, scene paths — change? migration? explicit break?}

## Performance budget
{worst case on the weakest target; perf budget overrides if any}

## Non-goals
- … (→ .ai/backlog.md)

## Decisions Ledger
| Decision | Choice | Decided by | Turned down (why) |
|---|---|---|---|

## Progress
- [ ] Phase 1 …
```
