# Template — first-person shooter starter
Status: implemented — evidence: game-builder template tests green under `gb verify` at scaffold time. That is 6 unit
tests (jump math, target health) and scenarios F1–F6 plus smoke, stable over `--repeat 10`. Detection proven: no
fire interval turns F4 red (60 shots/s), a ray that ignores walls turns F5 red, and mouse look from `relative`
turns F1 red. Screenshots looked at.
Ladder rung: toy (look + move + shoot) with a tiny first-playable loop (clear the arena)

## Goal
A tested starting point for a first-person shooter. You look with the mouse (captured) or the right stick, move
relative to where you look, jump, and shoot a hitscan weapon at targets with health. One target moves and one hides
behind cover. Clear them all to win. The art is placeholder (boxes, a box gun).

## Design
- **Player** (`scenes/player/player.tscn`, `scripts/player/fps_player.gd`): `CharacterBody3D` on layer 2.
  - Yaw on the body, pitch on `Head` (clamped).
  - Mouse look reads `InputEventMouseMotion.screen_relative`. `relative` is scaled by the viewport stretch — see
    godot-pitfalls and recipe 40.
  - Right-stick look through `look_*`; movement relative to the yaw; jump from height + time to apex.
  - `aim_at(point)` for tests, aim assist and cut-scenes. Observable: `yaw`, `pitch`, `jumps`.
- **Weapon** (`scripts/weapon/weapon.gd`, under the camera): a `RayCast3D` of `weapon_range` along the camera's
  −Z, mask 5 (world + targets), so walls stop shots. One shot per `fire_interval` while `shoot` is held; hits call
  `take_damage(damage)`. A muzzle-flash light. Observable: `shots_fired`, `last_hit`.
- **Targets** (`scenes/targets/target.tscn`): `StaticBody3D` on layer 3 with `health`. A hit flashes the target,
  and it is destroyed once at 0. `sway` makes one move back and forth.
- **Arena** (`scenes/arena/arena.tscn`, `scripts/arena/arena.gd`): 30×30 m floor with walls and one cover wall, and
  5 targets (left, right, behind the cover, moving, far).
  - HUD: a crosshair, "Cele: n/5" and the win message; `action` restarts after the win.
  - The mouse is captured on start; `pause` (Esc) frees and re-captures it.
  - Observable: `targets_total`, `targets_left`, `completed`, `score`.
- **Input** (template actions, written by Godot at scaffold time): `shoot` on the left mouse button, F and the right
  trigger; `look_left/right/up/down` on the right stick; plus the defaults.
- Forward+, Jolt, 1280×720.

## Tuning table (data/fps_tuning.tres → FpsTuning; target.gd)
| Parameter | Value | Unit | Where | Range to try |
|---|---|---|---|---|
| walk_speed | 6 | m/s | FpsTuning | 4–9 |
| acceleration | 50 | m/s² | FpsTuning | 20–100 |
| friction | 60 | m/s² | FpsTuning | 20–100 |
| air_control | 0.5 | × | FpsTuning | 0.2–1.0 |
| jump_height | 1.2 | m | FpsTuning | 0.8–2.0 |
| time_to_apex | 0.35 | s | FpsTuning | 0.25–0.5 |
| mouse_sensitivity | 0.0025 | rad/px | FpsTuning (settings menu later) | 0.001–0.006 |
| stick_look_speed | 3 | rad/s | FpsTuning | 1.5–5 |
| min/max_pitch_deg | −85 / 85 | ° | FpsTuning | — |
| fire_interval | 0.15 | s | FpsTuning | 0.05–0.6 |
| damage | 1 | hp | FpsTuning | 1–5 |
| weapon_range | 60 | m | FpsTuning | 20–200 |
| health (target) | 3 | hp | target.gd `@export` | 1–10 |
| sway / sway_period | 2 / 3 | m / s | target.gd `@export` (moving target) | — |

## Behaviours (test IDs)
| ID | Behaviour | Test |
|---|---|---|
| F1 | Mouse right turns right by screen_relative × sensitivity (not by `relative`); looking up stops at max_pitch | `f1_mouse_look.gd` |
| F2 | After turning 90° left, "up" walks toward −X at walk_speed (kinematics ± 15 cm), no drift | `f2_move_relative.gd` |
| F3 | Aiming at a target and shooting hits it; each hit removes `damage`; at 0 it is gone and the HUD counts it | `f3_shoot_target.gd` |
| F4 | Holding shoot fires once per fire_interval (≈ 7 shots in 1 s), not every frame | `f4_fire_interval.gd` |
| F5 | The cover stops shots: aiming at the hidden target from the spawn hits the cover | `f5_cover_blocks.gd` |
| F6 | Shooting every target (around the cover, leading the moving one) completes the arena and shows the message | `f6_clear_arena.gd` |
| — | Jump math; a target is destroyed exactly once | `tests/unit/test_jump_math.gd`, `test_target.gd` |

## Next steps for your game
Discovery decides what the game is. Typical next specs:
- enemies that shoot back (recipes 24/25 AI, 05 health, 06 hitboxes);
- ammo and reload;
- hit feedback (recipes 32/33);
- a pause/settings menu with sensitivity and invert Y (recipes 15/17).
Tune feel by editing `data/fps_tuning.tres` and playing.
