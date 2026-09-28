# 55 — Regenerating health and damage direction indicators

**Problem:** a campaign shooter's health model decides its pacing:
- health packs make every fight a resource drain;
- full regeneration lets a player erase all damage behind cover;
- hits from off-screen feel unfair when nothing says where they came from.

**Solution:**
- **`RegenHealth`:**
  - `take_damage(amount)`;
  - after `regen_delay` s without a hit, health returns at `regen_rate` per second, and every hit restarts the wait;
  - `segment` > 0 caps regeneration at the top of the current segment (25 → at 60 it regenerates to 75), so damage
    has a lasting cost without health packs;
  - `danger()` is 0…1 below `danger_below` for the screen effect (red edges, desaturation, heartbeat, muffled sound).
- **`RegenHealth.direction_to(camera_basis, own_position, attacker_position)`:** the hit's angle relative to the view
  (0 = front, 90 = right, ±180 = behind), ignoring height.
- **`DamageIndicators`:**
  - `add(angle)` for each hit; indicators fade over `lifetime`;
  - hits within `merge_within` degrees refresh one arc instead of stacking;
  - the HUD draws each `{angle, left}` as an arc around the crosshair, with `alpha()`.

**Tuning:**
- `regen_delay` 3–5 s: shorter makes peeking safe, longer drags;
- `regen_rate` 20–40 %/s of max health;
- `segment`: 0 or a quarter to a third of max;
- `danger_below` about 0.3;
- the indicator's `lifetime` 1–2 s.

On a harder difficulty, lengthen the delay rather than raising enemy damage (`gb doc genre-military-fps`).

**Host:**
- Enemies hit the player through `take_damage`, and the HUD reads `current` and `danger()`.
- On each hit: `indicators.add(RegenHealth.direction_to(camera.global_basis, player.global_position,
  attacker.global_position))`.
- Tick both in `_physics_process`.

**Pitfalls:**
- regenerating while still under fire (the delay must restart on every hit, as here);
- an indicator per bullet (a spray of 10 arcs; merge them);
- using the attacker's position when the hit happened instead of later (fine for hitscan; for slow projectiles pass
  their launch point);
- a heartbeat that never stops because `danger()` uses current health while regeneration is still running.

**Test:** `tests/unit/test_r55_regen.gd`: the delay and rate, a hit restarting the delay, segments, danger and death,
the direction angles, indicators merging and fading.
