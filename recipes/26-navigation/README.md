# 26 — Navigation (pathfinding around obstacles)

**Problem:** enemies walking straight at the player get stuck on walls.

**Solution:** a `NavigationRegion2D` with a navigation polygon (bake it in the editor from the TileMap/obstacles, with
`agent_radius` so paths keep distance from walls) + a `NavigationAgent2D` on each mover: set `target_position`, each
physics frame move toward `get_next_path_position()` until `is_navigation_finished()`. The demo uses a hand-written
polygon (a wall with a gap below it) so it needs no baking step.

**Grid games:** `AStarGrid2D` is simpler and deterministic for tile-based movement (roguelikes, tactics).

**Pitfalls:** querying on the first frame (the map syncs on physics frames — wait one); polygons that don't share exact
edges are not connected; forgetting `agent_radius` → bodies scrape corners; hundreds of agents re-pathing every frame
(set the target only when it moved noticeably); avoidance (`avoidance_enabled`) needs `velocity_computed` handling.

**Test:** `tests/scenarios/r26_navigation.gd`.
