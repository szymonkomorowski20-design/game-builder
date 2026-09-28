# 56 — Aim assist for gamepads

**Problem:** aiming with a stick is far coarser than with a mouse. Without help, gamepad players can't make the small
corrections a shooter asks for. Too much help (snapping, a gun that aims by itself) takes the skill away.

**Solution:** **`AimAssist`**, plain math the camera code applies, **for gamepad input only**:
- **slowdown** (friction): `slowdown(eye, aim_dir, targets)` returns a sensitivity multiplier. It is `min_scale` on
  a target and rises linearly to 1 at the edge of `cone`.
- **pull** (rotational assist): `pull(eye, aim_dir, camera_basis, targets, stick, delta)` returns degrees
  (yaw, pitch) to turn toward the target nearest the crosshair:
  - **only while the stick is moving** (|stick| ≥ 0.2), scaled by the stick;
  - capped by `pull_speed` per second;
  - never past the target.
- `best_target` is the target closest to the crosshair inside `cone` and `max_range`.

`targets` are aim points (chest height) the host has already checked are visible. Line of sight is its job: one ray
per candidate per frame, or every few frames.

**Tuning:**
- `cone` 4–8°;
- `min_scale` 0.4–0.6;
- `pull_speed` 5–15 °/s;
- `max_range`.

Offer an on/off setting and a strength setting. Keep ADS-snapping (turning to a target when aiming down sights) out of
a first version: it is the most criticised form.

**Host:**
- Only when the last input came from a joypad.
- `look_speed *= assist.slowdown(...)`.
- Each frame `var d := assist.pull(...)`, then add `d.x` to the yaw and `d.y` to the pitch before applying the player's
  own stick input.

**Pitfalls:**
- assist through walls (check visibility);
- applying it to mouse input;
- pulling while the stick is idle (the gun tracks targets by itself);
- one fixed aim point that drags the crosshair to the feet or the head (use the chest).

**Test:** `tests/unit/test_r56_aim_assist.gd`: slowdown by angle, cone and range; the pull only with a moving stick,
capped and never past the target; the choice of the closest target.
