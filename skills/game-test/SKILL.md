---
name: game-test
description: Use to design and write the tests for an implemented game-spec phase — GUT unit tests for logic, bot-player scenarios for behaviour, replays for regression, screenshots for visuals — before review and the playtest gate. Triggers — "napisz testy", "przetestuj to", "plan testów", "jakie przypadki", "co jeszcze może się zepsuć", "edge case", after a phase of game-implement is code-complete. Derives expected behaviour from the SPEC before reading the implementation, freezes the case list with the human, then writes tests that detect faults instead of mirroring the code.
---

# Game Test — tests that detect, not tests that pass

**Core principle (from Sailes, unchanged): the expected value must not come from the implementation.**
An agent that reads the code and then writes assertions encodes the same assumption twice and the
suite is green forever. So: derive from the spec first, freeze with the human, then write.

## The four instruments
| Instrument | For | Where | Deterministic by |
|---|---|---|---|
| GUT unit test | logic that can be wrong silently: damage, score, state machines, inventory, save data, generation rules | `tests/unit/test_*.gd` | pure functions, no timers |
| Scenario (`GbScenario`) | behaviour through real input: moves, jumps, collisions, win/lose | `tests/scenarios/*.gd` | physics frames + seeded RNG |
| Replay | regression of a real play session recorded by the human | `tests/replays/*.json` | same + final-state match of `gb_track` nodes |
| Screenshot | layout/visual regressions | `tests/baselines/*.png` | `--fixed-fps`, same frame |
Feel and fun are none of these — they are the human's playtest verdict.

## Protocol
**Process: light** (AGENTS.md): you write the tests yourself, from the spec, **before** the code. Show them failing, and send the case list to the human in one message instead of a separate freeze step. The rest of this skill still applies (`<plugin>/docs/rigor.md`).

**Delegation (standard):** when you implemented the phase yourself, hand the test work to the `game-builder:game-tester` agent (spec path + phase only) — a fresh context has not seen the implementation, which is exactly what step 1 requires. You keep the human conversation (freezing the plan).

1. **Derive from the spec only** (implementation unread — not even "just to check whether the phase is built":
   that comes from the spec's Progress, `STATUS.md` and `git log --oneline`; `scripts/` and `scenes/` stay closed
   until the plan file exists. A phase that is not built yet still gets its plan first): equivalence partitions incl. invalid, boundary values (0, 1, max, max+1 — lives, score limits, speeds), a state-transition table incl. illegal transitions (dead player pressing jump, pause during scoring), and **a failure path per behaviour**. Details: `techniques.md`.
2. **Emit the plan** (`test-plan-template.md`) to `.ai/test-plans/<spec>.md` with `Status: DRAFT`, questions first (what the spec does not decide). **Hard stop:** the human approves/edits → `FROZEN`. No tests while DRAFT.
3. **Write the tests** from the frozen list; every test name carries its behaviour ID (`test_b3_ball_speeds_up_after_hit`, `# B3` in scenarios). Run them as you write (`gb test`, `gb scenario <file>`).
4. **Read the diff, then only ADD** cases the implementation reveals (float edge, node freed mid-frame). **Never weaken** an assertion or delete a test to reach green; a red frozen test means the code is wrong or the expectation was — the latter is the human's call.
5. **Prove detection** at the tier the behaviour earns — `techniques.md` § Detection proof. Break exactly that behaviour, show its test go red, revert, show green.

| Tier | Trigger | Proof |
|---|---|---|
| A | save/load, progression loss, economy/purchases, anything that destroys the player's progress | per-ID break → red → revert for every A behaviour + a save round-trip test |
| B | rules and mechanics | per-ID break → red → revert |
| C | cosmetics, UI text | green suite |

## Anti-flake rules (games)
- Never wait in real time; wait in physics frames (`wait`, `wait_frames`, `wait_until` with a timeout).
- Seeded randomness only (harness seed); a game-owned `RandomNumberGenerator` takes `GbHarness.seed_value` when active.
- Float positions: `expect_near` with a tolerance derived from the spec, never exact equality after physics.
- Each scenario starts from a known scene (`load_scene`) and does not depend on another scenario's state.
- Retrying until green is forbidden — it hides real intermittent bugs.
- Anything the engine does on a background thread (navigation map sync, threaded resource loading, audio mixing,
  networking) is ready **when a condition says so**, not after N frames: `wait_until(<the real readiness check>)`.
  Measured: a navigation scenario that waited 2 frames raced the async map sync and failed ~1 run in 60.
- Before closing a phase: `node tools/gb/gb.js scenario --repeat 10` — any scenario reported `FLAKY` is a defect to
  diagnose (`game-diagnose`), never a re-run.

## Never
- Assertions that cannot fail (asserting a value the test itself set).
- Mocking your own game code to make a test pass.
- Claiming a playtest happened; manual checks are listed as UNVERIFIED until the human confirms.
- Recording deliberate debt as a comment: use GUT `pending("see backlog: <row>")` so it stays visible in every run.

## Red Flags — STOP
- You opened the implementation before writing the behaviour list.
- Tests exist while the plan still says DRAFT.
- A frozen expectation was changed to match the code.
- No failure paths in the list.
- A tier-A behaviour (saves, progression) without a break → red → revert proof.
