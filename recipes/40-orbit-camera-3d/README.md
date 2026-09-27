# 40 — 3D orbit camera (mouse or stick) with camera-relative movement

**Problem:** a third-person game needs a camera the player can turn with the mouse or the right stick, that never
flips over the top, never looks from inside a wall — and movement that stays "up = away from the camera" whichever
way the camera faces.

**Solution:** `OrbitCamera` (Node3D): follows `target` (position only), yaw on itself, pitch on its `Pitch` child,
a `SpringArm3D` + `Camera3D` under Pitch (the arm's collision mask = the world only, not the player's layer).
Mouse motion (while captured) and the optional actions `camera_left/right/up/down` both call `orbit(d_yaw, d_pitch)`;
pitch is clamped, yaw wraps. The player moves with `OrbitCamera.camera_relative(input, camera.yaw)`.
Capture the mouse when play starts (`Input.mouse_mode = Input.MOUSE_MODE_CAPTURED`) and release it in menus.

**Tuning:** `mouse_sensitivity` (rad/px), `stick_speed` (rad/s), `min_pitch_deg`/`max_pitch_deg`, `invert_y`,
`height`, the arm's `spring_length`. Offer sensitivity and invert Y in the settings menu (recipe 17).

**Pitfalls:** mouse look from `relative` — it is scaled by the viewport stretch, so sensitivity changes with the
window size (this recipe measured ×10 headless); use `screen_relative` (Godot 4.3+). Rotating the player instead of a separate rig (the camera spins with every turn); pitch without a
clamp (the view flips); the spring arm colliding with the player's own capsule (mask it out); stick actions that
don't exist (`Input.get_vector` errors — the recipe checks `InputMap.has_action`); mouse deltas read in
`_process` with a frame-rate factor (mouse motion is already per event — no `delta`). Next to a wall the arm gets
very short — fade the player mesh under ~1.5 m (see the platformer-3d template notes).

**Test:** `tests/unit/test_r40_orbit_camera.gd`, `tests/scenarios/r40_orbit_camera.gd`. Scene: `orbit_demo.tscn`.
