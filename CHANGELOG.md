# Changelog

## 0.21.1 — 2026-09-27 · fixes found by the proof game
- `gb doctor` in a `Process: autonomous` repo reports "no commit yet" as a WARN pointing to the `git write-tree` snapshots,
  not a MISS: there commits wait for the human, so the MISS blocked every phase gate. Tested.
- `game-checker` has a **spec review mode** (a spec and the brief, no diff), because autonomous mode has it approve the
  spec before any code.
- `docs/rigor.md` says three weights, and names which rules autonomous moves to the end.

## 0.21.0 — 2026-09-27 · autonomous process mode
- **`- Process: autonomous`**, for when the human chooses it ("zrób sam", "prawie bez bramek"); the owner chose it for
  proof games:
  - the bot makes the key decisions with each card's recommended option and the genre doc, recording each in the
    Decisions Ledger (By: bot, reason, alternatives);
  - a fresh game-checker approves the spec against the brief;
  - every phase has machine gates: `gb verify`, the checker, the playtester looking at shots, and a
    **completability scenario** (a bot finishes the loop);
  - the human plays the finished game with a checklist in STATUS.md.

  Unchanged: safety, licences, paid generators only on the human's yes per batch, and commits only on the human's
  word (per-phase `git write-tree` snapshots).
- Where it lives:
  - `gb scaffold --rigor autonomous`;
  - the session router prints the autonomous pipeline and a PROCESS line;
  - a bootstrap card option;
  - notes in discovery, spec and implement;
  - `docs/rigor.md`.

  Tested (router and scaffold).

## 0.20.0 — 2026-09-27 · template action-roguelite-3d (Hades-like), gb check sees autoloads, templates built on recipes
- **`gb scaffold --template action-roguelite-3d`** — an original Hades-like starter:
  - a hub with a training dummy, an upgrade shrine and the run door;
  - runs of 5 rooms with director waves (a spawn warning before every enemy);
  - a boon choice and doors that show their reward;
  - rushers and brutes with two-cue telegraphs that hits never cancel;
  - a boss with 66%/33% phases, an invulnerable transition, adds, and slam/lunge/nova moves, each showing where it
    hurts at its true size;
  - a melee combo and an invulnerable dash that cancels recovery;
  - embers banked on death, and Vitality/Might upgrades saved with the save recipe.
  - Built on recipes 05, 13, 43 and 47–52, which scaffold adds with their tests.
  - Scenarios A1–A8. **A8: a bot wins the whole base run** (the "completable at base stats" contract).
  - Unit contracts: enemy brain, boons, boss readability (`validate()`), and balance (time-to-kill bands; no hit
    over 20% or 30% of base health).
  - Stable over `--repeat 3`.
  - Detection covers 4 cases. A missing i-frame check was caught only after strengthening A1.
- **What the test bot found and what was fixed:**
  - the boss lunge had no ground telegraph;
  - its lane was drawn 1.6 m wide but hurt 3 m wide;
  - it tracked the player until the hit, so no late sidestep worked. It now locks at `lunge_lock`;
  - brutes hit for 30% of health (now 20%).
- **Templates can list `recipes` in template.json.** Scaffold adds them exactly like `gb recipe add` (dependencies +
  tests), so a template never carries a drifting copy. Tested.
- **Recipe dependency detection is fixed.** Only node *types* count in scenes, comments and strings are ignored,
  and names a recipe declares itself (an inner `enum State`) don't count. Before, 47 wrongly pulled in 05 and 06,
  and 51 pulled in 14. Tested.
- **`gb check` no longer fails every script that uses an autoload** (`Events`, `GbHarness`…). It now checks in
  `_initialize()`, where autoload names are known; before, in `_init()`, they weren't (measured). Tested.
- Recipes:
  - 43 `Dash.is_ready()`;
  - 47 `ComboMelee3D.damage_multiplier`;
  - 51 `BossBrain.state_elapsed()`.

  Each has a test or documentation.

