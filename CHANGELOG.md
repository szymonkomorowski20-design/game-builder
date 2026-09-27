# Changelog

## 0.12.2 — 2026-09-27 · more fixes from Lodowy Loch (stage 8, phases 4–5)
- Recipe 13 (versioned saves), interrupted writes. `save` writes `.tmp`, removes the old file, then renames. A
  crash between the last two steps left only `.tmp`, and the next load reported MISSING, so the player lost
  progress. The Lodowy Loch phase-5 checker caught it. `load_save` now renames a complete orphaned `.tmp` into place
  and drops a `.tmp` that is unfinished or sits next to a good save. Three new tests; detection proven (without the
  recovery, those three are red).
- `gb import` / `gb verify` import twice when the first pass fails with "Preload file … has no resource loaders". A
  script that preloads a file new to that import (an .ogg added outside the editor) cannot compile on the first pass,
  and the second one passes (measured on 4.7.2). The report says "imported twice". Proven on a fresh scaffold with a
  preloaded new .ogg: 0.12.1 fails the import, now it passes.
- `tools/gb/project_setting.gd --set=section/key=value` sets any string setting through the engine, for example
  `application/run/main_scene`. Needed when a game gains a title screen.
- Scaffolded `.gitignore` ignores `nul`. In Lodowy Loch an agent ran `… 2>nul` inside Git Bash, which created a real file named `nul`, and `git add -A` then failed ("unable to index file 'nul'").

## 0.12.1 — 2026-09-27 · fixes found while building Lodowy Loch (stage 8)
- `gb test` failed open: GUT skips a test script that does not load (parse error, unknown class) and reports the rest as passing, so a test file written before its code showed "PASS 2/2". A test script that fails to load — or fewer scripts run than `test_*.gd` files on disk — now fails the step, naming the file. Proven: the new verification test fails on 0.12.0 and passes now.
- Screenshot compare, per-pixel tolerance 0.1 → 0.02, with a new `--tolerance` flag. Identical runs are bit-exact: 0 px differed even at tolerance 0. At 0.1, an ice-tint change that altered 23 % of the screen compared as "0 px differ". Proven in Lodowy Loch: the same change now fails with 5–15 % of pixels per floor, and reverting it gives 0 px.
- The opt-in windowed test "shot + compare" still expected the pre-0.12.0 message and failed; 0.12.0 was released without running it. It now matches "0 px (0.00%) differ from the baseline". Before a release that touches shots, run `GB_TEST_WINDOW=1 npm test` too.
- game-implement: baselines containing changing text (HUD counters) break on every text change. Keep counters out of baseline shots; when an intended text change breaks them, show the diff and ask. Found in Lodowy Loch: 5 → 10 floors turned "1/5" into "1/10" in six baselines.
- game-implement phase gate: with commits made only on the human's word, the checker reviews the staged diff (`git diff --cached <phase-start>`). Stage the spec's Evidence and the run log before spawning it. In Lodowy Loch phase 1 the evidence was written after staging, and the checker correctly returned CHANGES-REQUIRED for the missing proof.

## 0.12.0 — 2026-09-26 · all 20 evals run, fixes from what they found (stage 7)
- **Evals run** on fresh Sonnet subagents in fixture repos, graded against their binary expectations using the artifacts on disk (`evals/RESULTS-2026-09-26.md`, `Last run:` in every eval): **20 / 20 PASS** in the end; first runs 16 PASS, 3 FAIL, 1 invalid fixture. Limits stated there: stand-in runs (skills named in the prompt, not auto-triggered), one model, one run each.
- **Fixed from the three failures:**
  - game-audio: after refusing a forbidden source, pick the closest legal sound by its description, register it, wire it, prove it plays, and let the human judge it at the gate.
  - game-test: "is the phase built?" is answered from the spec's Progress, STATUS.md and `git log`. `scripts/` and `scenes/` stay closed until the plan file exists.
  - `gb scenario --end-shot` saves every scenario's final frame as `<scenario>__end.png`. It is evidence and never a baseline.
  - game-playtester: N/A only for items with nothing to see or hear; a visible item without a picture is NOT VERIFIED.
