# 27 — TileMapLayer: levels, collision, per-tile data

**Problem:** hazards and special tiles detected by comparing tile coordinates in code; world/cell conversions off by
one when the map is moved.

**Solution:** Godot 4.3+ uses one `TileMapLayer` node per layer (the old `TileMap` is deprecated). Put gameplay data
on the **TileSet**: a physics layer (collision polygons per tile) and custom data layers (`hazard: bool`, `cost: int`,
`footstep: String`). Query with `get_cell_tile_data(cell).get_custom_data("hazard")`. Convert world → cell with
`local_to_map(to_local(world_pos))` — always through `to_local`. `AsciiLevel` builds a layer from text rows and creates
the TileSet in code, so tests and procedural generators (28) need no editor assets.

**Editor workflow:** TileSet from your atlas image → paint collision in the TileSet editor → terrains for autotiling →
scene collections for interactive tiles (doors, chests) that need scripts.

**Pitfalls:** using `TileMap` (deprecated) tutorials; forgetting `to_local` when the layer is offset; texture filter
blurring pixel art (Project Settings → Rendering → Textures → Default Texture Filter = Nearest); seams between tiles
(enable texture padding in the atlas); physics "ghost collisions" at tile seams for fast bodies.

**Test:** `tests/unit/test_r27_tilemap.gd`.
