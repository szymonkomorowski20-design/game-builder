# Recipes — tested mechanics for Godot 4.7

Each recipe is a small, working solution to one common game problem: code (GDScript 4, static typing), a scene
where needed, a README (**Problem / Solution / Tuning / Pitfalls / Test**) and at least one test that runs in
`gb verify`. They are meant to be **copied into a game and adapted**, not imported as a library.

```
node tools/recipes.js          # installs harness + GUT into recipes/, then gb verify --path recipes
```

Last full run: 116/116 GUT tests, 11/11 bot scenarios (scenarios also 3× via --repeat), Godot 4.7.2 (2026-09-26).

## How an agent uses a recipe
1. Find it below, or `node <plugin>/tools/gb/gb.js recipe list` (or `gb kb "<problem>"` for background).
2. `node <plugin>/tools/gb/gb.js recipe add <NN> --path .` copies it into `recipes/NN-x/` together with the
   recipes it depends on and their tests (paths rewritten, nothing overwritten); keep the `class_name` unless
   it clashes.
3. Keep the copied tests and adapt them — they are the proof the copy still works in the new game.
4. Move numbers into the spec's Tuning table: a number in a recipe is a default (a constructor argument or a
   plain var) — the game passes its own values from its Tuning resource; the README lists which to tune.
5. Read the recipe's **Pitfalls** before changing it — each one was hit for real (see also `skills/game-implement/godot-pitfalls.md`).

## Index