## 0.19.0 — 2026-09-27 · genre pack "action roguelite": recipes 47–52, genre doc
- The first genre-pack systems (goal: build a Hades-like on your own). Each recipe has unit tests and a
  bot scenario (except 52), plus detection proofs:
  - **47 melee combo:**
    - `ComboAttack` runs windup → active → recovery, with a 0.15 s input buffer;
    - a press in the last recovery loops the combo;
    - a dash cancels recovery only;
    - a new hit id per swing.
    - `ComboMelee3D` hits each target once per swing.
    - Detection: no buffer, dash-cancel in windup, and no per-swing guard (4 hits per swing).
  - **48 stat modifiers and boons:**
    - `StatSheet` computes (base + flat) × (1 + Σ increased) × Π more, independent of order;
    - boons have rarity scaling and synergies via `requires_tags`;
    - `BoonPool.offer` is seeded and gives distinct, unowned boons, with luck.
    - Detection covers 4 rules. A weak test was found and strengthened: "never offers owned" had checked a single
      seed, now it checks 100.
  - **49 encounter director:**
    - threat budget per depth, waves that fill it and mix types, types unlocked by depth;
    - the next wave only when the last is dead; `cleared` once.
    - Detection covers 4 rules.
  - **50 run structure and meta:**
    - doors show their reward;
    - the first room is combat with a boon, the boss is last, a rest comes before the boss;
    - no shop after a shop, elites from a depth;
    - death banks all currency, and upgrade costs rise;
    - `MetaProgress` goes through to/from dict.
    - The scenario caught a demo economy where the first upgrade was unreachable.
  - **51 boss phases:**
    - HP thresholds stop overflow damage;
    - the transition is invulnerable;
    - telegraph → strike → recovery, with no repeated move;
    - phase-locked moves;
    - `validate()` holds the readability contract (telegraph ≥ 0.4 s, a window to punish).
    - The scenario measures the on-screen telegraph before each strike. Detection covers 5 rules.
  - **52 status effects:** damage over time with exact ticks, REFRESH/STACK with a cap, stat statuses through
    `StatSheet` that are never doubled and are restored on end, cleanse.
- **Genre doc** `gb doc genre-action-roguelite` (gry-wiedza): principles and typical ranges for combat, enemies,
  build variety, run structure, meta, bosses, onboarding and pitfalls. It comes from research across 7 games (84
  sources, marked by confidence) and ends with a principle → recipe table. The discovery and spec skills read
  `genre-*` docs when the pitch is in that genre.
- **Harness:** a scenario script with a parse error now fails at once ("could not load scenario script") instead of
  waiting for the frame cap (76 s in a window). Tested.
- godot-pitfalls: new row, measured in recipe 47. GodotPhysics doesn't report `StaticBody3D` to an `Area3D`.
- Recipes: 193/193 GUT, 23/23 scenarios (×5 stable).

## 0.18.0 — 2026-09-27 · knowledge moved to gry-wiedza, licences, hooks rewritten
- **Split:** the tool stays here and the knowledge moved to the gry-wiedza repo.
  - `design-theory`, `platforms`, `asset-pipeline`, `starter-packs` and `reference-games` now live in
    `gry-wiedza/wiedza/`, with Godot-docs attribution (CC BY 3.0).
  - New `gb doc [name]` reads them from the local gry-wiedza clone (`GAME_BUILDER_WIEDZA`, the clone holding
    BAZA-AI, or `~/Desktop/gry-wiedza`). With no clone it names the GitHub URL. Tested.
  - Skills point to `gb doc <name>`.
  - The Polish manual moved the other way, from gry-wiedza to `docs/INSTRUKCJA.md`, because it describes the tool.
