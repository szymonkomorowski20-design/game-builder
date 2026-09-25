# Dogfood 1 — Pong (stage 3 proof), 2026-09-25

Built with game-builder 0.2.0 → 0.3.0 following the skills only: `gb scaffold` → Game Brief →
local spec-writing (game-spec method) → game-pre-implement report → test plan frozen before code →
game-implement, three phases, RED first, `gb verify` every step, detection proofs → human playtest gates.

Repo: `Desktop/gb-pong` (local git; commits 50da709 → 0767d5b).

## Result
| Phase | Evidence | Playtest gate |
|---|---|---|
| 1 — paddles | `gb verify` PASS, unit 11/11, scenarios 3/3; B1 detection proof (clamp removed → unit + scenario red) | none in spec |
| 2 — ball | PASS, scenarios 5/5 incl. no tunnelling at 900 px/s; B4 + B5 detection proofs | **open — waiting for the human** |
| 3 — points/win/restart | PASS, scenarios 8/8 incl. visual V1; B6 + B7 detection proofs | **open — waiting for the human** |

## What the method caught that "read the code" would not
1. **A new state broke an older scenario** (SERVE held the ball; `place_ball` did not enter PLAY). The phase-2 scenario failed after phase-3 code — the regression suite doing its job. Fixed in code; test unchanged.
2. **A visual defect with all tests green**: the ball covered the end-of-match message. Found only by looking at the screenshot from a visual scenario; fixed, expectation added, baseline accepted.
3. **Every behaviour's test was shown to detect its fault** (break → red → revert → green), so the green suite means something.

## What it changed in the plugin
- `gb scenario --window --accept|--compare`: scenario screenshots become baselines (they could only be viewed before).
- `gb tools update` + `gb doctor` warning when a game's `tools/gb` is older than the plugin.
- game-test: "test setup hooks set the full state they imply"; "visual scenario per new screen".
- game-implement: the Pong screenshot example; keeping tools current.

## Numbers
- 4 feature commits after bootstrap; 11 unit tests, 8 scenarios, 1 accepted baseline; 0 assets (rectangles only).
- One-off: the first windowed run after import took 75 s (engine start-up); later windowed runs ~1 s.
