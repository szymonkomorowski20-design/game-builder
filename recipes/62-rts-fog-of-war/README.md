# 62 — RTS fog of war (unexplored / explored / visible on a grid, an overlay texture)

**Problem:** without fog there is no scouting, no surprise and no reason to hold ground.
- Fog done per node (a raycast or an Area per unit, every frame) costs too much with a hundred units.
- Fog done wrong breaks the rules:
  - enemies that stay drawn after they leave your sight;
  - buildings placed in the black;
  - terrain you have seen going black again;
  - a hard-edged square overlay.

**Solution:** `RtsFog`, one per team, a byte per cell.
- Each cell is UNEXPLORED (black), EXPLORED or VISIBLE.
  - EXPLORED is seen once: the terrain and buildings as they were last seen, no units.
  - VISIBLE is seen now by a unit or building of the team.
- `update(viewers)` (each viewer is `{at, sight}`) clears the visible layer and stamps each viewer's circle from
  precomputed offsets. What is stamped is also explored. Call it 5–10 times a second, not every frame: 200 viewers on
  128×128 take a few milliseconds (the test measures it).
- Queries:
  - `is_visible(world)`: draw and allow targeting an enemy only here;
  - `is_explored(world)`: allow a building only here (recipe 60's `explored`); a building seen once stays drawn here;
  - `state_at`, `cell_state`, `explored_fraction`.
- `to_image()` returns the overlay (FORMAT_L8: 0 / 128 / 255). Feed it to an `ImageTexture` sampled with linear
  filtering by a shader that darkens the world: soft edges for free.
- `reveal_all()` (a revealed map, the end screen).

**Tuning:**
- the cell size (1–2 m; the overlay is one pixel per cell). Measured in the rts-3d template's 40-against-40 battle:
  1 m cells cost 3.2 ms per update for both teams, 2 m cells 1.1 ms. Updating one team per tick halves the worst frame
  again. Convert between the fog's cells and the build grid's through world points, never by a fixed factor;
- each unit's `sight` (scouts see far: 10–14 m; workers 6–8 m; buildings 8–10 m);
- the update rate (5–10 Hz).

**Host (the game):**
- a timer calls `update()` with the team's living units and buildings;
- every enemy's `visible = fog.is_visible(its position)` (and its selection and targeting follow);
- a full-map `MeshInstance3D` (or a `ColorRect` in 2D) with the overlay shader, and the texture re-uploaded after each
  update (`ImageTexture.update(fog.to_image())`);
- the minimap (recipe 45) samples the same image;
- the AI (recipe 64) should use its own team's fog, or say plainly that it cheats.

**Extensions (not here):**
- sight blocked by high ground or forests: for each viewer, skip the cells whose height is above the viewer's (a height
  grid), or cast a few rays per circle;
- vision that lingers a moment after a unit dies (some games keep it for about a second).

**Pitfalls:**
- a physics query per unit per frame;
- enemy units hidden by the overlay but still clickable, or still shown on the minimap;
- a team's buildings not counted as viewers;
- an AI that sees through the fog unannounced (players notice and call it unfair).

**Test:** `tests/unit/test_r62_fog.gd`:
- a circle, inside and outside;
- explored after the viewer leaves;
- overlapping viewers and the map's edge;
- the overlay's three values; reveal_all;
- the cost with 200 viewers.
