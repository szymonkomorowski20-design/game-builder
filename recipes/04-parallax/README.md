# 04 — Parallax background

**Problem:** depth in a 2D side view — distant layers move slower than near ones and repeat endlessly.

**Solution:** one `Parallax2D` node per layer (Godot 4.3+, replaces ParallaxBackground/ParallaxLayer);
`scroll_scale` below 1 for far layers, `repeat_size` equal to the art width for endless tiling. Children are the layer art.

**Tuning:** `scroll_scale` per layer (0.1 sky … 0.8 near foliage), `repeat_size`, `autoscroll` for clouds.

**Pitfalls:** mixing the old ParallaxBackground nodes with Parallax2D; `repeat_size` not matching the texture width (seams);
pixel art at fractional scroll (enable pixel snap); moving a Parallax2D's `position` by code (it is overridden
while it follows the camera); measuring `screen_offset` in tests (shared by all layers — measure the on-screen
position via `get_global_transform_with_canvas()`, as the test does).

**Test:** `tests/scenarios/r04_parallax.gd` — the far layer moves less than the near one.
Source: Godot docs "2D Parallax" (`gb kb "Parallax2D scroll_scale repeat_size"`).