- **Fixed from defects that passing evals surfaced:**
  - Screenshot compare now allows 0 differing pixels by default (was 1 %). Three unchanged runs measured 0, and green paddles in Pong (0.42 %) had passed. A passing compare prints its pixel count.
  - `tests/baselines/` gets a `.gdignore`, so Godot no longer imports baselines or exports them into the game.
  - `gb run/test/scenario/replay/shot/perf/export` import first when a `class_name` is missing from Godot's class cache. This happens after `gb recipe add` or on a fresh clone, where scenarios failed with "Could not find type X". Proven against 0.11.0 on a fresh scaffold + recipe 26.
  - `gb scaffold --adopt`:
    - records the project's real renderer, resolution, pixel filter and Events autoload in ADR-001 / AGENTS.md instead of new-project defaults;
    - writes "2D or 3D — not detected" without `--dim`;
    - no longer generates an example test that asserts an Events autoload adoption never adds, which made `gb verify` fail right after adoption.
  - adopt-existing-repo.md: the one expected `gb doctor` MISS (export presets are the human's platform decision), a tracked `.godot/` reported instead of committed, ask for a git identity.
  - game-bootstrap: ask for a git identity, never copy one from another repository. brief-template.md no longer contains the phrase `gb doctor` rejects.
  - game-implement:
    - step 5 is a commit point, made only on the human's word. It had contradicted the repo rule "never commit without the human".
    - a new gameplay number goes into the spec's Tuning table before the code.
    - the Run result line carries its evidence path.
    - a first baseline may be accepted after looking at it; replacing one is the human's call.
  - recipes/README.md describes `gb recipe add` and says recipe numbers are defaults fed from the game's Tuning.
  - The release-hygiene test skips `RESULTS-*.md`.

## 0.11.0 — 2026-09-26 · card template, 20 evals
- `gb scaffold --template cards-2d`: card combat starter (deckbuilder-style) — seeded deck (recipe 31), hand of 5, energy per turn, attack/block cards and the starting deck as data (`data/cards.tres`), enemy with cycling visible intents, block, win/lose/restart; pure `Combat` model; keyboard/gamepad (select, play, end turn) and mouse. 11 unit tests (incl. a balance contract: greedy play wins within 5 turns) + 4 scenarios C1–C4 played through input only, green at scaffold time. Detection proven (block not absorbing, energy not spent); the screenshot review found the selected card marked by colour alone → now also by ▶.
- Evals: 12 new scenarios for the behaviours added in 0.5–0.10 (ripped sounds refused, 4.7 API changes, Tuning instead of literals, Run result line, checker finds what is missing, playtester never judges feel, diagnose reproduces first, release never publishes, save migration, flaky is a defect, recipe first, web audio limits) — 20 in total; a hygiene test checks every eval's fields and referenced files.
- Pong closed as a finished method test on the owner's decision (gates closed without a play verdict).

## 0.10.0 — 2026-09-26 · grid puzzle template (stage 5)
- `gb scaffold --template grid-puzzle-2d`: push-box puzzle starter — rules as a pure model with undo, levels in a `LevelSet` resource (exported with the game, unlike loose .txt files), single step per key press, restart, next level, win; a BFS solver proves every shipped level solvable and pins its par. 6 unit tests + 4 scenarios G1–G4 (the scenarios play the solver's solutions as real key taps), green at scaffold time.
- Caught while building it: a hand-designed level was unsolvable (the solvability test failed, the level was redesigned) and guessed pars were wrong (pars now come from the solver). Detection proven: moving while a key is held turns G1 red. Screenshot looked at.

## 0.9.0 — 2026-09-26 · top-down template (stage 5)
- `gb scaffold --template topdown-2d`: tested top-down arena starter — 8-direction movement with acceleration (normalized diagonals), shooting at a cooldown, enemies that chase and hurt on contact, invulnerability after a hit, two waves, heart pickup, win/lose/restart, HUD; all numbers in `TopDownTuning` (`data/topdown_tuning.tres`); implemented spec with Tuning table; 1 unit test file (3 tests) + 8 behaviour scenarios T1–T8, green at scaffold time. Detection proven: invulnerability 0 turns T5 red, a player without wall collision turns T2 red; screenshot looked at (HUD, walls, pillar, chasing enemies).
- game-bootstrap template card lists both templates with their core loops and tests; e2e test scaffolds and verifies the new template.

## 0.8.0 — 2026-09-26 · multiplayer recipe, flake hunter
- Recipe 39 multiplayer basics: server-authoritative RPCs (client asks, server validates with the network-provided sender id, broadcasts state), tested in ONE process — two `SceneMultiplayer` instances on separate branches over ENet on localhost: join, a cheating request clamped, disconnect. Web note: only HTTP/WebSocket/WebRTC in browsers.
- `gb scenario --repeat N`: runs scenarios N times and names any `FLAKY` scenario (passed k/N). Proven with a deterministic alternating scenario.
- Found while adding recipe 39: a scenario failed once in ~67 runs. Measured cause candidate: the navigation map's first iteration exists at frame 0 but is empty; polygons arrive at frame 3 (4.7.2, async region sync) — the navigation scenario waited 2 frames. Recipe 26 gains `map_ready()` (wait for a non-empty path query); pitfall and game-test anti-flake rules updated (background work is awaited by a readiness condition; `--repeat 10` before closing a phase).

## 0.7.0 — 2026-09-26 · design skills, testable balance and levels (stage 6, part 2)
- **Skills (10):** `game-feel` (response before juice, every knob in the Tuning table), `game-balance` (intent as contracts with bands), `game-level-design` (teach/test levels, completability for every level and seed), `game-npc-ai` (FSM vs BT, perception, telegraphing, decision tables), `game-narrative` (dialogue/quests as data, every branch reachable), `game-save` (tier A with fixtures per release), `game-performance` (measure against a budget on the worst case), `game-ui-accessibility` (focus navigation, resolutions, text size, toggles, AccessKit), `game-vfx` (renderer limits of Compatibility from the 4.7 docs), `game-upgrade` (engine/tool upgrades proven with the same evidence before and after).
- **Recipes 36–38** (113 GUT tests total): balance contracts by Monte-Carlo simulation (detection proven — a stronger slime and an unarmoured knight break their bands with exact numbers), level validation with key/door soft-lock detection (proven), colour-blind palette check + screen overlay (Machado et al. 2009; overlay checked on a real renderer screenshot).
- **Templates:** playtest plan and report, balance sheet, art bible, audio document, postmortem — referenced from their skills.
- **`docs/modules.md`:** optional-module catalogue (status, how, traps) used by game-bootstrap's module cards — e.g. web saves depend on IndexedDB persistence, web multiplayer has only HTTP/WebSocket/WebRTC (4.7 docs).

## 0.6.0 — 2026-09-26 · roles, release and diagnosis (stage 6, part 1)
- **Agents** (few on purpose — Claude Code Game Studios measured that heavier process produced a worse game): `game-checker` (reviews the diff against the spec only, opens with "what the diff does NOT do", read-only), `game-tester` (derives tests from the spec before reading code, detection proof), `game-playtester` (runs the game, `gb shot --movie`, looks at every image, `Run result` per Done-when item, questions for the human — never judges feel), `game-researcher` (recipes → pinned 4.7 docs → knowledge base, verified at source, lists what it could not establish). Wired into game-implement (checker + playtester before the human gate), game-test, game-spec, game-pre-implement.
- **Skills:** `game-release` (credits, smoke-tested exports, web limits, save compatibility, human publishes), `game-diagnose` (reproduce with gb → hypothesis ledger → failing test → minimal fix → incident), `game-playtest` (tasks, observation, keep/tweak/cut → Tuning values or backlog), `game-assets` (library search, allowed licences, Godot 4.7 import, register in the same commit).
- `gb export --smoke`: runs the exported desktop build headless for 180 frames with `--log-file` and fails on errors in its log. Detection proven: a resource dropped by `exclude_filter` passes the editor run and fails the smoke run.
- `gb credits`: `CREDITS.md` from `.ai/assets/REGISTER.md`; fails on non-commercial, no-derivatives, unknown or proprietary licences and on registered files that do not exist.
- Scaffold: pixel-art projects get `window/stretch/scale_mode="integer"`; `credits.js` shipped to game repos; one list of framework files for scaffold and `tools update` (test enforces it). Session router and AGENTS.md task router name the new skills; open incidents route to game-diagnose.

## 0.5.0 — 2026-09-26 · knowledge: recipes, Godot 4.4–4.7 reference, audio (stage 4)
- **Recipes** (`recipes/`, 35): tested mechanics for Godot 4.7 — movement, camera, shake, parallax, health, hitbox/hurtbox, projectile, weapon, inventory, crafting, shop, achievements, versioned save/load (tier A, detection-proven), state machine, pause, scene transitions, settings + rebinding, dialogue, quests, pooling, audio voices, localization, HUD, enemy AI, behavior tree, navigation, tilemap, procedural dungeon, day/night, grid puzzle, cards, hit-stop, hit-flash shader, adaptive music (`AudioStreamInteractive`), SFX variants (`AudioStreamRandomizer` + `AudioStreamPolyphonic`). 98 GUT tests + 11 bot scenarios (`node tools/recipes.js`). Each has README (Problem/Solution/Tuning/Pitfalls/Test) and an index in `recipes/README.md`.
- `gb recipe list` / `gb recipe add <NN…>` (plugin copy): copies recipes into a game with their tests, resolves dependencies from `class_name` use, rewrites `res://` paths, never overwrites. Proven end to end: recipes added to a fresh scaffold pass `gb verify` there.
- `gb shot --movie`: screenshot through Godot's Movie Maker (`--write-movie`) — no harness or game code needed, also records the audio and reports its peak (`audio peak -inf dBFS` = silence), the first automated proof that a game makes sound. Default when the harness is missing.
- `skills/game-implement/godot-4.4-4.7-changes.md`: GDScript-breaking and behaviour changes extracted from the official migration guides of the pinned 4.7 docs (e.g. `Resource.duplicate(true)` in 4.5, Jolt default in 4.6, explicit `return` in typed overrides and keyboard device IDs in 4.7, web audio Sample mode).
- `skills/game-implement/godot-pitfalls.md`: ~35 pitfalls measured while building the harness, Pong and the recipes (symptom → cause → fix).
- `game-implement`: mandatory `Run result: OBSERVED | NOT VERIFIED | N/A` line with evidence in `.ai/evidence/` for every player-visible step (adapted from Claude Code Game Studios, MIT); reads the change list and pitfalls; starts from recipes.
- New skill `game-audio`: legal sources (library search by sound description, licence traps found in gry-wiedza wave 05), import, buses, recipes, web audio limits, proof via `gb shot --movie`, human judges the sound.
- Knowledge base skill updated for gry-wiedza wave 05 (pinned 4.7 docs, audio guides, MIDI assets, audio licence traps). AGENTS.md task router: audio, recipes, Godot changes. Scaffold adds `.ai/evidence/`.
- Found by the recipe tests: `JSON.parse_string` on bad input is an engine error (use `JSON.new().parse`); `get_shader_parameter` is `null` until set; translations must be registered or the UI shows keys; `get_stream_playback()` on a stopped player errors; float accumulation in timers; `is_navigation_finished` uses `target_desired_distance`.

## 0.4.0 — 2026-09-25 · platformer-2d starter template (stage 5, first template)
- `gb scaffold --template platformer-2d`: tested side-view platformer starter — acceleration/friction run, jump defined by height + time to apex (`JumpMath`), faster fall, variable jump, coyote time, jump buffer, all numbers in `PlayerTuning` (`data/player_tuning.tres`); level with gap, platforms, 5 coins, goal, respawn; HUD; implemented spec with Tuning table; 3 unit tests + 8 behaviour scenarios (P1–P8).
- Found by the template's own scenarios: whole-step gravity overshot the designed jump (75.25 px vs 72) → trapezoid integration after the jump impulse (72.07 px); the player walked off the level after the goal (seen in the p8 screenshot) → right wall + freeze at goal, expectation added.
- game-bootstrap: template decision card (Q1b), `--template` flag; scaffold prints concrete import errors.

## 0.3.0 — 2026-09-25 · spec → implement → test (stage 3)
- Skills: `game-spec` (Open Questions gate, Tuning table, runnable Done-when, playtest gates; template), `game-pre-implement` (game compatibility surfaces: @export renames, saves, input actions, res:// paths, replays/baselines; physics/determinism/perf risks), `game-implement` (RED first, gb verify every step, look at shots, playtest gate, tuning loop, never re-record to green, keep tools current), `game-test` (spec-first derivation, frozen plan, four instruments, detection proof tiers, anti-flake; techniques + plan template).
- Router and game-start route through the new skills; AGENTS.md template task router; scaffold adds `.ai/test-plans/` and `.ai/runs/`.
- `gb scenario --window --accept|--compare` for scenario screenshots; `gb tools update`; `gb doctor` warns when a game's tools/gb is older than the plugin.
- Dogfood 1: Pong built with the plugin in three phases (docs/dogfood/pong.md); its lessons are now in game-test/game-implement.
- 3 new evals (written, not yet run).

## 0.2.0 — 2026-09-25 · verification layer (stage 2)
- `gb_harness` addon (autoload `GbHarness`, inert in normal play): seeded RNG, bot-player scenarios (`GbScenario`: press/tap/hold/wait/node/expect_*), record → replay with final-state match for nodes in group `gb_track`, screenshots, performance sampling. Measured on 4.7.2: physics deterministic, input injection works headless, capture needs a window.
- `gb`: `scenario`, `record`, `replay`, `shot` (baseline compare/accept via `imgdiff.gd`), `perf` (vs `.ai/perf-budget.json`), `lint` (broken res:// refs, Godot 3 APIs, licence register, harness), `export` (presets, missing-template diagnosis), `harness install`, `tests install gut`; `verify` = import → check → lint → run → test → scenarios → replays (`--quick` stops after test).
- GUT 9.7.1 vendored (MIT); `gb test` parses GUT totals and writes JUnit.
- Scaffold adds harness, GUT, smoke scenario, example unit test, export presets (Windows Desktop + Web), perf budget, CI workflow (Godot Linux build → `gb verify`), check-on-edit PostToolUse hook; `--adopt` installs harness/GUT through the engine.
- `gb doctor` checks the new pieces and warns about missing export templates.
- Fixes found by the new tests: `check_all.gd` no longer re-loads itself (hang/crash without `.gdignore`); scenarios reach the harness by path (autoload names are not identifiers under `--script`); harness lint is an error only in stamped repos (honest adoption baselines).
- `docs/mcp-evaluation.md`: Godot MCP servers reviewed; `gb` stays the verification instrument.

## 0.1.0 — 2026-09-25 · foundation (stage 1)
- Plugin skeleton: manifest, marketplace, enable scripts, SessionStart hooks (workflow router for game repos, framework-version check), Sailes disabled per game repo to avoid double routing.
- `gb` verification CLI for Godot 4: `godot`, `import`, `check` (all scripts in one boot), `run` (headless, log-based — runtime errors fail even with exit code 0), `test` (GUT/gdUnit4 if installed), `verify`, `doctor`, `kb`/`assets` (gry-wiedza knowledge base), `scaffold` (plugin-only, never overwrites; `--adopt` for existing projects).
- Skills: `game-start`, `game-discovery` (checklists, decision cards, scope ladder, brief templates), `game-bootstrap` (decision engine, engine baseline, adopt procedure, knowledge base, done checklist).
- Game repo templates: stamped AGENTS.md, `.ai/` tree with local spec-writing skill and checklists, `.claude/` guardrails (session memory, protected paths).
- Tests: gb unit + integration against real Godot fixtures, hooks, guard, scaffold incl. an end-to-end bootstrap, release hygiene (versions, changelog, YAML-safe skill frontmatter); `claude plugin validate` passes.
