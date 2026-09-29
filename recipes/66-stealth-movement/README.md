# 66 — Stealth movement (profiles with noise, edges that hold, falls with soft landings)

**Problem:** third-person movement that works for a platformer fails in a stealth game:
- one speed for everything, so sneaking is only slow running, and nothing tells the guards how loud the player is;
- walking off a roof by accident, the genre's classic complaint (genre doc §1);
- falls with no consequence (roofs mean nothing) or damage that works as an invisible wall, and hay that does nothing;
- jumps eaten a frame early or late.

**Solution:** three small rules and one body.
- **`MoveProfiles`:** SNEAK / WALK / RUN / SPRINT, each with a speed (m/s), a noise radius (m) and a high-profile flag.
  - `pick(stick, sprint_held, sneak_held)`: sprint (only while moving) wins over sneak; a half-pushed stick walks.
  - `landing_noise(height)`: silent below 0.6 m, then 2 m of radius per metre fallen, capped.
- **`EdgeGuard`:**
  - `probe_drop(space, feet, dir, ahead, max_probe, mask)` looks down `ahead` m in front of the feet. It returns the
    drop, or INF when there is no floor within `max_probe`.
  - `decide(...)`: a step down is fine. A real drop needs an intent: jump, drop, or sprinting, which leaps (the
    high-profile run of the genre). Otherwise the body stops.
- **`FallRule`:** named heights. Nothing up to `safe_height`, damage rising linearly to `deadly_height`, death from
  there on. A floor in the group `soft_landing` (hay, water) takes falls up to `soft_max_height`. For "no death from
  falling", set `deadly_height = INF`.
- **`StealthMover`** (`CharacterBody3D`):
  - camera-relative input (`camera_path`: the orbit camera of recipe 40);
  - acceleration, friction and air control; the `Body` child turns toward the movement;
  - a jump set by height and time to apex, with a buffer and coyote time;
  - the edge guard on the floor and the fall rule on landing.

  Signals:
  - `noise_made(at, radius)`: one per `step_length` of travel at the profile's radius, and on landing;
  - `landed(height, outcome)`;
  - `stopped_at_edge`.

  `climbing = true` hands the body to another system (the climber of recipe 67).
- **`GreyboxBlock.make(centre, size, colour, layers, groups)`:** a coloured, collidable box for demos and blockouts.

**Input actions:** `move_left/right/up/down` and `jump`. `sprint`, `sneak` and `drop` are optional and used only if
they exist.

**Hooking up:**
- Route `landed` into Health (recipe 05).
- Route `noise_made` into the guards' hearing (recipe 68).
- Put the player on its own physics layer, and keep `world_mask` to the world, so the edge probe never sees the
  player's own capsule.

**Tuning:**
- speeds 1.6 / 2.2 / 4.2 / 6.5 m/s, and noise radii 0 / 2 / 5 / 9 m. These are starting values: no game in the genre
  doc publishes its own;
- `walk_below` 0.55;
- `jump_height` 1.2 m, `jump_time_to_apex` 0.38 s, `fall_gravity_scale` 1.6: a sprint clears about 4 m;
- `coyote_time` 0.1 s, `jump_buffer` 0.12 s;
- `step_down_max` 0.6 m, `edge_probe_ahead` 0.45 m (a little more than the capsule's radius), `drop_window` 0.35 s;
- `safe_height` 4.5 m, `deadly_height` 14 m, `soft_max_height` 40 m.

**Pitfalls:**
- An edge probe that includes the player's own body reads the capsule as floor; exclude its RID.
- Stopping at an edge by lowering the speed instead of zeroing it: momentum carries the body over.
- A leap on sprint with no way to turn it off: some games want the player to stop at every edge. Set
  `auto_jump_when_sprinting` to false.
- Fall height measured from the take-off instead of the highest point: a jump from a roof then hurts less than a
  step off it. The mover tracks the peak.
- `CharacterBody3D` doesn't climb steps: use ramps, keep steps under the floor snap, or let the climber's vault
  (recipe 67) take them.
- Footstep noise every frame instead of per distance: the radius is right but guards hear sixty "steps" a second.

**Test:** `tests/unit/test_r66_movement.gd`:
- the profile table, speeds, noise and landing noise;
- the fall rule's heights and soft landings;
- the edge guard's decisions;
- the drop probe on real boxes.

`tests/scenarios/r66_stealth_movement.gd` (scene `stealth_move_demo.tscn`):
- sprint and sneak speeds; sneaking is silent and running is heard;
- the roof's edge holds, and a drop from 5 m hurts;
- 9 m into hay doesn't hurt;
- a sprint leaps a 2.5 m gap, and a run stops at it.
