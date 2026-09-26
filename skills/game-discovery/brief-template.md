# Brief templates

The brief is the single artifact discovery produces — decisions and constraints, not prose. The
spec and the implementation consume it. Saved as `.ai/brief.md` (new game) or inside the feature
spec's context section (feature).

---

## New game — Game Brief

```markdown
# Game Brief: {Working Title}

## TLDR
{1–2 sentences: what the player does and why it is fun.}

## Player fantasy
{One sentence.}

## Core loop
- Every ~10 s: {verb}
- Every ~1 min: {goal}
- Every ~10 min: {progress}
- Loop sentence: the player ___, in order to ___, which lets them ___.

## References
| Game | Take | Do NOT take |
|---|---|---|

## Shape
- Dimension / camera:
- Pace: {real-time | turn-based}
- Session length:
- Structure: {levels | runs | hub | open}  ·  Levels: {hand-made | procedural}
- Fail state & its cost:

## Platform & input
- Target platform(s), priority order:
- Input: {keyboard+mouse | gamepad | touch}
- Hard constraints: {e.g. must run in a browser → Compatibility renderer}

## Systems (ranked; only the core loop's systems are in the first playable)
| System | Needed for first playable? | Rung (scope ladder) |
|---|---|---|

## Feel targets
{snappy/heavy + any known numbers → the spec's tuning table}

## Art & audio
- Source: {CC0 placeholders from gry-wiedza | own | bought | AI}  ·  Style:
- Licence rule: every asset registered with source + licence before it ships.

## Narrative & language
## Multiplayer
## Distribution & monetisation
## Maker constraints
- Hours/week, skills, what they want to learn, dev machine:

## First playable
First playable = {…} (scope-guard.md definition)
Done when: {the human's own success criterion}

## Scope ladder position
- Rung 1 (toy): … · Rung 2 (first playable): … · Rung 3+: → backlog

## Non-goals
- {explicitly NOT in this game / not now — also copied to .ai/backlog.md}

## Decisions Ledger
| Decision | Chosen | By | Rejected alternatives (why not) |
|---|---|---|---|
| {decision} | {option} | user | {option — why not} |

## Vetoable trivia (reversible, no cost)

## Next step
- game-bootstrap (Case B), carrying this brief.
```

---

## Feature — Feature Brief

```markdown
# Feature Brief: {Mechanic / System / Content}

## TLDR
## Recon result
- Already exists? {yes / partially / no — scene/script paths}
- Reusable pieces:

## Who & why (which part of the core loop it serves)
## Behaviour
- Inputs → states → outputs · Feedback (sound / visual / camera / UI):

## Feel parameters (starting values; final values decided by the human after playing)
| Parameter | Start value | Unit | Range to try |
|---|---|---|---|

## Acceptance criteria
- [ ] {observable, testable}
- [ ] {edge case}

## Content volume · Save & compatibility · Performance budget
## Assets needed (source + licence)
## Non-goals
## Decisions Ledger
## Next step
- local spec-writing skill → phases, each ending in a playable build.
```
