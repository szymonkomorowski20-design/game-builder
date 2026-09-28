# 65 — RTS camera (edge / key / drag pan, zoom limits, bounds, jump-to, the ground point under the cursor)

**Problem:** the RTS camera is the player's eyes. The usual failures:
- a pan that crawls when zoomed out and races when zoomed in;
- corners that pan faster than edges;
- a view that leaves the map;
- a minimap click that doesn't centre the spot;
- clicks and drag boxes that land somewhere other than where the player looks.

**Solution:** `RtsCamera`, a pivot node on the ground with a `Camera3D` child looking down at `pitch` from `distance`.
- Pans with the pan actions (`pan_actions`), the screen edges (`edge_margin` px; `edge_pan` off in tests and unfocused
  windows) and a middle-mouse drag.
- `pan_step` scales the speed with the zoom and never pans faster diagonally; `edge_direction` gives the edges and
  corners.
- The wheel zooms between `min_distance` and `max_distance`.
- `clamp_to(bounds)` keeps the pivot on the map.
- `jump_to(point)` centres a spot: a minimap click, a control group's double tap, an "under attack" alert.
- `ground_point(screen)` returns the ground under a screen position (the camera ray meeting the ground plane). Use it for
  right-click targets and the drag box's world corners; the screen centre looks exactly at the pivot.

**Tuning:**
- `pitch` (45–60°);
- `distance` and its limits (they decide how much of the battle fits);
- `pan_speed` (15–25 m/s at the default zoom);
- `edge_margin` (8–16 px);
- `bounds` (the map minus half a screen, so the edge of the map is the edge of the view).

**Host (the game):** put the rig in the level and set `bounds`. Route minimap clicks to `jump_to`. Take right-click
targets from `ground_point(mouse)` (or a physics ray for units and buildings).

**Pitfalls:**
- a pan speed that ignores the zoom;
- normalising the edge direction without clamping (corners 1.41× faster);
- edge panning while the window is unfocused, or during a drag box;
- `project_position` math done by hand instead of the camera's rays;
- bounds on the camera instead of the pivot (a tilted view shows past the edge).

**Test:**
- `tests/unit/test_r65_camera.gd`: edges and corners, the speed against the zoom, bounds;
- `tests/scenarios/r65_rts_camera.gd` (in the engine): a pan of the tuned distance, stopping at the bounds, the zoom
  limits, `jump_to`, and the screen centre's ground point.