- **Licences:** `LICENSE` (proprietary, all rights reserved, by the owner's decision) and `THIRD_PARTY_NOTICES.md`:
  - GUT 9.7.1: MIT, vendored with its licence and copied into games with it;
  - Claude Code Game Studios: MIT, adapted rules, full notice included;
  - Godot docs: CC BY 3.0, summarised facts, attribution;
  - Sailes app-builder: inspiration only.
- **Hooks rewritten from scratch.** The session hooks had been adapted from Sailes app-builder (Sailes Tech, no
  licence), and about 20 lines were verbatim. They are now new code with the same behaviour:
  - `hooks/lib/game-repo.js` replaces `repo-state.js`;
  - `session-router.js` replaces `workflow-router.js`;
  - `version-check.js` replaces `framework-version-check.js`;
  - the game templates' `guard-protected-paths.sh` now parses JSON with Node;
  - `session-start.sh` was rewritten and now tolerates CRLF.

  Decision-table headers were reworded. After the rewrite, the only line shared with sailes-app-builder 1.28.2
  is a standard PowerShell invocation. Hook tests 12/12 and guard tests 8/8 pass;
  the staleness warning was checked by hand.

## 0.17.1 — 2026-09-27 · export size, README
- `gb export` reports the size of the whole export. For the web that is index.html plus .wasm, .pck and .js: Lodowy Loch showed 0.0 MB, now 40.5 MB. There is a test for it (`exportBytes`).
- README describes 0.17.0 and links the Polish manual in gry-wiedza (`game-builder/INSTRUKCJA.md`).
- Web export templates 4.7.2 installed on the dev machine (official release, SHA512 checked). The Lodowy Loch web build exports and runs in a browser: title, floor 1, a slide with the keyboard.

## 0.17.0 — 2026-09-27 · design theory, platforms, asset pipeline, starter packs, reference games, light process
- **`docs/design-theory.md`:** nine ideas, each with a source and its place at our gates:
  - MDA;
  - loops;
  - interesting decisions;
  - fun as learning;
  - flow and difficulty;
  - game feel;
  - kishōtenketsu level design;
  - audience;
  - playtesting.

  Wired in:
  - the brief has a "Target experience" section and discovery asks about it;
  - the spec review has a design check;
  - the playtest report has aesthetic and difficulty tables;
  - the postmortem asks which aesthetic landed.
- **`docs/platforms.md`:** Web, itch.io + butler, and Android per the **4.7-branch** docs. BAZA-AI's main
  godot-docs copy turned out to be master (4.8-dev), and its Android pages differ: SDK versions, automatic SDK
  setup, R8. Covers:
  - web: single-threaded by default; COOP/COEP only for threads; Sample-mode audio; IndexedDB saves; input-event
    fullscreen; `web_android`/`web_ios`;
  - itch.io: page and SharedArrayBuffer only for threaded builds;
  - Android: keystore through environment variables only, AAB needs Gradle.

  Also in this area:
  - `game-release` points to the doc and no longer suggests `python -m http.server`;
  - the bootstrap platform card shows the consequences.
- **`docs/asset-pipeline.md`:** from the 4.7 docs, the importer repositories and the Blender 4.2 manual:
  - images: pixel art, Detect 3D;
  - audio formats;
  - Blender → glTF: +Z front, NLA-stashed actions, deform bones for blend shapes;
  - name suffixes that delete meshes (`-colonly`, `-navmesh`);
  - edits that survive reimport (extract materials, inherited scenes);
  - TileMapLayer;
  - Aseprite Wizard, YATI (turn off multi-threaded import), and the LDtk importer (quiet since 2025-02).

  `game-assets` links it.
- **`docs/starter-packs.md`:** library packs per template, with local paths, author pages for the register and
  notes. Measured on the way:
  - KayKit characters carry 76–95 animations, including Idle, Running_A and Jump_*;
  - **Kenney Future fonts lack Polish letters except ó**, while Godot's default Open Sans has all of them.

  Gaps: side-view platformer tiles. Discovery and `game-assets` link it.
- **`docs/reference-games.md`:** 17 open-source Godot 4 games. Code and asset licences were read from the repos,
  and 4 were excluded (copyleft, Godot 3, not Godot). None of them has automated tests.
- **Process weight, standard or light (`docs/rigor.md`):**
  - `gb scaffold --rigor standard|light` writes `- Process:` to AGENTS.md and ADR-001;
  - there's a decision card (Q7b) in bootstrap;
  - the session router reads it and prints the matching pipeline plus a PROCESS line, and names an unknown value
    instead of guessing;
  - light: short spec, readiness check only for risky specs, the checker once per spec, the implementer's own
    Run result instead of the playtester agent, a human gate at least per spec. The spine never relaxes;
  - standard stays the default (the choice is the human's). Our own cost comparison is still to be measured;
  - 2 new tests, with a detection proof: the router ignoring the choice turns the test red.
- An independent agent fact-checked platforms.md and asset-pipeline.md against the 4.7 docs and itch.io: 36 of 38
  and 38 of 45 claims were confirmed. Fixed after the check:
  - SharedArrayBuffer: Safari, not Firefox, still needs a popup;
  - the keystore "letters only" rule is a suggestion, and the human sets the signing environment variables;
  - `-rigid` converts the node itself;
  - OBJ wording and the audio sample rate;
  - `.uid` attributed to our rule;
  - a mesh's *Save to File* is not promised to survive reimport;
  - YATI can also crash;
  - the LDtk importer's README says TileMaps while its code creates TileMapLayer, so check the installed version.

  The rest was re-verified directly: the Blender Actions/NLA rule, and the YATI, Aseprite Wizard and LDtk versions.
- `gb kb` adds a NOTE when its results quote the master Godot docs, which BAZA-AI keeps next to the pinned 4.7
  copy and which the search mixes in. For a 4.7 project, trust the `/blob/4.7/` copy. Tested.
- npm test: 82 tests, 78 pass, 4 skipped (window/export).

## 0.16.0 — 2026-09-27 · recipes 44–46
- **44 AnimationTree:**
  - `AnimStates.state_for(on_floor, velocity)` is the one rule: idle/run on the floor, jump while rising, fall
    otherwise.
  - `CharacterAnimator` calls `travel()` only when the state changes.
  - `AnimStates.build_machine()` builds a fully connected state machine with cross-fades in code.
  - The scenario checks the state machine's current node, not the animator's own variable.
  - Detection: jump and fall swapped → unit test and scenario red.
- **45 minimap:**
  - `Minimap` draws the level scaled uniformly (aspect kept, centred) with a dot per tracked group.
  - Things off the map are pinned to the edge, inset by the dot radius; `map_point` is pure.
  - Detection: per-axis scale → 2 unit tests red.
- **46 multiplayer spawning + sync:**
  - `NetWorld` + `NetAvatar`: the server spawns an avatar per peer through a `MultiplayerSpawner`
    (`spawn_function`). Late joiners get everyone; leaving despawns on every peer.
  - A `MultiplayerSynchronizer` replicates `position` (ALWAYS mode, in the spawn packet).
  - Clients only send input. The server rejects NaN/INF, clamps it to length 1, moves at `SPEED` and keeps
    avatars inside `bounds`.
  - Tested in one process with three multiplayer roots (8 GUT tests). A side-by-side demo with a scenario that
    presses a key on the client.
  - Detection, each red:
    - no clamp;
    - no NaN guard;
    - ON_CHANGE instead of ALWAYS (a tampered client copy stays wrong);
    - no despawn;
    - an avatar without a synchronizer (scenario).
  - Stable: 5 scenario repeats, 3 GUT runs.
- godot-pitfalls: 3 new measured rows:
  - ON_CHANGE sync leaves stale client copies;
  - NaN survives `limit_length`;
  - children leave the tree before their parent's `_exit_tree`.
- Recipes: 151/151 GUT, 18/18 scenarios (`node tools/recipes.js`).

## 0.15.0 — 2026-09-27 · first-person shooter template, template input actions
- `gb scaffold --template fps-3d`, green at scaffold time.
  - Mouse look from `screen_relative` with a pitch clamp, and right-stick look.
  - Movement relative to the view; jump.
  - A hitscan weapon (`RayCast3D` masked to world + targets, so walls stop shots) with `fire_interval`, `damage`
    and `weapon_range` in `FpsTuning`.
  - 5 targets with health: one moving, one behind cover. Clear the arena to win.
  - A crosshair HUD; Esc frees the mouse.
  - 6 unit tests and scenarios F1–F6 plus smoke, stable over 10 repeats.
- Detection proven:
  - no fire interval → F4 red (60 shots/s instead of ~7);
  - a ray that ignores walls → F5 red (the hidden target takes damage);
  - mouse look from `relative` → F1 red.
- Templates can declare their own input actions in `template.json` `"actions"`: keys by name, mouse buttons,
  joypad buttons and axes. Scaffold passes them to `setup_input.gd --extra-actions=…`, so Godot still writes the
  input map. fps-3d uses this for `shoot` (LMB / F / right trigger) and `look_*` (right stick). The e2e test checks
  that `shoot` is on mouse button 1.
- The screenshots showed an oversized box gun, which was shrunk.

## 0.14.0 — 2026-09-27 · recipes 40–43
- **40 orbit camera 3D:**
  - `OrbitCamera`: yaw rig, pitch child, spring arm. Mouse (while captured) or the optional
    `camera_left/right/up/down` actions; pitch is clamped and yaw wraps.
  - `camera_relative(input, yaw)`: "up = away from the camera" at any yaw.
  - Found building it: `InputEventMouseMotion.relative` is scaled by the viewport stretch. Mouse look turned 10×
    too far in a headless run, and in a game sensitivity would change with the window size. The recipe uses
    `screen_relative` (4.3+); a new godot-pitfalls row; the scenario fails on `relative`.
- **41 checkpoints:** `CheckpointTracker` — the furthest checkpoint wins, backtracking never moves the respawn back,
  and the start is used before any checkpoint (2D or 3D positions). A `Checkpoint` Area2D and a demo level on
  recipe 01's mover.
- **42 moving platform:**
  - `PlatformPath`: pure ping-pong route at constant speed.
  - `MovingPlatform`: an `AnimatableBody2D` with `sync_to_physics` that carries a `CharacterBody2D` rider sideways
    and upward.
  - Verified the claim: the same platform as a `StaticBody2D` moved by `position` leaves the rider behind; it falls
    to y ≈ 1500 and the scenario goes red.
- **43 dash + knockback:**
  - `Dash`: burst, cooldown counted from the start, i-frames through the burst + `iframes_after`.
  - `Knockback`: away from the source, linear decay; a new hit replaces the push.
  - `DashMover`: priority dash > knockback > walking; `take_hit` respects the i-frames.
- Detection proven:
  - 41 "last touched wins": the unit test and scenario go red.
  - 43 without the cooldown: the unit test and scenario go red.
  - 40 with `relative` and 42 with `StaticBody2D`: the scenarios go red.
- Recipes: 137/137 GUT, 15/15 scenarios, stable over 5 repeats.

## 0.13.0 — 2026-09-27 · 3D platformer template (stage 5)
- `gb scaffold --template platformer-3d`: a 3D starter, green at scaffold time. Forward+, Jolt, 1280×720.
  - Movement on the ground plane with acceleration, friction and air control; the body turns to face the movement.
  - Jump from height + time to apex, faster fall, variable jump, coyote time, jump buffer. All numbers are in
    `PlayerTuning` (metres).
  - Chase camera on a `SpringArm3D`: fixed angle, the world is its only collision layer, and it stays in front of
    walls.
  - A CSG course: a gap, a raised platform, a pillar, 5 coins (masked to the player — Jolt reports static bodies
    too), and a goal.
  - 5 unit tests and scenarios D1–D7 plus smoke; `--repeat 10` stable.
- Detection proven: a spring arm without collision turns D4 red (the camera ends up behind the pillar), and no coyote
  timer turns D3 red.
- Caught while building it:
  - A hand-written `Transform3D` in a .tscn is row-major. A column-major rotation pointed the camera into the ground;
    D4 measured the arm at 1.5 m in the open.
  - The screenshots showed the camera inside the player next to a wall, an ugly sky under the horizon, and the goal
    message covering the player.
  - godot-pitfalls.md gains three rows: row-major Transform3D, camera close to walls, Jolt Area3D.
- game-bootstrap lists the template; the scaffold e2e test covers it.

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
