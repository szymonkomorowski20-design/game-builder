# Template — 3D platformer starter (chase camera)
Status: implemented — evidence: game-builder template tests green under `gb verify` at scaffold time: 5 unit tests
(tests/unit/test_jump_math.gd) and 7 scenarios D1–D7 plus the smoke scenario; `--repeat 10` stable (Jolt).
Detection proven: a spring arm without collision turns D4 red, and no coyote timer turns D3 red. Screenshots looked at.
Ladder rung: toy (movement + one core interaction) with a tiny first-playable loop (coins → goal)

## Goal
A tested starting point for a 3D platformer: responsive movement you tune by numbers, a chase camera that never looks
from inside a wall, and a short course with a gap, a raised platform, coins and a goal. The art is placeholder (capsule
and boxes). Replace it through the asset register once the game's look is decided.

## Design
- **Player** (`scenes/player/player.tscn`, `scripts/player/player.gd`): `CharacterBody3D` on collision layer 2.
  - Movement on the ground plane: `move_up` = away from the camera (-Z), `Input.get_vector` normalises diagonals.
    Acceleration and friction, air control.
  - Jump from height + time to apex (`JumpMath`), faster fall, variable jump height, coyote time, jump buffer.
  - The `Body` node turns toward the movement direction at `turn_speed`.
  - Observable: `state` (idle/run/jump/fall), `jumps_started`.
- **Camera**: `CameraRig/SpringArm` (`SpringArm3D`, 7 m, pitched 35° down, collision mask 1 = the world, sphere
  margin 0.3) with `Camera3D`.
  - Fixed yaw, which keeps controls and tests simple (no mouse needed). Mouse or stick orbit is a later recipe.
  - Against a wall between the player and the camera, the arm shortens and the camera stays in front of the wall.
- **Level** (`scenes/level/level_1.tscn`, `scripts/level/level.gd`) — CSG boxes with collision:
  - ground 1: x −6…6, z 2…−10; gap z −10…−12.5; ground 2: z −12.5…−32.5;
  - raised platform (top 1 m) at x 3, z −18; pillar x 3…5, z −2.5…−1.5, height 3 m;
  - 5 coins (`Area3D`, mask 2 = only the player; under Jolt an Area3D also reports static bodies, 4.5+);
  - goal at z −30; respawn at `Spawn` when y < `kill_y`.
  - Sky, sun with shadows, HUD label and an end message; `action` restarts after the goal.
  - Observable: `coins_collected`, `coins_total`, `deaths`, `completed`, `score`.
- Renderer Forward+ (desktop 3D), viewport 1280×720, physics: Jolt (the 4.6+ default).

## Tuning table (data/player_tuning.tres → PlayerTuning; level.gd)
| Parameter | Value | Unit | Where | Range to try |
|---|---|---|---|---|
| run_speed | 6 | m/s | PlayerTuning | 4–9 |
| acceleration | 40 | m/s² | PlayerTuning | 15–80 |
| friction | 50 | m/s² | PlayerTuning | 15–80 |
| air_control | 0.8 | × | PlayerTuning | 0.3–1.0 |
| turn_speed | 12 | rad/s | PlayerTuning | 6–20 |
| jump_height | 1.6 | m | PlayerTuning | 1.2–2.5 |
| time_to_apex | 0.38 | s | PlayerTuning | 0.25–0.5 |
| fall_gravity_multiplier | 1.6 | × | PlayerTuning | 1.0–2.5 |
| max_fall_speed | 20 | m/s | PlayerTuning | 12–40 |
| jump_cut_multiplier | 0.45 | × | PlayerTuning | 0.2–1.0 |
| coyote_time | 0.1 | s | PlayerTuning | 0.05–0.15 |
| jump_buffer | 0.12 | s | PlayerTuning | 0.05–0.2 |
| spring_length | 7 | m | player.tscn SpringArm | 4–10 |
| kill_y | −10 | m | level.gd `@export` | — |

## Behaviours (test IDs)
| ID | Behaviour | Test |
|---|---|---|
| D1 | Holding move_up runs toward −Z; the distance in 1 s matches the kinematics; no drift; friction stops | `d1_run_speed.gd` |
| D2 | A held jump reaches jump_height (± 5 cm); a tapped jump is clearly lower | `d2_jump_height.gd`, unit `test_jump_math` |
| D3 | Jump works within coyote_time after running off the ledge, not after it | `d3_coyote_time.gd` |
| D4 | Camera at the full arm length in the open; in front of the pillar when it is between camera and player | `d4_camera_wall.gd` |
| D5 | Running into the coin ahead collects it once and updates the HUD | `d5_coin_collect.gd` |
| D6 | Falling into the gap below kill_y respawns at Spawn and counts a death | `d6_fall_respawn.gd` |
| D7 | Reaching the goal completes the level, shows the message and keeps the player there | `d7_reach_goal.gd` |

## Found while building it
- In a `.tscn`, `Transform3D(…)` lists the basis **row by row**. A rotation hand-written column by column pointed
  the spring arm into the ground. D4 caught it (the arm was 1.5 m long in the open), and it is now in
  godot-pitfalls.md.
- With the player right in front of a wall (0.9 m), the camera ends up inside the player's head. The arm works as
  designed, but the view is useless. D4 now stands 2 m away. For your game: fade the player mesh when the arm is
  shorter than ~1.5 m, or raise the camera — a spec decision.

## Next steps for your game
Discovery decides what the game is; the next spec changes this template (camera orbit, new mechanics, levels, art).
Tune feel by editing `data/player_tuning.tres` and playing, not by changing code.
