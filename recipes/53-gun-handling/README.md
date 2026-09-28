# 53 — Gun handling: rate, magazine, reloads, spread, recoil, falloff

**Problem:** the gun is most of a shooter's feel, and it is easy to get subtly wrong:
- a fire rate that drifts with the frame rate;
- a burst after a pause (idle time counted as credit);
- random recoil the player can't learn;
- bloom that never recovers;
- aiming that doesn't matter;
- a reload that can be spammed, or one that loads rounds even though it was cancelled;
- damage that is the same at 5 m and 80 m.

**Solution:** **`GunModel`** (plain logic, no 3D) with its numbers in a **`GunStats`** resource. The host calls
`tick(delta, trigger_down)` every physics frame and gets back the shots fired that frame.
- **Rate:** `rpm`. Inside a burst the sub-frame overshoot carries over, so 700 rpm stays 700 rpm at 60 Hz. A shot after
  a pause starts the clock fresh. `automatic = false` fires once per press.
- **Magazine and reserve:**
  - `reload()` picks the **tactical** time with rounds left, the **empty** time otherwise;
  - it refuses a full magazine and an empty reserve;
  - `cancel_reload()` (sprint, swap, stagger) loads **nothing**;
  - a press on an empty magazine emits `dry_fired` (the click).
- **Accuracy:**
  - the cone half-angle is `lerp(hip_spread, ads_spread, ads)` + bloom;
  - bloom grows `bloom_per_shot` per shot up to `bloom_max` and recovers at `bloom_recovery` °/s;
  - after `first_shot_rest` without firing, the next shot has **no bloom**, so tapping is accurate and spraying is not;
  - `set_ads(true)` eases in over `ads_time`;
  - every shot's offset is drawn uniformly over the cone's disc from a seeded RNG.
- **Recoil:**
  - a learnable **pattern** (`recoil_pattern`, degrees per shot; the last entries repeat), scaled down while aiming;
  - it restarts after a rest;
  - `Shot.kick` is what to add to the camera now;
  - `kick_accumulated` recovers when firing stops.
- **Damage:**
  - full up to `falloff_start`, linear down to `falloff_min` at `falloff_end`;
  - × `headshot_mult` or `limb_mult` by hit zone (recipe 54 says which zone was hit).

**Tuning:**
- `rpm`, `magazine`, the two reload times;
- `damage`, the zone multipliers, the falloff distances;
- the spread and bloom numbers, `ads_time`;
- the recoil pattern.

Time-to-kill is the number to design around. For damage d, enemy health h and rate r, TTK ≈ (⌈h/d⌉ − 1) × 60/r
seconds; keep it in the Tuning table. The defaults are a CoD4-era assault rifle [wiki, `gb doc genre-military-fps`]:
- 700 rpm, 40 → 30 damage with distance, headshot × 1.4;
- on 100 health: 3 body hits up close (TTK ≈ 0.17 s), 2 to the head.

Other archetypes: snipers × 1.5 to the head with high damage and a slow bolt; shotguns × 1.0 to the head, with a
wide cone and a steep falloff; a pistol semi-auto.

**Host:**
- Every physics frame, `tick(delta, Input.is_action_pressed(&"shoot"))`.
- For each Shot:
  - rotate the camera's forward by `offset`;
  - cast the ray (recipe 54);
  - apply `kick` to the camera pitch and yaw;
  - play the sound, muzzle flash and hit marker on `fired`.
- `set_ads` from the aim action; the speed is × `ads_move_scale` while aiming.
- On sprint call `cancel_reload()`.

**Pitfalls:**
- timing shots with `create_timer` (drifts and breaks under hit-stop);
- recoil applied as a random walk (unlearnable);
- spreading in angle space without converting to a direction around the camera's own basis;
- showing the crosshair bloom from a different value than the one that draws the shot.

**Test:** `tests/unit/test_r53_gun.gd`: the exact rates (600 and 700 rpm), semi-auto, the dry click, the two reload
kinds, a cancelled reload, spread from hip to ADS with bloom and recovery, shots inside the cone, the recoil pattern
and its restart, falloff and zones, and determinism.
