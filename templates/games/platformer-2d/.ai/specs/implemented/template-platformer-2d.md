# Template — 2D platformer starter
Status: implemented — evidence: game-builder template tests (tests/unit/test_jump_math.gd, tests/scenarios/p*.gd) green under `gb verify` at scaffold time
Ladder rung: toy (movement + one core interaction) with a tiny first-playable loop (coins → goal)

## Goal
A tested starting point for a side-view platformer: responsive movement you tune by numbers, a short
level with a gap, platforms, coins and a goal. Placeholder art (rectangles) — replace it through the
asset register when the game's look is decided.

## Design
- Player (`scenes/player/player.tscn`, `scripts/player/player.gd`): acceleration/friction run, jump
  defined by height + time to apex (`JumpMath`), faster fall, variable jump height (release to cut),
  coyote time, jump buffering. Observable: `state` (idle/run/jump/fall), `jumps_started`.
- Level (`scenes/level/level_1.tscn`, `scripts/level/level.gd`): ground 0–400 px and 496–1440 px
  (top y = 312, gap 400–496), platforms A (150–246, top 240) and B (560–680, top 250), 5 coins
  (group `coins`), goal at x = 1400, respawn at `Spawn` when y > `kill_y`. Observable: `coins_collected`,
  `coins_total`, `deaths`, `completed`, `score`. HUD label + end message; `action` restarts after the goal.
- Viewport 640×360 (window 1280×720), camera follows the player with smoothing and level limits.

## Tuning table (data/player_tuning.tres → PlayerTuning; level.gd)
| Parameter | Value | Unit | Where | Range to try |
|---|---|---|---|---|
| run_speed | 180 | px/s | PlayerTuning | 120–260 |
| acceleration | 1400 | px/s² | PlayerTuning | 600–3000 |
| friction | 1600 | px/s² | PlayerTuning | 600–3000 |
| air_control | 0.8 | × | PlayerTuning | 0.3–1.0 |
| jump_height | 72 | px | PlayerTuning | 40–120 |
| time_to_apex | 0.38 | s | PlayerTuning | 0.25–0.5 |
| fall_gravity_multiplier | 1.6 | × | PlayerTuning | 1.0–2.5 |
| max_fall_speed | 600 | px/s | PlayerTuning | 400–900 |
| jump_cut_multiplier | 0.45 | × | PlayerTuning | 0.2–1.0 |
| coyote_time | 0.1 | s | PlayerTuning | 0.05–0.15 |
| jump_buffer | 0.12 | s | PlayerTuning | 0.05–0.2 |
| kill_y | 480 | px | level.gd `@export` | — |

## Behaviours (test IDs)
| ID | Behaviour | Test |
|---|---|---|
| P1 | Holding a direction reaches run_speed after acceleration; distance in 1 s matches the kinematics | `p1_run_speed.gd` |
| P2 | Holding jump reaches jump_height (± 3 px) | `p2_jump_height.gd`, unit `test_jump_math` |
| P3 | Jump still works within coyote_time after walking off a ledge, and not after it | `p3_coyote_time.gd` |
| P4 | A jump pressed shortly before landing triggers on landing (buffer) | `p4_jump_buffer.gd` |
| P5 | Releasing jump early gives a lower jump (variable height) | `p5_variable_jump.gd` |
| P6 | Touching a coin collects it once and updates the HUD | `p6_coin_collect.gd` |
| P7 | Falling below kill_y respawns at Spawn and counts a death | `p7_fall_respawn.gd` |
| P8 | Reaching the goal completes the level and shows the message | `p8_reach_goal.gd` |

## Next steps for your game
Discovery decides what the game is; the next spec changes this template (new mechanics, levels,
art). Tune feel by editing `data/player_tuning.tres` and playing, not by changing code.
