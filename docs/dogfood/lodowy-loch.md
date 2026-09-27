# Dogfood 2 — Lodowy Loch (stage 8), 2026-09-26 → 2026-09-27

A new small game built end to end with game-builder 0.12.0 → 0.12.2, following the skills only:
game-start → game-discovery (3 interview rounds, Decisions Ledger) → game-bootstrap (`gb scaffold --template
grid-puzzle-2d`, Compatibility, 640×360 pixel art ×2, GUT) → local spec-writing (5 phases, Open Questions answered by
the human) → game-pre-implement → game-implement per phase (tests before code, RED first, `gb verify` every step,
detection proofs, screenshots looked at) → a game-checker and a game-playtester (fresh subagents) per phase → the
human's playtest.

Game: an ice-sliding puzzle in a frozen dungeon. The hero slides until the next cell is a wall, rough rock stops it,
and stairs catch it. There is undo and restart, 10 floors with the solver's target, a title screen with "Kontynuuj",
Kenney Tiny Dungeon tiles, and Kenney sounds with a CC0 music track.
Repo: `Desktop/gry testowe/lodowy-loch` (local git, branch `feat/first-playable`: bootstrap 960bd96, phases
267c4df · 3e7e2ea · a5f00fb · e1d9355; phase 5 staged, commit on the owner's word).

## Result
| Phase | Evidence | Review | Human |
|---|---|---|---|
| 1 — slide | verify PASS, I1–I6 + S1–S4, 2 detection proofs, `--repeat 10` | CHANGES-REQUIRED → APPROVE | deferred |
| 2 — rock + target | I7–I9 + S5, detection proof | NITS (layout numbers → from the scene) | none in spec |
| 3 — Tiny Dungeon art | register + credits, baselines looked at, compare 0 px, detection proof | APPROVE (asset hashes checked) | deferred |
| 4 — 10 floors | I10 difficulty contract, two independent solvers agree, perf on the largest floor | CHANGES-REQUIRED → APPROVE | 2 decisions taken |
| 5 — title, save, audio | P1–P6, A1–A4, S6/S7, audio peaks, detection proofs | CHANGES-REQUIRED → NITS | — |
| all | 30 unit tests, 8 scenarios, 13 baselines | | **played to the end: "wszystko działa"** |

The human played the whole game once, at the end, instead of at each gate. The owner said "kontynuuj" twice without
playing, and the gates were recorded as **deferred**, never as "keep". The final verdict is general. The detailed
questions (slide speed, whether floors 8–10 need thinking, the audio balance) were not answered, and the spec records
them as unanswered.

## What the method caught
1. **A false green in the tool itself.** A test file written before its code did not parse, GUT skipped it, and
   `gb test` said "PASS 2/2". Found in phase 1 while doing test-first. Fixed in 0.12.1.
2. **Two screenshot-compare blind spots.** Green paddles in the eval runs slipped under the 1 % threshold (fixed in
   0.12.0). Here an ice-tint change over 23 % of the screen slipped under the 0.1 per-pixel tolerance. Identical
   runs are bit-exact, so the tolerance is now 0.02 (0.12.1).
3. **Layout problems visible only in screenshots.** An 8-row floor would cover the HUD, so a 19×8 limit was added to
   the tests. The message touched the board, so the board is now centred between the HUD and the message. Wall and
   ice had the same grey-blue, so `wall_tint` was added. All tests were green before each of these.
4. **The checker was right four times.**
   - Evidence was written after staging and was invisible to the review.
   - Floors 6–10 came from a layout search against the brief's "hand-made" levels, without asking the human.
   - A false claim that the win screen differed only in the HUD.
   - An interrupted save write could lose the player's save. That bug was in the plugin's recipe 13 (0.12.2).
5. **A baseline containing HUD text** breaks on every text change. Going from 5 to 10 floors broke six baselines.
   They were re-accepted only on the human's word.
6. **Environment traps.**
   - The first import fails when a script preloads a newly added asset; `gb import` now retries once (0.12.2).
   - `2>nul` in Git Bash creates a real file named `nul` that git cannot index; `nul` is in the scaffolded
     .gitignore (0.12.2).
   - Setting the main scene needed a way to change project settings through the engine
     (`project_setting.gd --set=`).

## What it changed in the plugin (0.12.1–0.12.2)
- `gb test` fails when a test script does not load.
- Screenshot compare: tolerance 0.02 with a `--tolerance` flag.
- `gb import` retries once for the import-order error.
- `project_setting.gd --set=`.
- Recipe 13 recovers from an interrupted write.
- `nul` in the scaffolded .gitignore.
- game-implement:
  - stage the evidence before the checker runs;
  - keep HUD counters out of baselines;
  - a new gameplay number goes into the Tuning table first;
  - first baselines only after looking at them.
- The windowed "shot + compare" test is fixed, and the release note says to run `GB_TEST_WINDOW=1` too.

## Numbers
- About 25 hours of agent work over two days, 5 phases.
- 5 checker rounds that asked for changes, 7 approvals (with or without nits); 5 playtester runs.
- 30 GUT tests, 8 scenarios, 13 accepted baselines, 11 detection proofs.
- Assets: 5 tiles, 4 sound effects and 1 music track, all CC0, each with a REGISTER row, a copied licence file and a
  hash matched against the source pack by the checker.
- Performance on the largest floor: frame p95 4.17 ms, 42 draw calls.

## Not tested by this run
- A GitHub CI run: the game repo is local only, and pushing it anywhere is the owner's call.
- A web or Android export.
- The playtest questions answered one by one.
- The tuning loop after a "tweak" verdict (no tweak was asked for).
