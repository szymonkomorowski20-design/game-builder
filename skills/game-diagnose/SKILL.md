---
name: game-diagnose
description: Use when something in the game is broken and the cause is not known — a crash, an error in the log, a mechanic that misbehaves, a failing test or replay, a build that works in the editor but not exported, a playtester's bug report. Triggers — "coś nie działa", "błąd", "crash", "bug", "zepsuło się", "gracz przenika przez ścianę", "test nie przechodzi", "replay się rozjechał", "działało wczoraj". Reproduces with gb first, proves the cause with a failing test, fixes minimally and records the incident.
---

# Game Diagnose — reproduce, prove, fix, remember

**Core principle:** no fix before a **reproduction that fails on demand**. A bug you cannot reproduce
with a `gb` command is a hypothesis, not a bug.

## 1. Reproduce (pick the cheapest that shows it)
| Symptom | Reproduction |
|---|---|
| Error in the log / crash | `node tools/gb/gb.js run --frames 300 [--scene res://…]` — the report lists errors with `file:line` even when Godot exits 0 |
| Parse / load error | `gb check` (all scripts in one boot) |
| Wrong behaviour | a `GbScenario` that performs the steps with input actions and `expect_*` the correct outcome — it must be **RED** now |
| Wrong logic | a GUT test that pins the correct value — RED now |
| Happened in a play session | `gb replay tests/replays/<x>.json` — a mismatch prints the diverging `gb_track` state; or ask the human to `gb record` it |
| Only in the exported build | `gb export --preset "Windows Desktop" --smoke` (export filters, missing autoloads, release-only errors) |
| Only on web | human reproduces in the browser; check web limits in `godot-4.4-4.7-changes.md` (audio Sample mode, threads) |
| Visual | `gb shot --movie --scene …` and look at the PNG |
| "Worked yesterday" | `git log`/`git bisect` with the reproduction as the test command |

Record it in `.ai/incidents/{date}-{slug}.md` (`Status: OPEN`): the command, the output, the expected result.

## 2. Hypotheses — a ledger, not a guess
For each hypothesis: what would prove it, what would refute it, the result. Keep refuted ones in the ledger.
Look first in `<plugin>/skills/game-implement/godot-pitfalls.md` (measured symptom → cause pairs: `_unhandled_input`
not seeing injected actions, float accumulation, `get_stream_playback` on a stopped player, navigation map sync,
Area layers/masks, JSON floats…) and `godot-4.4-4.7-changes.md` (API behaviour that changed after the model's training).

## 3. Fix
Minimal change at the proven cause. The reproduction goes GREEN, the full `gb verify` stays green. The
reproduction test **stays in the suite** (it is now a regression test). Tuning problems are Tuning-table
changes, not code.

## 4. Close
Incident `Status: FIXED` with the cause and the commit; a lesson in `.ai/lessons.md` if it can recur; a lesson
that recurs twice becomes a check (a lint rule, a scenario, a test helper).

## Red Flags — STOP
- Changing code before a failing reproduction exists.
- "Fixed" without running the reproduction and `gb verify` after the change.
- Deleting or loosening a failing test/replay to make the bug disappear.
- Several speculative changes at once — you won't know which one mattered.
