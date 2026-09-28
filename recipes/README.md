# Recipes — tested mechanics for Godot 4.7

Each recipe is a small, working solution to one common game problem: code (GDScript 4, static typing), a scene
where needed, a README (**Problem / Solution / Tuning / Pitfalls / Test**) and at least one test that runs in
`gb verify`. They are meant to be **copied into a game and adapted**, not imported as a library.

```
node tools/recipes.js          # installs harness + GUT into recipes/, then gb verify --path recipes
```

Last full run: 280/280 GUT tests, 24/24 bot scenarios, Godot 4.7.2 (2026-09-28).

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
| [40-orbit-camera-3d](40-orbit-camera-3d/README.md) | 3D orbit camera (mouse or stick) with camera-relative movement | a third-person game needs a camera the player can turn with the mouse or the right stick, that never flips, never looks from inside a wall | test_r40_orbit_camera.gd, r40_orbit_camera.gd |
| [41-checkpoints](41-checkpoints/README.md) | Checkpoints (furthest one wins, never backwards) | after dying the player should restart at the last checkpoint — but walking back over an earlier flag must not move the respawn point back | test_r41_checkpoints.gd, r41_checkpoints.gd |
| [42-moving-platform](42-moving-platform/README.md) | Moving platform that carries the player | a platform moving along waypoints must carry whoever stands on it, sideways and upward, without the rider sliding off | test_r42_platform_path.gd, r42_moving_platform.gd |
| [43-dash-knockback](43-dash-knockback/README.md) | Dash and knockback (with i-frames) | a dash that can be spammed or leaves the player hittable mid-dash; knockback that stacks into a launch or pushes toward the enemy | test_r43_dash_knockback.gd, r43_dash_knockback.gd |
| [44-animation-tree](44-animation-tree/README.md) | AnimationTree state machine driven by movement | animation code scattered through the player script, animations that flicker between states, a fall animation that never plays | test_r44_anim_states.gd, r44_animation_tree.gd |
| [45-minimap](45-minimap/README.md) | Minimap (drawn, aspect kept, off-map pinned to the edge) | a minimap that stretches the level (distances lie), loses things that are off the map, or renders the level twice | test_r45_minimap.gd, r45_minimap.gd |
| [46-multiplayer-spawn-sync](46-multiplayer-spawn-sync/README.md) | Multiplayer spawning + sync (MultiplayerSpawner, MultiplayerSynchronizer) | avatars must appear for late joiners, vanish everywhere when their owner leaves and move without clients teleporting themselves | test_r46_net_world.gd, r46_net_world.gd |
| [47-melee-combo](47-melee-combo/README.md) | Melee combo (windup / active / recovery, input buffer, dash-cancel) | mushy melee: eaten presses, hitboxes on for the whole swing, one swing hitting five times | test_r47_combo.gd, r47_melee_combo.gd |
| [48-boons-modifiers](48-boons-modifiers/README.md) | Stat modifiers and boons (rarity, synergies, seeded offers) | build variety that breaks: order-dependent stacking, repeated offers, synergies before their parts, unreproducible offers | test_r48_boons.gd, r48_boons.gd |
| [49-encounter-director](49-encounter-director/README.md) | Encounter director (threat budget, waves, room cleared) + AttackTokens (at most N attack at once) | hand-placed rooms don't scale, random spawns are unfair or repetitive, and five overlapping tells are unreadable | test_r49_encounters.gd, r49_encounter.gd |
| [50-run-meta](50-run-meta/README.md) | Run structure and meta progression | blind doors, bad pacing, death erasing all progress, broken upgrade economy | test_r50_run_meta.gd, r50_run_meta.gd |
| [51-boss-phases](51-boss-phases/README.md) | Boss phases and telegraphed attacks | bosses that are an HP pile: phases skipped by burst, unreadable or repetitive attacks | test_r51_boss.gd, r51_boss.gd |
| [52-status-effects](52-status-effects/README.md) | Status effects (damage over time, stacks, stat changes) | burns ticking once too often, doubled slows that never end, uncapped stacks | test_r52_status.gd |
| [53-gun-handling](53-gun-handling/README.md) | Gun handling (fire rate, magazine, tactical/empty reload, spread and bloom, ADS, recoil pattern, damage falloff) | guns that fire at the frame rate, reloads that eat rounds, random recoil nobody can learn, hip fire as accurate as aiming | test_r53_gun.gd |
| [54-hitscan-zones](54-hitscan-zones/README.md) | Hitscan with hit zones (spread → ray, head / body / limb) | rays from the camera hitting the shooter, headshots that never register, spread applied in world space | test_r54_hitscan.gd |
| [55-regen-health-indicators](55-regen-health-indicators/README.md) | Regenerating health and damage direction indicators | regen that starts mid-fight, deaths with no warning, hits from behind with no idea where from | test_r55_regen.gd |
| [56-aim-assist](56-aim-assist/README.md) | Aim assist for pads (slowdown and pull in a cone, only while moving the stick) | a pad player who can't track anything, or an aimbot that snaps through walls | test_r56_aim_assist.gd |
| [57-cover-shooter-ai](57-cover-shooter-ai/README.md) | Cover-shooter AI (cover finder, peek, suppression, flank, barks, accuracy ramp) | enemies standing in the open or killing from 40 m with the first shot; flanks nobody hears coming | test_r57_cover_ai.gd |
| [58-rts-selection-orders](58-rts-selection-orders/README.md) | RTS selection and orders (click, box, groups, smart right-click, shift queue) | a box that grabs the town hall with the army, enemies mixed into a selection, groups keeping the dead, orders lost when a target dies | test_r58_selection_orders.gd |
| [59-rts-economy](59-rts-economy/README.md) | RTS economy (stockpile, supply, resource nodes with saturation, the gathering loop) | purchases half-paid, supply overfilled by two queues, ten workers on one mine earning ten times, workers walking past a new town hall | test_r59_economy.gd |
| [60-rts-build-produce](60-rts-build-produce/README.md) | RTS building and production (placement grid, production queue, tech tree) | overlapping or fogged buildings, a red ghost with no reason, pay-at-the-end queues, supply-blocked spam, tech that never locks again | test_r60_build_produce.gd |
| [61-rts-group-move](61-rts-group-move/README.md) | RTS group movement (the magic box, formation slots, crossing-free assignment, arrival) | twenty units fighting over one point, formations collapsing into a ball, crossing paths, crowds that never settle | test_r61_group_move.gd |
| [62-rts-fog-of-war](62-rts-fog-of-war/README.md) | RTS fog of war (unexplored / explored / visible on a grid, an overlay texture) | per-unit raycasts every frame, enemies drawn after they leave sight, buildings in the black, hard-edged overlays | test_r62_fog.gd |
| [63-rts-combat](63-rts-combat/README.md) | RTS combat (damage with bonuses, type table and armour; target priority; leash) | no counters, immune armour, units shooting walls while archers kill them, twitching between targets, endless chases | test_r63_combat.gd |
| [64-rts-ai](64-rts-ai/README.md) | RTS skirmish AI (a priority list, attack waves, retreat, honest difficulty) | an AI that supply-blocks, never techs, trickles units, fights to the last man, or secretly sees the map | test_r64_ai.gd |
| [65-rts-camera](65-rts-camera/README.md) | RTS camera (edge / key / drag pan, zoom limits, bounds, jump-to, the ground point under the cursor) | a pan that ignores the zoom, fast corners, a view off the map, clicks landing away from where the player looks | test_r65_camera.gd, r65_rts_camera.gd |

Tests: `tests/unit/test_rNN_*.gd` (GUT, logic and time via `advance(delta)`), `tests/scenarios/rNN_*.gd`
(bot player through the harness: real physics, real input actions). Tier A (player progress): recipe 13 —
its migration test was proven to fail when the migration is broken.

## Not yet covered
Save-to-cloud, mod loading, client-side prediction/interpolation for multiplayer — planned in `ROADMAP.md`.