| Recipe | Title | Problem it solves | Tests |
|---|---|---|---|
| [01-topdown-movement](01-topdown-movement/README.md) | Top-down 8-direction movement | move a character in 8 directions with a snappy but not instant feel; diagonals must not be faster. | r01_topdown_diagonal.gd |
| [02-camera-follow](02-camera-follow/README.md) | 2D camera follow with drag margins and limits | the camera should follow the player without jittering on every small step and never show outside the level. | r02_camera_limits.gd |
| [03-camera-shake](03-camera-shake/README.md) | Screen shake (trauma) | hits and explosions need punch, but random per-frame offsets look like jitter and stacked shakes explode. | test_r03_camera_shake.gd |
| [04-parallax](04-parallax/README.md) | Parallax background | depth in a 2D side view — distant layers move slower than near ones and repeat endlessly. | r04_parallax.gd |
| [05-health](05-health/README.md) | Health & damage component | every hurtable thing (player, enemy, crate) needs the same rules: damage, brief invulnerability after a hit, d | test_r05_health.gd |
| [06-hitbox-hurtbox](06-hitbox-hurtbox/README.md) | Hitbox / hurtbox | attacks, spikes and projectiles must damage the right things, once per contact, without every | r06_hitbox_hurtbox.gd |
| [07-projectile](07-projectile/README.md) | Projectile | bullets, arrows and fireballs: fly, hit once, disappear; never live forever. | r07_projectile_hits.gd |
| [08-weapon](08-weapon/README.md) | Weapon: cooldown, magazine, reload | fire rate, ammo and reload are where shooters feel good or bad; timing must be exact and testable. | test_r08_weapon.gd |
| [09-inventory](09-inventory/README.md) | Inventory with stacks | pick up, stack, drop and save items without losing any and without UI code owning the rules. | test_r09_inventory.gd |
| [10-crafting](10-crafting/README.md) | Crafting | combine items into new ones without duplicating or losing items when something goes wrong. | test_r10_crafting.gd |
| [11-shop](11-shop/README.md) | Shop & currency | buying and selling must never create or destroy money/items by accident. | test_r11_shop.gd |
| [12-achievements](12-achievements/README.md) | Achievements (stat-driven) | achievements scattered as `if` checks everywhere, unlocking twice or not at all after loading a save. | test_r12_achievements.gd |
| [13-save-load](13-save-load/README.md) | Save / load with versions and migrations | saves outlive code. A renamed field or a crash during writing destroys players' progress — the worst bug a g | test_r13_save_load.gd |
| [14-state-machine](14-state-machine/README.md) | Finite state machine (node-based) | a player/enemy script full of `if is_jumping and not is_attacking and ...` flags that contradict each other. | test_r14_state_machine.gd |
| [15-pause](15-pause/README.md) | Pause | pausing stops everything — including the pause menu itself — or leaves some systems running. | r15_pause.gd |
| [16-scene-transitions](16-scene-transitions/README.md) | Scene transitions & background loading | `change_scene_to_file` hitches on big scenes, the cut is abrupt, and double-clicking "Play" starts two loads. | r16_scene_transition.gd |
| [17-settings](17-settings/README.md) | Settings & key rebinding | volume sliders that don't persist, settings files that break after an update, rebinding that wipes the | test_r17_settings.gd |
| [18-dialogue](18-dialogue/README.md) | Branching dialogue | dialogue hardcoded in scripts — writers can't edit it, branches are untestable. | test_r18_dialogue.gd |
| [19-quests](19-quests/README.md) | Quests | quest logic spread over enemies, pickups and NPCs (`if quest_active: counter += 1` in the slime script). | test_r19_quests.gd |
| [20-object-pool](20-object-pool/README.md) | Object pool | hundreds of bullets/sparks per second → instantiate + `queue_free` churn causes frame spikes. | test_r20_pool.gd |
| [21-audio](21-audio/README.md) | Audio: SFX voices, buses, music | every enemy owns an AudioStreamPlayer; 40 hits in one frame = 40 overlapping, clipping copies of the same | test_r21_audio.gd |
| [22-localization](22-localization/README.md) | Localization | English strings hardcoded in scenes and scripts; translating later means hunting through every file; | test_r22_localization.gd |
| [23-hud](23-hud/README.md) | HUD bound by signals | the player script does `get_node("/root/Game/UI/HpBar").value = hp` — every UI change breaks gameplay, | r23_hud.gd |
| [24-enemy-ai](24-enemy-ai/README.md) | Enemy AI: patrol, sight, chase, attack, give up | enemies that see through walls, chase forever, or forget the player the instant they turn a corner. | r24_enemy_ai.gd test_r24_enemy_decide.gd |
| [25-behavior-tree](25-behavior-tree/README.md) | Behavior tree | the enemy FSM (24) grows to 12 states with transitions between all of them (flee when hurt, heal, call | test_r25_behavior_tree.gd |
| [26-navigation](26-navigation/README.md) | Navigation (pathfinding around obstacles) | enemies walking straight at the player get stuck on walls. | r26_navigation.gd |
| [27-tilemap](27-tilemap/README.md) | TileMapLayer: levels, collision, per-tile data | hazards and special tiles detected by comparing tile coordinates in code; world/cell conversions off by | test_r27_tilemap.gd |
| [28-procedural-dungeon](28-procedural-dungeon/README.md) | Procedural dungeon (seeded) | procedural levels that are sometimes unwinnable (unreachable rooms), and bugs nobody can reproduce because | test_r28_dungeon.gd |
| [29-day-night](29-day-night/README.md) | Day/night cycle | lighting, NPC schedules and spawns each keep their own idea of what time it is. | test_r29_day_night.gd |
| [30-grid-puzzle](30-grid-puzzle/README.md) | Grid puzzle (Sokoban rules + undo) | puzzle rules mixed with tweens and sprites → impossible to test, undo bugs, animation timing changes | test_r30_grid_puzzle.gd |
| [31-cards](31-cards/README.md) | Card game core: deck, hand, discard | cards duplicated or lost between piles; shuffles that can't be reproduced for replays, daily challenges | test_r31_cards.gd |
| [32-hit-stop](32-hit-stop/README.md) | Hit-stop (freeze frame) | hits feel weightless. | r32_hit_stop.gd |
| [33-hit-flash-shader](33-hit-flash-shader/README.md) | Hit flash (canvas_item shader) | `modulate = Color.WHITE` can't make a sprite *brighter* than its texture, so "flash white on hit" doesn't | test_r33_hit_flash.gd |
| [34-adaptive-music](34-adaptive-music/README.md) | Adaptive music (AudioStreamInteractive) | music should change with the game (explore → combat → boss) without abrupt cuts, and gameplay code | test_r34_adaptive_music.gd |
| [35-sfx-variants](35-sfx-variants/README.md) | SFX variants with built-in streams (Randomizer + Polyphonic) | the same footstep 40 times sounds mechanical; one `AudioStreamPlayer` per sound per enemy wastes | test_r35_sfx_variants.gd |
| [36-balance-sim](36-balance-sim/README.md) | Balance contracts (Monte-Carlo simulation) | balance is judged by feel after every change; a tweak to one stat silently makes another enemy | test_r36_balance_sim.gd |
| [37-level-validation](37-level-validation/README.md) | Level validation (completable, no soft-locks) | a level edit or a generator seed makes the exit unreachable, hides a coin behind a wall, or puts a | test_r37_level_validation.gd |
| [38-colorblind-check](38-colorblind-check/README.md) | Colour-blind check (palette test + screen overlay) | red vs green teams, health bars, "good/bad" pickups — ~8 % of men can't tell some of these apart, | test_r38_colorblind.gd |
| [39-multiplayer-basics](39-multiplayer-basics/README.md) | Multiplayer basics (server-authoritative, tested in one process) | networked games trust clients ("I have 1000 points"), and multiplayer code is hard to test — two | test_r39_multiplayer.gd |

Tests: `tests/unit/test_rNN_*.gd` (GUT, logic and time via `advance(delta)`), `tests/scenarios/rNN_*.gd`
(bot player through the harness: real physics, real input actions). Tier A (player progress): recipe 13 —
its migration test was proven to fail when the migration is broken.

## Not yet covered
AnimationTree state machines, multiplayer spawning/synchronizers, save-to-cloud, mod loading — planned in `ROADMAP.md`.
