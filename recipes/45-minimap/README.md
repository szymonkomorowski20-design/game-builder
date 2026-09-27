# 45 — Minimap (drawn, aspect kept, off-map pinned to the edge)

**Problem:** a minimap that stretches the level (distances lie), loses things that are off the map instead of hinting
where they are, or renders the whole level a second time in a SubViewport just to show a few dots.

**Solution:** `Minimap` (Control): the level's `world_rect` scaled **uniformly** into the control (aspect kept,
centred, letterboxed), a dot per node in the tracked groups (`minimap_player`, `minimap_enemy`, `minimap_pickup` —
colours in `groups`). Things outside the world are clamped to the map's edge (inset by the dot radius so the dot stays
inside). `Minimap.map_point(world, rect, size)` is pure and unit-tested. Put the control on a CanvasLayer (HUD).

**Tuning:** the map's size and corner (layout), `dot_radius`, colours per group, `world_rect` = the level's bounds.

**When a SubViewport instead:** the map must show terrain/art (render a top-down camera into a SubViewport texture,
still use `map_point` for the icons on top).

**Pitfalls:** scaling x and y separately (a square room shows as a rectangle); forgetting that `global_position` of
nodes under a moving camera is still world space (correct) but a Control's position is screen space; redrawing only
on change (moving things need `queue_redraw()` every frame — cheap for dozens of dots); icons of freed nodes (the
group query each frame avoids stale references).

**Test:** `tests/unit/test_r45_minimap.gd`, `tests/scenarios/r45_minimap.gd` (+ screenshot). Scene: `minimap_demo.tscn`.
