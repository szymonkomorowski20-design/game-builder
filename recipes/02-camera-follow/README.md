# 02 — 2D camera follow with drag margins and limits

**Problem:** the camera should follow the player without jittering on every small step and never show outside the level.

**Solution:** `Camera2D` as a child of the player; `drag_*_enabled` + margins (fraction of half the screen) create a
dead zone; `limit_*` clamp the view to the level's pixel bounds. Add `position_smoothing_enabled` for easing
(keep it off in tests that assert exact positions, or wait for it to settle).

**Tuning:** drag margins (0–1), smoothing speed, limits = level bounds.

**Pitfalls:** limits smaller than the viewport; several cameras without choosing the current one; reading
`position` instead of `get_screen_center_position()` (drag and limits act on the screen centre).

**Test:** `tests/scenarios/r02_camera_limits.gd`. Scene: `camera_follow.tscn` (reuses the recipe 01 mover).
