---
name: game-playtest
description: Use to run a playtest and turn what players say and do into decisions — preparing the build and the questions, observing without leading, recording keep/tweak/cut verdicts per mechanic, and mapping feedback to Tuning-table values or backlog items. Triggers — "playtest", "niech ktoś zagra", "zagrałem i…", "sprawdź czy fajne", "feedback od graczy", "bramka playtestu", after game-playtester reported the machine checks. Covers the human playtest gate of game-implement and wider tests with other players.
---

# Game Playtest — the one verdict no script can give

**Core principle:** the machine proves the build runs and looks right; **people decide whether it is fun,
fair and clear**. Your job is to make their verdict precise and to translate it into numbers or scope —
never to supply the verdict yourself.

## Before the session
1. Machine playtest done (`game-builder:game-playtester` or by hand): `gb verify` green, `Run result` lines
   OBSERVED, no audio `-inf` where sound is expected.
2. One-line way to play: F5 in the editor, or the exported build path (`gb export --smoke` for others).
3. **3–5 tasks**, concrete ("jump across the second gap", "lose on purpose and restart", "buy the sword").
4. The current Tuning values listed next to each mechanic, so feedback maps to numbers.
5. For players other than the developer: a playtest plan (who, what build, what we want to learn — one
   question the session must answer, e.g. "do players understand the double jump without a tutorial?").

## During (when you can observe, e.g. the human narrates or records)
Don't explain the game in advance beyond the controls. Note where they hesitate, die, get lost, repeat, smile.
What players *do* outranks what they *say*. Ask open questions after, not leading ones
("How did the jump feel?" — not "Was the jump too floaty?").

## Verdict — per mechanic
| Mechanic | Verdict | In their words | Maps to |
|---|---|---|---|
| Jump | tweak | "too floaty on the way down" | `fall_gravity_multiplier` 1.6 → 2.0 |
| Coins | keep | — | — |
| Wall slide | cut | "never noticed it" | backlog |

- **keep** → optionally record a replay (`gb record <name>`) as a regression test; accept shots you looked at.
- **tweak** → change only Tuning values, re-verify, short re-test. New behaviour requested = new scope → brief/spec.
- **cut** → remove or move to `.ai/backlog.md` with the reason.
- "Would you play again?" is the prototype's real success test — record the answer.

Record in the spec's phase **Playtest** section: date, build/commit, players, verdict table, and in
`STATUS.md` the phase verdict. Recurring confusion → a lesson in `.ai/lessons.md`.

Templates: [playtest-plan-template.md](playtest-plan-template.md) (before) · [playtest-report-template.md](playtest-report-template.md) (after) — copy both into `.ai/playtests/` named `{date}-{slug}-plan.md` and `{date}-{slug}-report.md`.

## Red Flags — STOP
- Writing "feels good" / "is fun" as your own conclusion.
- Changing code paths in response to a "tweak" verdict.
- A playtest without written tasks or without the Tuning values visible.
- Treating one player's taste as a verdict when the spec asked for a wider test.
