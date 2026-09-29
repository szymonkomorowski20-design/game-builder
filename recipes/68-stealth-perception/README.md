# 68 — Stealth perception (vision zones, an awareness meter, hearing along paths)

**Problem:** detection that feels random, the stealth genre's first complaint (genre doc §3, §12):
- a plain cone sees too much far away and nothing right beside the guard;
- instant detection leaves no window to react;
- rays to many bones give results nobody can predict;
- light, sneaking and crowds that don't matter;
- guards hearing through walls because hearing is a circle.

**Solution:** four small parts.
- **`VisionCone`:** three zones.
  - `near`: within 2.5 m, almost all around;
  - `main`: out to 20 m, its half-angle shrinking from 60° to 25° with distance (the angle inversely related to
    distance, as in The Last of Us);
  - `peripheral`: wide, short and slow, to the sides.

  `time_to_notice(zone, distance)` is 0.4 s near, 1–4 s in the main zone (linear with distance, as in Blacklist) and
  4 s peripheral. `rate(zone, distance, cues, guard_state)` turns that into meter per second and applies the
  multipliers:
  - shadow ×0.35, sneaking ×0.6, high profile ×1.6, standing still ×0.7;
  - blended into a crowd: unseen except in the near zone (×0.5 there);
  - a hunting guard ×2.5, a cautious one ×1.4.
- **`AwarenessMeter`:**
  - it rises by `rate × delta` while the player is seen, and falls slowly (`fall_per_s`) while not;
  - `suspicious_at` (0.4) is the "I'll go and check" step, and full means detected;
  - detection latches until the brain (recipe 69) calls `reset()`;
  - `last_seen` and `last_seen_at` change only while the player is seen, so the guards' knowledge stays honest.
- **`Hearing`:**
  - `distance(map, from, to)` is the walkable length from a noise to the listener on the navigation map. It is INF
    when no path reaches the listener, and the straight distance when the noise is off the mesh (a roof the guards
    don't walk);
  - `hears(radius, length)`.
- **`GuardSenses`** (`Node3D` at the guard's eye height, looking along its −Z):
  - every `think_every` (0.1 s) it tests the target's chest and head for a zone and a clear line of sight, and feeds
    the best rate to the meter; `noticed(level)` fires when the level rises;
  - the target's `stealth_cues()` (recipe 66's `StealthMover`) gives the cues;
  - `hear(at, radius)` emits `heard(at, radius)`. Connect the player's `noise_made` to it.

**Hooking up:**
- Give `sight_mask` the world and the player's layer, so a ray that reaches the player counts as clear, and leave the
  guards off it.
- Set `guard_state` from the brain.
- Draw the meter over the guard's head, and the reason next to it (genre doc §12).
- Set the player's `in_shadow` from lights or zones, and `blended` from recipe 70.

**Tuning:**
- the zones' ranges and angles, and the times;
- the multipliers;
- `suspicious_at` 0.4 and `fall_per_s` 0.2.

Keep them the same for every guard (Shadow Tactics does, genre doc §3), and change difficulty with the times or with
more blind spots. No shipped game publishes its own numbers; only The Last of Us gives 1–2 s for a typical guard.

**Pitfalls:**
- The guard's own capsule in the way of its sight ray: exclude its RID.
- A sight mask without the player's layer: the ray then reaches the test point and passes through the player, which
  still works. But a mask that stops at the player's hitbox Area3D and not at its body reads as blocked. Test both
  ends.
- Hearing by straight distance: guards hear through a 20 m wall. By path only: a noise on a roof, off the mesh,
  snaps to the street below and is heard around corners. Use straight distance off the mesh.
- A meter that resets when the player hides: the hunt ends the moment the player breaks line of sight. Latch
  detection and let the brain end it.
- Checking every guard against the player every frame: stagger them with `think_every`.

**Test:** `tests/unit/test_r68_perception.gd`:
- the zones and the narrowing main angle;
- the times and every multiplier;
- the meter: rise, the suspicious step, the slow fall, latched detection, reset, and an honest last-seen place;
- `hears`.

`tests/scenarios/r68_perception.gd` (scene `perception_demo.tscn`, navigation baked on load):
- noticed after 1 / rate seconds in the main zone;
- shadow at its multiplier; blended, unseen;
- a wall blocks sight; nothing behind the guard, near beside it, slow to the side;
- a sprint behind the guard is heard and sneaking isn't;
- a noise behind a 20 m wall isn't heard, in front it is, a loud one goes round, and on a roof it travels straight.
